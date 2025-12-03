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
     *    • bursts of "glitter" appear as the cursor moves to either an adjacent column or row
     *    • effect does not render for cursor jumps beyond 10 columns, nor for greater than a single row
     *    • Stylix colours drive tint and opacity without extra shader edits
     *────────────────────────────────────────────────────────────────────────*/

    /* ───── Configuration ────────────────────────────────────────────────── */
    const float DURATION = 2.5;           /* particle lifetime (s)              */
    const float BIN_INTERVAL = 0.12;      /* time between particle spawn bins   */
    const float PARTICLE_COUNT = 25.0;    /* particles per bin                  */
    const float MAX_COL_JUMP = 10.0;      /* max horizontal jump to render      */
    const float MAX_ROW_JUMP = 1.0;       /* max vertical jump to render        */
    const float PARTICLE_SIZE = 0.003;    /* base particle radius (NDC)         */
    const float FALL_SPEED = 0.15;        /* downward drift speed               */
    const float SPREAD = 0.08;            /* horizontal spread multiplier       */
    const vec4 GLITTER_COLOR = vec4(${mkRGBA_valOnly { hex = "#${colors.base0A}"; alpha = 0.9; }}) / vec4(255.0,255.0,255.0,255.0);
    const vec4 GLITTER_ACCENT = vec4(${mkRGBA_valOnly { hex = "#${colors.base0D}"; alpha = 0.7; }}) / vec4(255.0,255.0,255.0,255.0);
    /* ─────────────────────────────────────────────────────────────────────── */

    /* 2D random hash for particle generation */
    float hash(vec2 p) {
        p = fract(p * vec2(123.456, 789.123));
        p += dot(p, p + 45.678);
        return fract(p.x * p.y);
    }

    /* pixel → NDC conversion */
    vec2 ndc(vec2 px, float isPos) {
        return (px * 2.0 - iResolution.xy * isPos) / iResolution.y;
    }

    /* ease out cubic */
    float easeOut(float t) {
        return 1.0 - pow(1.0 - t, 3.0);
    }

    /* ease in cubic */
    float easeIn(float t) {
        return t * t * t;
    }

    /* twinkle animation for sparkle */
    float twinkle(float t, float seed) {
        float phase = fract(seed * 7.123);
        float pulse = sin((t + phase) * 12.0 + seed * 6.28) * 0.5 + 0.5;
        return pulse * pulse;
    }

    void mainImage(out vec4 fragColor, in vec2 fragCoord) {
        /* base terminal buffer */
        #if !defined(WEB)
        fragColor = texture(iChannel0, fragCoord / iResolution.xy);
        #endif

        /* current fragment in NDC */
        vec2 fragNDC = ndc(fragCoord, 1.0);

        /* cursor movement delta in columns/rows */
        vec2 cursorDelta = iCurrentCursor.xy - iPreviousCursor.xy;
        float colJump = abs(cursorDelta.x / iCurrentCursor.z);
        float rowJump = abs(cursorDelta.y / iCurrentCursor.w);

        /* cursor bounds in NDC for clamping */
        vec2 cursorTopNDC = ndc(iCurrentCursor.xy, 1.0);
        vec2 cursorBottomNDC = ndc(iCurrentCursor.xy + vec2(0.0, iCurrentCursor.w), 1.0);
        float cursorMinY = min(cursorTopNDC.y, cursorBottomNDC.y);
        float cursorMaxY = max(cursorTopNDC.y, cursorBottomNDC.y);

        vec3 glitterAccum = vec3(0.0);
        float alphaAccum = 0.0;

        /* iterate through time bins within DURATION */
        float maxBins = ceil(DURATION / BIN_INTERVAL);
        for (float binIdx = 0.0; binIdx < maxBins; binIdx += 1.0) {
            /* calculate bin spawn time */
            float binTime = iTimeCursorChange + binIdx * BIN_INTERVAL;
            float binAge = iTime - binTime;

            /* skip bins not yet spawned or older than DURATION */
            if (binAge < 0.0 || binAge > DURATION) continue;

            /* only check movement threshold for the first bin */
            if (binIdx == 0.0 && (colJump > MAX_COL_JUMP || rowJump > MAX_ROW_JUMP)) {
                continue;
            }

            float progress = binAge / DURATION;
            float fade = 1.0 - easeIn(progress);

            /* cursor trail start/end in NDC */
            vec2 cursorStart = ndc(iPreviousCursor.xy + iPreviousCursor.zw * 0.5, 1.0);
            vec2 cursorEnd = ndc(iCurrentCursor.xy + iCurrentCursor.zw * 0.5, 1.0);
            vec2 trailVector = cursorEnd - cursorStart;

            /* motion intensity determines particle density */
            float intensity = min(1.0, length(cursorDelta) / (iCurrentCursor.z * 3.0));
            float activeParticles = PARTICLE_COUNT * intensity;

            /* generate particles for this bin */
            for (float i = 0.0; i < PARTICLE_COUNT; i += 1.0) {
                if (i >= activeParticles) break;

                /* unique seed per particle AND bin */
                vec2 seed = vec2(i * 0.127, binTime * 0.031 + binIdx * 13.579);

                /* spawn position along trail */
                float spawnPos = hash(seed);
                vec2 particleOrigin = mix(cursorStart, cursorEnd, spawnPos);

                /* random offset perpendicular to motion */
                vec2 perpendicular = vec2(-trailVector.y, trailVector.x);
                if (length(perpendicular) > 0.0) {
                    perpendicular = normalize(perpendicular);
                }
                float offsetAmount = (hash(seed + vec2(1.5, 2.7)) - 0.5) * SPREAD;
                particleOrigin += perpendicular * offsetAmount;

                /* particle animation over time */
                float particleAge = progress + hash(seed + vec2(3.1, 4.2)) * 0.2;
                particleAge = clamp(particleAge, 0.0, 1.0);

                /* drift motion */
                vec2 drift = vec2(
                    (hash(seed + vec2(5.3, 6.4)) - 0.5) * 0.05,
                    -FALL_SPEED
                ) * particleAge;

                vec2 particlePos = particleOrigin + drift;

                /* clamp particle Y position to cursor bounds */
                particlePos.y = clamp(particlePos.y, cursorMinY, cursorMaxY);

                /* distance to particle */
                float dist = length(fragNDC - particlePos);

                /* particle size variation */
                float sizeVar = 0.5 + hash(seed + vec2(7.5, 8.6)) * 0.5;
                float radius = PARTICLE_SIZE * sizeVar;

                /* soft circle with glow */
                float particleShape = smoothstep(radius * 2.0, 0.0, dist);
                float coreShape = smoothstep(radius, 0.0, dist);

                /* sparkle intensity */
                float sparkle = twinkle(particleAge, hash(seed + vec2(9.7, 10.8)));
                float alpha = particleShape * fade * (0.3 + sparkle * 0.7);

                /* color variation between primary and accent */
                float colorMix = hash(seed + vec2(11.9, 12.1));
                vec3 particleColor = mix(GLITTER_COLOR.rgb, GLITTER_ACCENT.rgb, colorMix);

                /* bright core */
                particleColor = mix(particleColor, vec3(1.0), coreShape * sparkle * 0.5);

                glitterAccum += particleColor * alpha;
                alphaAccum += alpha;
            }
        }

        /* composite glitter over terminal buffer */
        if (alphaAccum > 0.0) {
            vec3 blendedColor = mix(fragColor.rgb, glitterAccum / max(alphaAccum, 0.001), min(alphaAccum, 1.0));
            fragColor.rgb = blendedColor;
        }
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
