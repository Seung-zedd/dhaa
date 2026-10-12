# Decision layer for the SPEC-review class gate — a negative result

Status: experiment closed after two tooling SPECs (SPEC-DEC-001, SPEC-DEC-002) in a private product
repository. Outcome: the interruption-reduction criterion was **not met** in either SPEC; the
no-unauthorized-decision condition **held** in both. The layer stays an offline evaluation tool and
is not wired into the review pipeline.

Related: `docs/wiki/spec-interrogator-evidence-first.md`, proposed in PR #6 and not yet merged
(the evidence-first class gate this experiment tried to automate).

This note records methodology and qualitative outcome only. It carries no performance figures for
the external provider or for the evaluation (see *What this note omits*).

---

## 1. Background

The SPEC-review pipeline raises flags on a SPEC document set. The class gate described in
`docs/wiki/spec-interrogator-evidence-first.md` then routes each flag to whoever already has
authority over it, so that the founder is interrupted only for product decisions no document and no
evidence can settle. In the product repository the gate uses seven classes; they map onto the
evidence-first vocabulary without renaming:

| Evidence-first note | Class used here | Founder action |
|---|---|---|
| AUTO-RESOLVE | `EVIDENCE-RESOLVED` | none unless override |
| PRD-RESOLVE | `POLICY-COVERED` (and `DECIDED` for a prior verdict) | none unless override |
| ENGINEERING-RESOLVE | `ENGINEERING-RESOLVED` | none unless override |
| VERIFY-MORE | `EVIDENCE-NEEDED` | request evidence / defer |
| CONFLICT | `IMPLEMENTATION-GAP` | none, until changing the requirement is proposed |
| FOUNDER-DECISION | `FOUNDER` | decide |

Naming hazard: the evidence-first note's "AUTO-RESOLVE" is one class. In this layer, `AUTO` is a
**route**, reachable by four classes (`DECIDED`, `POLICY-COVERED`, `EVIDENCE-RESOLVED`,
`ENGINEERING-RESOLVED`). The two words should not be read as the same thing.

Before this experiment the gate was executed by the orchestrator LLM by hand, with only a post-hoc
lint checking the artifacts it left behind. There was no mechanical step between a flag and its
route, which is exactly where an AI can make a product decision without anyone noticing.

**The question.** Can an external judgment provider plus a deterministic guardrail reduce founder
interruptions, without producing any unauthorized decision (a flag whose correct class is `FOUNDER`
routed past the founder)?

The provider was Jev (TypeSafe AI, `@typesafe-ai/sdk`), a typed-judgment API that answers
`choice` / `score` / `noul` questions with a selected label and a probability distribution, without free-text
generation.

---

## 2. Design

### 2.1 Three layers, separately typed

```
DecisionInput  = flag prose (state) + cited facts (authorityContext) + evidence refs
      |
[1] Candidate FSM       deterministic   "possible"   -> set of classes this flag can take
      |
[2] DecisionProvider    pluggable       "probable"   -> one class from that set, plus confidence
      |
[3] AuthorityGuardrail  deterministic   "permitted"  -> route AUTO | VERIFY | FOUNDER
      |
[4] existing workflow   AUTO proposes a resolved-table row; VERIFY returns to the manual gate;
                        FOUNDER enters the interview queue
```

The one invariant: **confidence is never a permission input.** It is logged for later calibration
and nothing else.

### 2.2 Candidate FSM

- Reads only `authorityContext` and `evidence`. It never reads the flag's prose and never reads
  provider output. The function signature takes those two arguments, not the whole input, so this
  holds by construction.
- Every rule is an **exclusion** over the same seven-class universe, so rule order cannot change
  the result. No rule excludes `FOUNDER`, so the set is never empty and the route mapping is total.
- Each item on the never-auto-downgrade list (new user-visible behaviour, persistence contract,
  brand, visual taste, privacy promise, unknown trade-offs, and so on) is a key whose value is
  `true | false | 'unknown'`. Any key that is not `false` bounds the set to
  `{FOUNDER, EVIDENCE-NEEDED}`.
- Every cited field must carry a `sources` entry (`path#line`). **A field with no entry is read as
  `'unknown'`, whatever value sits beside it.** The ordering is `false < 'unknown' <= true`: unknown
  is the worst case, not a neutral default.

### 2.3 DecisionProvider

- The provider's choice criteria are built **only from the FSM's candidate set**. A class the FSM
  removed is not rejected after the fact; it is never offered. A label outside the set is refused.
- A flag whose candidate set is `{FOUNDER}` alone is never sent.
- Every failure mode (timeout, rate limit, schema mismatch, connection error) returns a
  `ProviderUnavailable` value. The adapter never throws; the guardrail routes it `VERIFY` (or
  `FOUNDER` for a founder-only set) with `authoritySource: 'fallback:deterministic'`.
- The default provider is `none`, which always returns unavailable and loads no network code. Under
  it the whole package is a deterministic lint of the gate.
- A flag whose body may quote end-user content (a cited trilean; `true` or `'unknown'`) is never
  sent. No request is built.

### 2.4 AuthorityGuardrail

The guardrail is the only component that produces a route. Its judgment parameter is narrowed at the
type level, so confidence is unreadable rather than merely unused:

```ts
interface AuthorityGuardrail {
  decide(
    input: DecisionInput,
    judgment: Pick<JevJudgment, 'candidate'> | ProviderUnavailable
  ): AuthorityDecision;   // { route, resolvedClass?, reason[], ruleIds[], authoritySource }
}
```

- The rule table is **injected**. Each rule carries an id that is a match key back into the
  authority document, the section it was transcribed from, the classes it gates, and a predicate
  over a degraded read-only view. The engine imports nothing domain-specific.
- `authoritySource` pins the git blob sha of the authority document; a test re-hashes the file.
- `EVIDENCE-NEEDED` and `IMPLEMENTATION-GAP` always route `VERIFY`. `FOUNDER` always routes
  `FOUNDER`. `AUTO` requires the selected class to be in the candidate set and every rule gating it
  to hold.
- `AUTO` means one thing: propose a resolved-table row, without prose. The layer never edits the
  decision index, a SPEC, the PRD or code. A tool that both decides and records has no gate between
  the two.

### 2.5 Log

Two JSONL lines per flag, always: a judgment record and an authority record. The authority record
has no `confidence` key at any depth. When no judgment was made, the judgment slot still carries an
`unavailable` record, so "no judgment" and "missing line" stay distinguishable. A confidence
threshold's effect is computed and logged ("would have escalated") and never applied.

### 2.6 Reusability of the parts

| Part | Scope |
|---|---|
| `src/core/contracts.ts`, `src/core/candidates.ts`, `src/core/guardrail.ts` | domain- and provider-agnostic |
| `src/providers/none.ts` (null provider, fan-out, provider registry) | provider-agnostic |
| `src/pillwriter/rules.ts` (transcribed rule table), flag loader | domain-specific |
| `src/providers/jev.ts` (SDK adapter: timeout, retry budget, abort, schema check) | provider-specific |

---

## 3. Method

- **Replay, not live use.** The evaluation replayed the review flags of one completed SPEC through
  the layer, reproducing the **initial triage**: the state of each flag before any analysis existed.
- **Gold label** is the founder-confirmed class after re-triage. The initial-triage class is carried
  on each row only to count the direction of re-triage.
- **Two context sets**, reported separately and never summed: a hand-filled set (cited facts filled
  by hand from the decision index's summary columns) and a parser-filled set.
- **Criterion (1), interruption reduction.** Measured over two target flags: flags that were
  `FOUNDER` at initial triage and were later resolved without a founder decision. Only an `AUTO`
  route counts; `VERIFY` is not a reduction. Normalised by the fallback rate, so a run where the
  provider was mostly unavailable cannot read as a result.
- **Unauthorized-decision condition.** A gold-`FOUNDER` row routed `AUTO`. Non-zero on either set
  fails the experiment. Each such row would carry an attribution: `rule` (a transcribed rule
  permitted it) or `fill` (the cited facts were filled wrongly).
- **Contamination controls.** Answer files, analysis files, and the resolved-items table of the
  index are forbidden inputs; a read audit **throws** on a forbidden path. The authority document is
  byte-identical for the whole run, checked by hash.
- **Predictions before the run.** Structural predictions (which rows become reachable, which keys
  move) were written before the first null-provider computation and quoted verbatim in the report.
  Reachability and route were predicted separately, on different bases.
- **Cost discipline.** Tests use recorded fixtures only; no test calls the live API. Each paid pass
  needed an explicit founder authorization.
- The design's other success criteria (class accuracy against a baseline, orchestrator token
  saving, disagreement exposing a defect) were reported as report-only rows. The founder's verdicts
  turned on criterion (1) and the unauthorized-decision condition.

---

## 4. Result

### SPEC-DEC-001 — build and first measurement

Built the three layers, the null provider, the log, a CLI that proposes rows on stdout, and the
replay harness under TDD. Founder verdict: **partial success.** The unauthorized-decision condition
held on both sets. Criterion (1) was not met. The recorded cause: the admissible fill sources named
no engineering convention, and `ENGINEERING-RESOLVED` requires a cited convention, so that class was
unreachable on every row. Widening the fill sources was deferred to a follow-up SPEC rather than
repaired in place, because widening what an evaluation may read is exactly what a source
restriction exists to gate.

### SPEC-DEC-002 — widened fill sources, re-measurement

Four changes, then one authorised paid pass:

1. **A degradation defect.** The convention field was the one cited field that bypassed the
   "uncited is unknown" pass, so an uncited convention string satisfied the gate. A doc comment
   stated the undegraded behaviour as intended, which is how it survived a review. Fixed
   reproduction-first.
2. **Axis A.** Convention citations admitted from an enumerated list (flag body, ADRs, glossary).
   Committed code was ruled evidence, not convention; the authority document was ruled not
   admissible as its own convention source.
3. **Axis B.** Per-key citations for the never-auto-downgrade keys on the parser-filled set, from
   the flag body alone.
4. **Axis C.** The hand-filled keys were re-derived under the predicate "does the settled answer
   change the *meaning* of this item", replacing a topical mapping from an index column. Planning
   found this necessary: both target flags carried a key set by that topical mapping, which bounded
   their candidate set before the convention gate was ever reached. The re-derivation was done twice
   — by the orchestrator, who knew the targets, and by a blind subagent, who did not — and any key
   on which the two disagreed became `'unknown'`.

Outcome, by founder verdict: **criterion (1) not met; the pre-declared "real reduction" threshold
not reached.** The unauthorized-decision condition held. The layer stays offline.

---

## 5. Why criterion (1) did not move

**5.1 The replay reproduces initial triage; the resolving material came later.** Both target flags
were resolved by material that did not exist at initial triage: a real-data analysis, and founder
answers from an interview round. That material lies outside the admissible fill sources by design,
because admitting it would let the answer key reach the evaluation input. Criterion (1) therefore
asked the layer to anticipate, at triage time, something that became knowable only after analysis.
The design deferred post-analysis re-triage to a later SPEC, which is where this material would be
legitimately readable.

**5.2 The safety bound and the target pull against each other, and the bound wins.** Any
never-auto-downgrade key that is not `false` bounds a flag to `{FOUNDER, EVIDENCE-NEEDED}`. Uncited
fields read as `'unknown'`, and disagreeing derivations read as `'unknown'`. Every conservative
choice in the filling procedure is, correctly, a reason for the FSM to keep the founder in the loop.
On the re-filled input no row of either set was `AUTO`-reachable.

**5.3 The provider cannot move a route the FSM has closed.** Because the provider chooses only among
FSM candidates, its contribution is bounded by the candidate set. In the second SPEC's paid pass,
every row's set was `{FOUNDER, EVIDENCE-NEEDED}` or smaller, so the provider was never *offered* an
`AUTO`-capable class. That pass carries no information about the provider's judgment on the `AUTO`
side. This was first written up as "the provider did not choose an `AUTO`-capable class" and later
corrected to "was not offered one" — the two sentences look alike and mean different things.

**5.4 Reachability is not a route.** In the first SPEC, some rows were `AUTO`-reachable, and no
`AUTO` route resulted from them. With so few observations, provider behaviour and input quality
cannot be separated there.

**5.5 The safety result is vacuous in the second pass.** "No gold-`FOUNDER` row routed `AUTO`" was
observed in a pass with no `AUTO` proposal at all. The condition held; it was not tested against a
proposal it had to block.

**5.6 "Structurally unreachable" is not proven.** One target flag was blocked by a single key, and
that key was one on which the two independent derivations disagreed. Had the blind derivation agreed
with the knowing one, that flag would have been reachable. The other target flag was blocked by
several keys and by the convention gate. Two target flags and one pass are too few to call the
outcome structural in general; what is structural is the mechanism in 5.1–5.3.

**5.7 The first diagnosis named the wrong gate.** The first SPEC attributed the result to the
convention gate. The second SPEC's planning found an earlier bound on the same rows, and its
measurement found the binding key had changed again. Per-row `ruleIds[]`, which list every rule
that blocked a route, are what made each correction possible.

---

## 6. What would have to be true for criterion (1) to be reachable

Stated as conditions, not as advice.

- **Post-triage evidence is admissible.** The measurement moves from initial triage to re-triage
  after analysis, with real-data analyses as admissible fill sources and the answer files still
  forbidden. This changes the question from "can the layer spare the founder at first sight" to
  "can the layer spare the founder once evidence exists".
- **The target flags' candidate sets can contain an `AUTO`-capable class.** Every
  never-auto-downgrade key on those flags must resolve to `false`, each with a citation from an
  admissible source that existed at the time being replayed.
- **A convention source exists at triage time.** `ENGINEERING-RESOLVED` needs a cited convention;
  an ADR or glossary entry written after the flags does not describe the triage-time state (and may
  carry answers to other flags).
- **The target set is larger than two, and passes are repeated**, so that provider behaviour and
  input quality can be separated and one disagreed key cannot decide the outcome.
- **The safety condition is exercised non-vacuously**: rows where an `AUTO`-capable class is
  offered and the gold class is `FOUNDER`, so that "no unauthorized decision" is observed against
  real proposals.

---

## 7. Reusable lessons

1. **Separate "probable" from "permitted" in the type system.** Narrow the guardrail's parameter to
   the one field it may read. An invariant held by discipline is one refactor from gone.
2. **Make forbidden options unofferable.** Building the provider's choice set from a deterministic
   candidate set is stronger than rejecting its output afterwards, and it makes the provider
   replaceable without touching authority.
3. **Uncited means unknown, and unknown is the worst case.** Apply the degradation in one shared pass
   read by every consumer. The only defect of this kind found here was a field that skipped the
   shared pass.
4. **Ship a null provider as the default.** The same code path then serves as the failure fallback
   and as a deterministic lint, and a pre-flight under it shows structural zeros before any paid
   call.
5. **Check whether the dangerous option was ever offered.** A safety criterion that held with zero
   proposals is untested. Report the number of opportunities beside the pass.
6. **Check when the resolving evidence came into existence.** If the target cases were resolved by
   evidence created after the replayed moment, a replay of that moment cannot credit the tool, and a
   null-provider pre-flight can reveal this before a run is paid for.
7. **Record provenance dates of admissible sources.** Sources read at HEAD can postdate the flags
   and carry answers to them; the second SPEC corrected several such dates during review.
8. **Contamination guards have a price.** A blind second derivation with disagreement-to-unknown is
   sound, and it can itself become the binding constraint.
9. **Write predictions and thresholds before reading results**, and keep reachability and route as
   two statements. The "real reduction" threshold was fixed before the report was read, which kept
   it from moving to fit the result.
10. **Keep the tool offline until the pre-declared threshold is met.** Here it was not, and the
    manual gate continues unchanged.

---

## What this note omits

- **Performance figures** for the provider and the evaluation: no accuracy, agreement,
  disagreement or escalation rates, no counts, no cost, token, latency or confidence values, and no
  example provider responses. Whether the provider's customer agreement restricts publishing
  performance figures has not been checked (an open item in SPEC-DEC-001).
- **Product content** of the private repository: flag texts, requirements, verdict wording and gold
  labels.
- **A recommendation** to adopt or abandon the provider. Section 6 states conditions only.
