# AGENTS

The standing brief for anyone, human or otherwise, changing this repository.

Read `README.md` for the shape of it, then `VERIFICATION.md` for which gate
discharges what.

## The rules

Every violation `mp-gate` reports names the rule it breaks, so a red gate says
*which promise* failed rather than merely that something is wrong. Nothing else
in the repository defines an `R`-number.

| Rule | What it says | Enforced by |
| --- | --- | --- |
| R1 | No source string literal holds a numeric claim that should be computed. | `mp-gate` |
| R2 | A lemma is cited by its statement, not by a line number that drifts. | `mp-gate` |
| R3 | Every generated artifact names the commit that produced it. | `mp-gate` |
| R4 | A bound is either proven or labelled a conjecture; never both. | `mp-gate` |
| R5 | The oracle data is read-only and hashed. | `mp-gate` |

## What you may change

Source, tests, the model, the oracles (only to correct a transcription error,
which must be recorded in `model/ledger.toml`). You may not change a gate to
make a red run green.
