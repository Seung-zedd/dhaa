# Claude Code: Tacit Knowledge Synthesis

_Extracted and synthesized from Anthropic's Multi-Agent Orchestration codebase and production experience._

This document crystallizes the "tacit knowledge" (architectural principles and core mental models) used by Anthropic to build advanced multi-agent systems. These insights go beyond simple implementation and focus on the deep abstraction principles required for high-quality agentic reasoning.

---

### Mental Model #1: "The Coordinator understands; the Worker executes"

This is the most fundamental philosophy of the entire system. One sentence in the system prompt stands out:

**"Never delegate understanding."**

The Coordinator’s primary role is **Synthesis**. When a worker reports research results, the Coordinator must digest the information itself and then provide specific specs—including exact file paths, line numbers, and precise logic changes—to the next worker.

- **Anti-pattern:** Phrases like "based on your findings, fix the bug" or "implement it based on the research" are strictly forbidden. This offloads the burden of understanding to the worker.
- **Principle:** The orchestrator must never be a "pass-through" node. Every intermediate result must be consumed by the orchestrator, and evidence of that consumption must be present in the next instruction. If the orchestrator says "just figure it out," the quality of the system collapses.

---

### Mental Model #2: "The Agent is a smart colleague who just walked into the room"

Guidelines for writing worker prompts emphasize:

> "Brief the agent like a smart colleague who just walked into the room — it hasn't seen this conversation, doesn't know what you've tried, doesn't understand why this task matters."

This is a design philosophy that accepts the fundamental constraints of LLM-based agents. Each worker operates in an independent context window; therefore, the prompt is its "entire world."

- **Action:** Explain what you are trying to achieve and why it matters. Describe what has already been learned or ruled out. Provide enough peripheral context for the worker to exercise judgment.
- **Key Insight:** "Lookups: hand over the exact command. Investigations: hand over the question." Giving fixed procedures for exploratory tasks creates "dead weight" if the initial premise is wrong.

---

### Mental Model #3: "Two Orchestration Modes — Coordinator vs. Fork"

Anthropic distinguishes between two fundamentally different delegation models, which are mutually exclusive.

1.  **Coordinator Mode:** The coordinator does not use tools directly. it uses `AgentTool` (create worker), `SendMessageTool` (instruct existing worker), and `TaskStopTool` (stop worker). The coordinator is the "brain," and workers are the "hands."
2.  **Fork Mode:** A parent agent clones itself. The child inherits the entire conversation context and system prompt. It shares the parent's prompt cache (saving cost and time), and the instruction becomes a "directive" rather than a "context briefing."

- **Deep Meaning:** Fork is used when the intermediate output doesn't need to remain in the parent's context. This reflects the core concept of **Context Hygiene**—consciously managing what stays in an agent's context window.

---

### Mental Model #4: "Context Overlap determines Continue vs. Spawn"

The decision framework verified in production is:

- **Continue (`SendMessageTool`):** Use when research has found the exact files to edit, to correct failures, or to extend recent work. The worker already has the error context and knows what was just tried.
- **Spawn (`AgentTool`):** Use when research was broad but implementation is narrow (to avoid dragging along "investigation noise"), to verify another worker's code (requires an independent perspective), or if the first implementation was an entirely wrong approach (to avoid polluting the retry with flawed context).

- **Principle:** There is no universal default. Think about how much of the worker's context overlaps with the next task.

---

### Mental Model #5: "Verification is 'Proving it Works,' not 'Confirming existence'"

The system prompt is very firm on Verification:

> "Verification means proving the code works, not confirming it exists. A verifier that rubber-stamps weak work undermines everything."

- **Guidelines:** Run tests with the feature enabled, perform type-checks, investigate errors, stay skeptical, and test independently. Do not simply re-run what the implementation worker ran; instead, try edge cases and error paths.
- **Context Rule:** Verification workers should almost always be a fresh **Spawn**, as implementation assumptions from the original worker can "blind" the verification process.

---

### Mental Model #6: "Parallelism is a Superpower — with Concurrency Rules"

The system prompt declares: **"Parallelism is your superpower."**

- **Rules:** Read-only tasks (research) can run freely in parallel. Writing tasks (implementation) should be limited to one per file set. Verification can run in parallel with implementation if it targets different file areas.
- **Technical Note:** Using multiple `tool_use` blocks in a single message triggers parallel execution.

---

### Mental Model #7: "Prompt Caching drives Architecture"

API cost optimization shapes the architecture itself. To maximize Anthropic's prompt caching:

- **Byte-Identity:** All fork children must generate byte-identical API request prefixes. The system maintains the parent's assistant messages exactly and use identical placeholder text for all `tool_use` blocks ("Fork started — processing in background"). Only the final text block differs per child.
- **Separation of Dynamic/Static:** Agent lists are separated into attachments rather than inlined in tool descriptions. This prevents minor changes in the dynamic agent list or MCP connections from invalidating the entire prompt cache.

---

### Mental Model #8: "Worker results are Internal Signals, not Conversation Partners"

The Coordinator prompt dictates:

> "Every message you send is to the user. Worker results and system notifications are internal signals, not conversation partners — never thank or acknowledge them."

- **Abstraction Principle:** Clearly separate the interface between the Orchestrator and User from the interface between the Orchestrator and Worker. Never treat worker results as a "chat" (avoiding "Thank you, Worker A").

---

### Mental Model #9: "Do not predict results — Do not fabricate"

A strict rule for Fork mode:

> "Don't race. After launching, you know nothing about what the fork found. Never fabricate or predict fork results in any format."

If a user asks for status, simply reply "It's still running—it will be ready soon." The most dangerous failure in an agentic system is presenting a hallucinated result as a real one.

---

### Mental Model #10: "The Scratchpad — Shared Memory between Agents"

A `scratchpad` directory allows workers to read and write without repeated permission prompts. This is for **"durable cross-worker knowledge."**

- This is the third channel of communication:
  1.  Messages via Coordinator (`SendMessageTool`)
  2.  Reports via `task-notification`
  3.  Asynchronous sharing via the File System (IPC).

---

### Mental Model #11: "The 4-Step Workflow — Research → Synthesis → Implementation → Verification"

This is the universal workflow for almost any complex task:

1.  **Research:** Workers explore the codebase in parallel.
2.  **Synthesis:** _Only the Coordinator_ reads the results, understands the scope, and writes the implementation specification.
3.  **Implementation:** A worker executes the changes and commits them based on the spec.
4.  **Verification:** A _separate_ worker proves the changes work.

---

### Mental Model #12: "On Failure — Continue the same Worker"

> "Continue the same worker with SendMessageTool — it has the full error context."

Don't discard a failing worker immediately. It already knows the state of the system and what didn't work. However, if repeated corrections fail, notify the user or try a completely new approach (Fresh Spawn).

---

### 📋 Abstraction Checklist for your Agentic System

- [ ] **No delegated understanding.** Orchestrator synthesizes every step.
- [ ] **Brief like a smart colleague.** High-context goals, low-friction constraints.
- [ ] **Continue vs. Spawn.** Let context hygiene drive your delegation mode.
- [ ] **Independent Verification.** Proving work, not just rubber-stamping.
- [ ] **Read Parallel, Write Serial.** Maintain consistency.
- [ ] **Cache-conscious architecture.** Separate static and dynamic components.
- [ ] **No "Chatting" with workers.** Results are internal signals.
- [ ] **Zero Fabrication.** "I don't know yet" is the only answer for pending tasks.
- [ ] **File System as IPC.** Use the scratchpad for durable shared state.
