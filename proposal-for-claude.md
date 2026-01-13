## Agent Orchestration Guidelines (Claude Code)

Use this section when Claude Code acts as an orchestrator selecting sub-agents and running a tribunal review.

### Agent Roles (use exact names)

- Software Engineer (Codex, GPT-5.2)
- Technical Researcher (Gemini 3 Pro)
- Executive Advisor (Claude Opus 4.5)

### Domain -> Expert Agent Selection

Pick the best-fit expert agent for the primary domain of the user request:

- Programming: Software Engineer (Codex, GPT-5.2)
- Advice: Executive Advisor (Claude Opus 4.5)
- Teaching: Technical Researcher (Gemini 3 Pro)
- Technical research: Technical Researcher (Gemini 3 Pro)
- Medical device industry knowledge (USA/EU): Executive Advisor (Claude Opus 4.5)
- Executive functions (planning, prioritization, coordination): Executive Advisor (Claude Opus 4.5)
- Other / generalist: Technical Researcher (Gemini 3 Pro)

If the request spans multiple domains, choose the agent for the highest-risk domain first (medical, legal, financial, or safety-critical), then consult the next best-fit agent if needed.

### Tribunal Workflow

After the expert agent returns a result, initiate a tribunal review using:

`/tribunal <User's objective defining prompt>`

The user can also invoke `/tribunal` at any time to scrutinize the most recent work.

### Tribunal Composition

- Tribunal members: the same 3 agents above, instantiated fresh for the review.
- Each agent performs independent verification and investigation of the output under review.
- Each agent submits: pass/fail, key findings, and concrete fixes if failing.

### Voting Rules (weighted)

Weight each vote by evidence-based proficiency for the domain under review.

Default weights by domain:
- Programming: Software Engineer 0.60, Technical Researcher 0.25, Executive Advisor 0.15
- Advice: Executive Advisor 0.55, Technical Researcher 0.30, Software Engineer 0.15
- Teaching: Technical Researcher 0.50, Executive Advisor 0.30, Software Engineer 0.20
- Technical research: Technical Researcher 0.60, Executive Advisor 0.25, Software Engineer 0.15
- Medical device (USA/EU): Executive Advisor 0.55, Technical Researcher 0.30, Software Engineer 0.15
- Executive functions: Executive Advisor 0.60, Technical Researcher 0.25, Software Engineer 0.15
- Generalist: Technical Researcher 0.45, Executive Advisor 0.35, Software Engineer 0.20

Pass if the weighted sum of pass votes is >= 0.60. Otherwise fail.

### Fail Loop

- On fail, resubmit the same user objective to the expert agent.
- Incorporate tribunal feedback explicitly.
- Cap retries at 2. After 2 failures, return the best available answer with a clear disclaimer and list of unresolved issues.

### Accuracy and Verification

- Tribunal must verify claims independently and prefer primary sources for high-stakes domains.
- If verification is not possible, mark as unverified and lower confidence.
