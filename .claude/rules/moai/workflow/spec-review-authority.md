---
paths: ".moai/specs/**,docs/review/**,PRD.md,**/.claude/agents/spec-interrogator.md,**/.claude/agents/moai/plan-auditor.md"
---

# SPEC Review — Authority Chain and the Founder Decision Gate

Detail for the SPEC Review Pipeline section of CLAUDE.md. Loads only on the paths above,
so it costs nothing on any other turn.

This file exists because two failures keep recurring in SPEC review: a SPEC quietly
deciding something the PRD had not settled, and the founder reading an AI recommendation
before forming an independent judgment. Both are decision-authority failures, not
formatting problems.

**The one sentence this file enforces:** AI audits, interrogates, routes, analyses and
executes. **The founder is the only decider.**

Applies to projects that keep a PRD. A project without one uses sections 5 through 8
unchanged and skips the PRD-specific checks.

---

## 1. Authority chain

```
PRD             product intent, scope, phase boundaries, founder-level decisions
  |
spec.md         implementable requirements
  |
acceptance.md   observable acceptance behaviour
  |
plan.md         implementation strategy
  |
code
```

`spec-compact.md` is **not** an authority source. It is a compressed representation of
the other three for LLM context, and it never carries a decision the others lack.

[HARD] A SPEC MUST NOT settle a product decision the PRD has not settled. When it does,
that is a Stage 2 judgment point, never a Stage 1 fix.

---

## 2. How to read the PRD

Most PRDs are prose. They record state in ordinary language rather than in
machine-readable markers, and one sentence routinely carries several states at once — a
candidate marked *not adopted*, then kept as reference material, then deferred to
post-launch data. **Do not try to derive state by grepping for keywords.**

### 2.1 Separate the version history from the body

Nearly every PRD carries a change-log or version-summary region above the numbered body.

[HARD] That region is HISTORICAL. Never cite it as a current requirement. It exists to
record what changed, and it routinely describes designs that were later dropped — an
entry may describe replacing a feature that had already been discarded, and reading it as
current would resurrect a rejected design.

Establish the boundary once, structurally (for example, "everything before the first
numbered section heading"), and record it in the project's own CLAUDE.md so both review
agents apply the same cut.

### 2.2 State of a CURRENT statement — read it, do not guess it

Within the body, judge each statement into one of:

- **CONFIRMED** — settled now. A SPEC contradicting it is a contradiction.
- **DEFERRED** — direction exists, verdict does not. A SPEC resolving it is a Stage 2 flag.
- **POST-MVP** — out of the current phase. A SPEC requiring it now is a scope issue.
- **REJECTED** — explicitly not adopted. Never revive from an old PRD phrasing alone.

[HARD] **If the state is not unambiguous, the statement is not authority.** Do not
resolve the ambiguity; route the item to Stage 2 as a judgment point. This is
conservative escalation applied to PRD reading itself, and it is what makes a
marker-free PRD safe to consult.

Recognised as PRD-level unless the text says otherwise: product scope, phase boundary,
tier or plan behaviour, user-visible UX flow, brand identity, pricing, privacy and
security promises.

---

## 3. Stage 1 — what PRD cross-validation may and may not conclude

plan-auditor gains PRD checks (Group 8, inside `LOCAL-EXT` markers). It may report a
**mechanical** defect only when all of these hold:

1. The PRD statement is in the CURRENT region (section 2.1)
2. Its state is unambiguously CONFIRMED or POST-MVP (section 2.2)
3. The SPEC conflict is direct, not inferred through a chain of reasoning
4. The exact PRD section can be cited

Otherwise: no finding. Hand it to Stage 2.

| Drift | Route |
|---|---|
| PRD CONFIRMED, SPEC missing it, and it falls in this SPEC's scope | Stage 1 coverage gap |
| PRD CONFIRMED, SPEC contradicts | Stage 1 contradiction |
| PRD DEFERRED, SPEC resolves it | **Stage 2** (never Stage 1) |
| PRD POST-MVP, SPEC requires it in the current phase | Stage 1 scope violation — unless the phase boundary itself is ambiguous, then Stage 2 |
| SPEC introduces product behaviour absent from PRD | Ask: implementation detail, or new product-level behaviour? Detail is fine. Product-level goes to Stage 2, and if confirmed, to section 7 propagation |

---

## 4. Stage 2 — unchanged contract, sharpened PRD reading

spec-interrogator reads the PRD as product ground truth for Category 5. That is **not**
authoring context — the context-isolation rule bans SPEC-authoring reasoning, prior
drafts, conversation history and stated founder preferences, not authoritative product
artifacts.

[HARD] The recommendation ban is unchanged and absolute: never answer a raised question,
never recommend a resolution, never conclude "this is probably fine" or "this should be
X". **A flag containing a proposed answer is a defective flag.** A preferred answer must
not be smuggled into the phrasing of the question either.

---

## 5. The decision index — authority routing, not importance ranking

`docs/review/{SPEC-ID}/question/decision-index.md` is produced by the orchestrator after
Stage 2. It replaces the older habit of writing a combined triage-and-recommendation
draft, which anchored the founder before they had judged anything.

Its job is **not** to shorten the founder's thinking. It is to route each flag to whoever
already has authority over it, so founder attention goes only where no authority exists.

### 5.1 Types

| Type | Meaning | Founder action |
|---|---|---|
| `DECIDED` | A previous founder verdict already covers this exact condition | `NONE` |
| `POLICY-COVERED` | An explicit PRD requirement, ADR, or engineering policy applies unchanged | `NONE_UNLESS_OVERRIDE` |
| `EVIDENCE-NEEDED` | Choosing requires data or a measurement that does not exist yet | `REQUEST_EVIDENCE` / `TEMPORARY_VERDICT` / `DEFER` |
| `FOUNDER` | No existing authority answers it | `DECIDE` / `NEED_ANALYSIS` / `NEED_EVIDENCE` / `DEFER` |

A flag whose answer turns out to exist inside the documents is not a founder decision at
all. List it in a separate `Stage 1 handoff` section of the index — visible, never
deleted — and route it to plan-auditor. [HARD] Repairing such a flag is mechanical only
while a single repair exists. When the contradiction can be fixed in more than one
direction and the directions differ in scope or product effect, choosing the direction is
a `FOUNDER` decision, even though the defect that exposed it was mechanical.

### 5.2 POLICY-COVERED and DECIDED require all nine

1. Explicit authority actually exists in this repository
2. Its exact source path can be cited
3. Its section or decision id can be cited
4. The authority's scope is the same as this question's
5. No new user-visible behaviour is created
6. No new persistence or public API contract is created
7. No data migration is required
8. It is not a brand or taste judgment
9. Applicability is unambiguous

[HARD] Fail any one and the type is `FOUNDER`. **An LLM "best practice" is not a
policy.** Similarity of topic is not applicability.

### 5.3 Never auto-downgrade

Anything touching these starts at `FOUNDER` or `EVIDENCE-NEEDED`: new user-visible
behaviour · product scope · phase boundary · persistence contract · public API contract ·
data migration · identity semantics · state lifetime · destructive or irreversible
behaviour · costly-reversible decisions · product priority · UX policy · tier and pricing
behaviour · brand identity · visual taste · privacy or security promises · unknown
trade-offs · any PRD DEFERRED item.

**When uncertain, escalate. Never downgrade.** One extra question read costs the founder
a minute; one product decision silently made by an AI costs a re-decision later.

### 5.4 Index format

```
| ID | Type | Decision surface | Authority | Impact | Reversibility | Action |
```

- `ID` is the original `interrogation-draft.md` question id. [HARD] Never renumber, never
  drop a flag from the index — routing changes who answers, never whether it is shown
- Bundling related flags into decision surfaces is allowed and encouraged; the original
  ids stay visible
- `Reversibility` is one of `EASY_REVERSIBLE`, `COSTLY_REVERSIBLE`, `HARD_TO_REVERSE`,
  `UNKNOWN`. It describes the cost of changing the decision later — it is **not** an
  importance score. No evidence means `UNKNOWN`

### 5.5 FOUNDER entry body

Show only: the question · PRD relation (`confirmed` / `deferred` / `absent` /
`conflicting`) · known constraints · options **only where the sources themselves produce
them** · the concrete failure or consequence · affected surface · reversibility ·
existing authority (`NONE` if none) · founder action.

[HARD] No recommendation. No preferred option marked. Do not invent a choice architecture
the sources do not contain — inventing the options is itself an anchoring act.

---

## 6. Analysis is pull, not push

[HARD] No analysis and no recommendation is produced for a flag until the founder marks
it `NEED_ANALYSIS`. Writing a verdict directly closes the flag with no AI input at all.

When requested, write `docs/review/{SPEC-ID}/question/analysis/{Qn}.md`: the question ·
relevant PRD and SPEC constraints · for each option its upside, downside and a concrete
failure scenario · unknowns · reversibility · the strongest argument for each side · what
evidence would discriminate between them.

Still no single recommendation. A recommendation appears **only** when the founder marks
`REQUEST_RECOMMENDATION`, and then it is written as an assessment: preferred option ·
confidence · strongest reason for · strongest argument against · what would change this
assessment.

```
FLAGGED -> TRIAGED -> DECIDED | POLICY-COVERED | EVIDENCE-NEEDED | FOUNDER

FOUNDER -> INITIAL_JUDGMENT -> decide ---------------+
                            -> unsure               |
                                 -> NEED_ANALYSIS   |
                                 -> AI ANALYSIS ----+
                                                    |
                                                    +-> FINAL_VERDICT -> Stage 3
```

[HARD] An AI preferred answer must never reach the founder before their independent
judgment or an explicit request for it.

---

## 7. Stage 3 — and when a verdict must reach the PRD

Canonical verdict source is `docs/review/{SPEC-ID}/question/answer.md`. Not canonical:
`audit-report.md`, `interrogation-draft.md`, `decision-index.md`, `analysis/{Qn}.md`, and
any AI recommendation.

Before applying a verdict, classify it:

- **SPEC-level** — index strategy, retry counts, internal algorithms, query shape,
  implementation detail. Apply to the SPEC set only.
- **Product-level** — phase or scope, tier behaviour, user-visible UX flow, brand
  identity policy, pricing, privacy or security promises.

[HARD] A product-level verdict applied to the SPEC alone recreates the PRD drift this
pipeline exists to catch. Report `PRD update required`, naming the PRD section, and
reconcile PRD and SPEC together — **strictly within the confirmed verdict**. Never
rewrite or extend surrounding PRD content the founder did not decide on.

---

## 8. Traceability

```
PRD section -> REQ id -> interrogation Qn -> decision-index Qn
            -> analysis/Qn.md (optional) -> answer.md Qn
            -> changed REQ / scenario / plan -> SPEC HISTORY
            -> PRD section update (product-level verdicts only)
```

Every hop must be reconstructable from the files alone.

---

## 9. What this file does not change

Stage 1 and Stage 2 stay separate. plan-auditor answers what is settled *inside* the
authoritative documents; spec-interrogator finds what is *not settled anywhere*. In
practice each has caught defects the other missed, including Stage 1 finding a
quantitative error in material Stage 2 had been reasoning from. That cross-check only
exists because the roles are distinct. Never merge them.

Zero Stage 2 flags still means "this model may have missed", never "pass".
