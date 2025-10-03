{ lib
, config
, namespace
, ...
}:
let
  inherit (lib.${namespace}) mkRGBA_valOnly;
  inherit (config.lib.stylix) colors;
in
{
  glitter_comet = ''
    /*─────────────────────────────────────────────────────────────────────────
     *  glitter_comet.glsl — sparkly cursor trail whose density follows motion
     *    • bursts of “glitter” appear only along the cursor travel segment
     *    • faster/longer jumps raise the sparkle density
     *    • Stylix colours drive tint and opacity without extra shader edits
     *────────────────────────────────────────────────────────────────────────*/

    // inputs - screen size helper
    vec2 ndc(vec2 value, float isPos) {
      // Map from pixels to NDC where Y dimension spans [-1, 1]
      return (value * 2.0 - iResolution.xy * isPos) / iResolution.y;
    }

    // Distance helper to a segment A->B
    float sdSegment(vec2 p, vec2 a, vec2 b, out float param) {
      vec2 pa = p - a;
      vec2 ba = b - a;
      float denom = max(dot(ba, ba), 1e-5);
      param = clamp(dot(pa, ba) / denom, 0.0, 1.0);
      return length(pa - ba * param);
    }

    // Randomizer
    float hash(vec3 p) {
      return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
    }

    //Tuneable Values in NDC units
    const vec4 GLITTER_COLOR = vec4(${mkRGBA_valOnly { hex = "#${colors.base06}"; alpha = 1.0; }}) / vec4(255.0, 255.0, 255.0, 1.0);
    const float GLITTER_WIDTH = 0.05;
    const float MIN_DENSITY = 0.9;
    const float MAX_DENSITY = 1.0;
    const float BRIGHTNESS = 0.75;
    const float GLITTER_PERIOD = 1.5;
    const float GLITTER_FALL_DISTANCE = 0.4;
    const float GLITTER_LIFETIME = 0.7;
    const float GLITTER_FRONT_THICKNESS = 0.1;

    //ShaderToy entry, pixel coords, output colors
    void mainImage(out vec4 fragColor, in vec2 fragCoord) {
      #if !defined(WEB)
        vec4 base = texture(iChannel0, fragCoord / iResolution.xy); //Sample existing framebuffer/background
      #else
        vec4 base = vec4(0.0); //Starting color
      #endif

      //Ghostty-provided uniforms for terminal cursor state
      //Cursor position before and after movement
      vec4 curRect = iCurrentCursor;
      vec4 prvRect = iPreviousCursor;

      //Compute cursor center in pixel space before and after movement
      vec2 curCentrePx = curRect.xy + vec2(curRect.z * 0.5, -curRect.w * 0.5);
      vec2 prvCentrePx = prvRect.xy + vec2(prvRect.z * 0.5, -prvRect.w * 0.5);

      //NDC positions for all relevant points
      vec2 cur = ndc(curCentrePx, 1.0);
      vec2 prv = ndc(prvCentrePx, 1.0);
      vec2 P = ndc(fragCoord, 1.0);

      // Cursor size in NDC
      vec2 cursorSizeNdc = (iCurrentCursor.zw * 2.0) / iResolution.y;
      float cursorMaxNdc = macx(cursorSizeNdc.x, cursorSizeNdc.y);

      // NDC centers already computer as `cur` and `prv`
      float travelNdc = length (cur - prv);

      //Optional same-line suppression
      bool sameLine = abs(ndc(curRect.xy, 1.0).y - ndc(prvRect.xy, 1.0).y) < 1e-6;
      bool suppressSameLine = HIDE_TRAILS_ON_THE_SAME_LINE && sameLine;

      //Gate tiny moves (suppress tiny moves)
      bool smallMove = (travelNdc <= DRAW_THRESHOLD * cursorMaxNdc);

      //Motion fade after the last cursor change
      float moveElapsed = max(iTime - iTimeCursorChange, 0.0);
      float motionPhase = clamp(moveElapsed / GLITTER_LIFETIME, 0.0, 1.0);
      float motionFade = 1.0 - smoothstep(0.0, 1.0, motionPhase);

      //Segment distance field in NDC units
      float segParam;
      float distToSeg = sdSegment(P, prv, cur, segParam);
      vec2 basePoint = mix(prv, cur, segParam);

      //Trail thickness mask around the segment (area around the line from A->B (before pos. to after pos.))
      // smoothstep expects ascending edges; use inner then outer radius so the trail mask stays confined to the cursor path while allowing vertical drift
      float trail = 1.0 - smoothstep(GLITTER_WIDTH * 0.2, GLITTER_WIDTH, distToSeg);

      //Falling glitter band below the path, expressed in normalized "fall space"
      float drop = P.y - basePoint.y; //NDC delta along Y-axis
      float dropNorm = clamp(drop / max(GLITTER_FALL_DISTANCE, 1e-4), 0.0, 1.0);
      float timeline = iTime / GLITTER_PERIOD;

      //Stable per-cell phasing: grid in pixel space with fixed cell size for sparkles?
      const float cellSizePx = 2.0; //~2px cells
      vec2 sparkleCell = floor(fragCoord.xy / cellSizePx);
      float cellSeed = hash(vec3(sparkleCell, 37.0));
      float t = timeline + cellSeed;
      float cycleProg = fract(t);
      float cycleIndex = floor(t);

      //Falling band front and tail in normalized [0,1] space
      float fallHead = cycleProg;
      float fallTail = max(fallHead - GLITTER_FRONT_THICKNESS, 0.0);
      float leadingEdge = 1.0 - smoothstep(fallHead, fallHead + GLITTER_FRONT_THICKNESS, dropNorm);
      float trailingEdge = 1.0 - (1.0 - smoothstep(fallTail, fallTail + GLITTER_FRONT_THICKNESS, dropNorm));
      float fallMask = leadingEdge * trailingEdge * smoothstep(0.0, GLITTER_FRONT_THICKNESS, dropNorm);

      //Denisty responds to travel distance in NDC, clamped to [0,1]
      float travelNorm = clamp(travelNdc, 0.0, 1.0);
      float densityFactor = clamp(travelNorm * 10.0, 0.0, 1.0);
      float density = mix(MIN_DENSITY, MAX_DENSITY, densityFactor) * motionFade;

      //Spawn decision per-cell per-cycle
      float sparkle = hash(vec3(sparkleCell, cycleIndex));
      float spawn = step(1.0 - density, sparkle);

      //Fade out within a cycle so specks twinkle
      float fade = 1.0 - smoothstep(0.33, 1.0, cycleProg);

      //Travel mask in consistent units; suppress tiny moves and optional same-line
      float travelMask = (smallMove || suppressSameLine) ? 0.0 : travelNorm;

      //Final glitter mask
      float glitter = trail * fallMask * spawn * fade * travelMask * motionFade;

      vec3 colour = mix(base.rgb, GLITTER_COLOR.rgb, glitter * BRIGHTNESS);
      fragColor = vec4(colour, base.a);
    }
  '';
  blaze = ''
    // Based on https://gist.github.com/chardskarth/95874c54e29da6b5a36ab7b50ae2d088
    float ease(float x) {
        return pow(1.0 - x, 10.0);
    }

    float sdBox(in vec2 p, in vec2 xy, in vec2 b)
    {
        vec2 d = abs(p - xy) - b;
        return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
    }

    float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
    {
        vec2 d = abs(p - xy) - b;
        return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
    }
    // Based on Inigo Quilez's 2D distance functions article: https://iquilezles.org/articles/distfunctions2d/
    // Potencially optimized by eliminating conditionals and loops to enhance performance and reduce branching
    float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
        vec2 e = b - a;
        vec2 w = p - a;
        vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
        float segd = dot(p - proj, p - proj);
        d = min(d, segd);

        float c0 = step(0.0, p.y - a.y);
        float c1 = 1.0 - step(0.0, p.y - b.y);
        float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
        float allCond = c0 * c1 * c2;
        float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
        float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
        s *= flip;
        return d;
    }

    float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
        float s = 1.0;
        float d = dot(p - v0, p - v0);

        d = seg(p, v0, v3, s, d);
        d = seg(p, v1, v0, s, d);
        d = seg(p, v2, v1, s, d);
        d = seg(p, v3, v2, s, d);

        return s * sqrt(d);
    }

    vec2 normalize(vec2 value, float isPosition) {
        return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
    }

    float blend(float t)
    {
        float sqr = t * t;
        return sqr / (2.0 * (sqr - t) + 1.0);
    }

    float antialising(float distance) {
        return 1. - smoothstep(0., normalize(vec2(2., 2.), 0.).x, distance);
    }

    float determineStartVertexFactor(vec2 a, vec2 b) {
        // Conditions using step
        float condition1 = step(b.x, a.x) * step(a.y, b.y); // a.x < b.x && a.y > b.y
        float condition2 = step(a.x, b.x) * step(b.y, a.y); // a.x > b.x && a.y < b.y

        // If neither condition is met, return 1 (else case)
        return 1.0 - max(condition1, condition2);
    }
    vec2 getRectangleCenter(vec4 rectangle) {
        return vec2(rectangle.x + (rectangle.z / 2.), rectangle.y - (rectangle.w / 2.));
    }

    const vec4 TRAIL_COLOR = vec4(${mkRGBA_valOnly { hex = "#${colors.base03}"; alpha = 1.0; }}) / vec4(255.0,255.0,255.0,255.0); //stylix driven
    const vec4 CURRENT_CURSOR_COLOR = TRAIL_COLOR;
    const vec4 PREVIOUS_CURSOR_COLOR = TRAIL_COLOR;
    const vec4 TRAIL_COLOR_ACCENT = vec4(${mkRGBA_valOnly { hex = "#${colors.base04}"; alpha = 1.0; }}) / vec4(255.0,255.0,255.0,255.0); //stylix driven
    const float DURATION = .2;
    const float OPACITY = .2;
    // Don't draw trail within that distance * cursor size.
    // This prevents trails from appearing when typing.
    const float DRAW_THRESHOLD = 1.5;
    // Don't draw trails within the same line: same line jumps are usually where
    // people expect them.
    const bool HIDE_TRAILS_ON_THE_SAME_LINE = false;

    void mainImage(out vec4 fragColor, in vec2 fragCoord)
    {
        #if !defined(WEB)
        fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
        #endif
        //Normalization for fragCoord to a space of -1 to 1;
        vec2 vu = normalize(fragCoord, 1.);
        vec2 offsetFactor = vec2(-.5, 0.5);

        //Normalization for cursor position and size;
        //cursor xy has the postion in a space of -1 to 1;
        //zw has the width and height
        vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.));
        vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.));

        //When drawing a parellelogram between cursors for the trail i need to determine where to start at the top-left or top-right vertex of the cursor
        float vertexFactor = determineStartVertexFactor(currentCursor.xy, previousCursor.xy);
        float invertedVertexFactor = 1.0 - vertexFactor;

        //Set every vertex of my parellogram
        vec2 v0 = vec2(currentCursor.x + currentCursor.z * vertexFactor, currentCursor.y - currentCursor.w);
        vec2 v1 = vec2(currentCursor.x + currentCursor.z * invertedVertexFactor, currentCursor.y);
        vec2 v2 = vec2(previousCursor.x + currentCursor.z * invertedVertexFactor, previousCursor.y);
        vec2 v3 = vec2(previousCursor.x + currentCursor.z * vertexFactor, previousCursor.y - previousCursor.w);

        vec4 newColor = vec4(fragColor);

        float progress = blend(clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1));
        float easedProgress = ease(progress);

        //Distance between cursors determine the total length of the parallelogram;
        vec2 centerCC = getRectangleCenter(currentCursor);
        vec2 centerCP = getRectangleCenter(previousCursor);
        float cursorSize = max(currentCursor.z, currentCursor.w);
        float trailThreshold = DRAW_THRESHOLD * cursorSize;
        float lineLength = distance(centerCC, centerCP);
        //
        bool isFarEnough = lineLength > trailThreshold;
        bool isOnSeparateLine = HIDE_TRAILS_ON_THE_SAME_LINE ? currentCursor.y != previousCursor.y : true;
        if (isFarEnough && isOnSeparateLine) {
            float distanceToEnd = distance(vu.xy, centerCC);
            float alphaModifier = distanceToEnd / (lineLength * (easedProgress));

            if (alphaModifier > 1.0) { // this change fixed it for me.
                alphaModifier = 1.0;
            }

            float sdfCursor = getSdfRectangle(vu, currentCursor.xy - (currentCursor.zw * offsetFactor), currentCursor.zw * 0.5);
            float sdfTrail = getSdfParallelogram(vu, v0, v1, v2, v3);

            newColor = mix(newColor, TRAIL_COLOR_ACCENT, 1.0 - smoothstep(sdfTrail, -0.01, 0.001));
            newColor = mix(newColor, TRAIL_COLOR, antialising(sdfTrail));
            newColor = mix(fragColor, newColor, 1.0 - alphaModifier);
            fragColor = mix(newColor, fragColor, step(sdfCursor, 0));
        }
    }
  '';

  synesthaxia_tweened = ''
    /*─────────────────────────────────────────────────────────────────────────
     *  cursor_smear_dynamic.glsl  —  Ghostty custom-shader drop-in (rev 3)
     *    • trail now aligned to cursor row
     *    • colour chosen from the most **vivid corner** (<-- THIS IS THE 'ISSUE' WITH COLOR SAMPLING!!! Pretty interesting function though)
     *     of **each** cursor rect (<-- COULD THIS BE CAUSING THE PHANTOM THIRD CURSOR LOCATION (see video embedded in README) ???)
     *────────────────────────────────────────────────────────────────────────*/

    /* ───── Tunables (constants only) ─────────────────────────────────────── */
    const float DURATION = 0.30; /* tween time (s)                    */
    const float TRAIL_OPACITY = 1.00; /* global α of trail                 */
    const float CURVE_STRENGTH = 0.00; /* −: concave  +: convex             */
    const float EDGE_SOFT = 0.001; /* AA width in NDC units             */
    const float GLOW_RADIUS = 0.002; /* halo thickness (NDC)              */
    const float GLOW_INTENSITY = 0.90; /* halo α multiplier                 */
    const float CURSOR_HIDE_AT = 1.00; /* hide stand-in when prog ≥ …       */
    /* ─────────────────────────────────────────────────────────────────────── */

    /* pixel → NDC (−1‥+1 across short axis, keeps aspect) */
    vec2 ndc(vec2 px, float isPos) {
        return (px * 2.0 - iResolution.xy * isPos) / iResolution.y;
    }

    /* fast coverage for AA */
    float cover(float sd) {
        return clamp(0.5 - sd / EDGE_SOFT, 0.0, 1.0);
    }

    /* cubic ease-out */
    float ease(float t) {
        return 1.0 - pow(1.0 - t, 3.0);
    }

    /* SDF of axis-aligned box centred at `c`, half-size `b` (both NDC) */
    float sdBox(vec2 p, vec2 c, vec2 b) {
        vec2 d = abs(p - c) - b;
        return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
    }

    /* signed distance to parallelogram (v0→v1→v2→v3, NDC) */
    float sdPara(vec2 p, vec2 v0, vec2 v1, vec2 v2, vec2 v3) {
        float w = 1.0;
        float d2 = dot(p - v0, p - v0);
        #define EDGE(A,B)                                                                 \
          {                                                                             \
              vec2 e = B - A, wv = p - A;                                               \
              vec2 proj = A + e * clamp(dot(wv, e) / dot(e, e), 0.0, 1.0);              \
              d2 = min(d2, dot(p - proj, p - proj));                                    \
              float c0 = step(0.0, p.y - A.y);                                          \
              float c1 = 1.0 - step(0.0, p.y - B.y);                                    \
              float c2 = 1.0 - step(0.0, e.x * wv.y - e.y * wv.x);                      \
              float flip = mix(1.0, -1.0, step(0.5, c0 * c1 * c2 +                      \
                                               (1.0 - c0) * (1.0 - c1) * (1.0 - c2)));\
              w *= flip;                                                                \
          }
        EDGE(v0, v1)
        EDGE(v1, v2)
        EDGE(v2, v3)
        EDGE(v3, v0)
        #undef EDGE
        return w * sqrt(d2);
    }

    /* framebuffer fetch with clamped coords */
    vec3 sampleFB(vec2 px) {
        return texture(iChannel0,
            clamp((px + 0.5) / iResolution.xy,
                vec2(0.0), vec2(1.0))).rgb;
    }

    /* choose edge whose outward normal best matches motion direction */
    void pickEdge(vec4 r, vec2 dir, bool origin, out vec2 aPx, out vec2 bPx) {
        vec2 N[4] = vec2[4](vec2(-1, 0), vec2(1, 0), vec2(0, -1), vec2(0, 1));
        float best = origin ? -1e9 : 1e9;
        int idx = 0;
        for (int i = 0; i < 4; ++i) {
            float d = dot(dir, N[i]);
            if (origin ? d > best : d < best) {
                best = d;
                idx = i;
            }
        }
        vec2 TL = r.xy;
        vec2 TR = TL + vec2(r.z, 0.0);
        vec2 BL = TL - vec2(0.0, r.w);
        vec2 BR = TL + vec2(r.z, -r.w);

        if (idx == 0) {
            aPx = TL;
            bPx = BL;
        }
        else if (idx == 1) {
            aPx = TR;
            bPx = BR;
        }
        else if (idx == 2) {
            aPx = TL;
            bPx = TR;
        }
        else {
            aPx = BL;
            bPx = BR;
        }
    }

    /* vividness score for RGB */
    float vividScore(vec3 c) {
        float vmax = max(max(c.r, c.g), c.b);
        float vmin = min(min(c.r, c.g), c.b);
        float sat = vmax > 0.0 ? (vmax - vmin) / vmax : 0.0;
        return sat * vmax;
    }

    /* colour representative for a cursor rect: pick most vivid corner */
    vec3 rectColor(vec4 r) {
        vec2 TL = r.xy;
        vec2 TR = TL + vec2(r.z, 0.0);
        vec2 BL = TL - vec2(0.0, r.w);
        vec2 BR = TL + vec2(r.z, -r.w);

        vec3 c0 = sampleFB(TL + vec2(0.5, -0.5));
        vec3 c1 = sampleFB(TR + vec2(-0.5, -0.5));
        vec3 c2 = sampleFB(BL + vec2(0.5, 0.5));
        vec3 c3 = sampleFB(BR + vec2(-0.5, 0.5));

        vec3 best = c0;
        float scr = vividScore(c0);
        float s1 = vividScore(c1);
        if (s1 > scr) {
            best = c1;
            scr = s1;
        }
        float s2 = vividScore(c2);
        if (s2 > scr) {
            best = c2;
            scr = s2;
        }
        float s3 = vividScore(c3);
        if (s3 > scr) {
            best = c3;
        }
        return best;
    }

    /*─────────────────────────────────────────────────────────────────────────*/
    void mainImage(out vec4 fragColor, in vec2 fragCoord) {
        /* 1. base terminal buffer */
        #if !defined(WEB)
        fragColor = texture(iChannel0, fragCoord / iResolution.xy);
        #endif

        /* 2. cursor rects (pixels) */
        vec4 cur = iCurrentCursor;
        vec4 prv = iPreviousCursor;
        vec2 dirPx = cur.xy - prv.xy;

        /* 3. build swept parallelogram */
        vec2 p0, p1, q0, q1;
        pickEdge(prv, dirPx, true, p0, p1); /* origin edge */
        pickEdge(cur, dirPx, false, q0, q1); /* dest   edge */

        vec2 v0 = ndc(p0, 1.0), v1 = ndc(p1, 1.0);
        vec2 v2 = ndc(q1, 1.0), v3 = ndc(q0, 1.0);
        vec2 P = ndc(fragCoord, 1.0);

        float sdTrail = sdPara(P, v0, v1, v2, v3);
        float len = length(v3 - v0);
        float tAlong = clamp(dot(P - v0, (v3 - v0) / len), 0.0, 1.0);
        sdTrail /= (1.0 + CURVE_STRENGTH * (tAlong - 0.5) * 2.0);

        /* 4. tween progress & stand-in cursor SDF */
        float rawProg = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
        float prog = ease(rawProg);
        float moving = 1.0 - step(CURSOR_HIDE_AT, prog);

        vec2 tweenPx = mix(prv.xy, cur.xy, prog);
        vec2 halfPx = cur.zw * 0.5;
        vec2 centrePx = tweenPx + vec2(halfPx.x, -halfPx.y);
        vec2 centreN = ndc(centrePx, 1.0);
        vec2 halfN = ndc(halfPx, 0.0);
        float sdCursor = sdBox(P, centreN, halfN);

        /* 5. colour sampling */
        vec3 colStart = rectColor(prv);
        vec3 colEnd = rectColor(cur);
        vec3 colTrail = mix(colStart, colEnd, tAlong);
        vec3 colTween = mix(colStart, colEnd, prog);

        /* 6. coverages */
        float trailVis = 1.0 - abs(1.0 - 2.0 * prog); /* grow→fade */
        float covTrail = cover(sdTrail) * TRAIL_OPACITY * trailVis;
        float covCursor = cover(sdCursor) * moving;
        float covGlow = cover(sdCursor - GLOW_RADIUS) *
                (1.0 - cover(sdCursor)) *
                GLOW_INTENSITY * moving;

        /* 7. composite */
        vec3 outRGB = fragColor.rgb;
        outRGB = mix(outRGB, colTrail, covTrail); /* trail */
        outRGB = mix(outRGB, colTween, covGlow); /* halo  */
        outRGB = mix(outRGB, colTween, covCursor); /* block */

        fragColor.rgb = outRGB;
    }
  '';
}
