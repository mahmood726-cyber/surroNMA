# E156 Protocol — `surroNMA`

This repository is the source code and dashboard backing an E156 micro-paper on the [E156 Student Board](https://mahmood726-cyber.github.io/e156/students.html).

---

## `[331]` SurroNMA: Surrogate-Validated Network Meta-Analysis for Oncology and Cardiology

**Type:** methods  |  ESTIMAND: Surrogate-calibrated treatment ranking  
**Data:** Multi-endpoint NMA datasets with surrogate and final outcome data

### 156-word body

Can surrogate endpoint validation be embedded within network meta-analysis to produce treatment rankings adjusted for differential surrogate validity across therapeutic comparisons? We developed SurroNMA implementing trial-level surrogate validation using Daniels and Hughes bivariate meta-analysis, surrogate threshold effect estimation, and network-level ranking adjustment based on validated versus unvalidated evidence contributions. The tool assesses surrogate validity for each comparison in the network and adjusts treatment rankings by down-weighting comparisons relying on inadequately validated surrogates. In oncology test networks the surrogate-adjusted ranking changed the top-ranked treatment in 2 of 5 scenarios compared with unadjusted NMA, with the largest ranking shifts occurring where progression-free survival was used as a surrogate for overall survival without adequate validation. Surrogate calibration reduced ranking uncertainty as measured by SUCRA confidence interval width by a mean of 12 percentage points across validated comparisons. Surrogate-validated NMA could improve the reliability of treatment rankings in therapeutic areas where regulatory approvals increasingly rely on surrogate endpoints. The approach requires per-comparison surrogate validation data that may not be available for all network edges.

### Submission metadata

```
Corresponding author: Mahmood Ahmad <mahmood.ahmad2@nhs.net>
ORCID: 0000-0001-9107-3704
Affiliation: Tahir Heart Institute, Rabwah, Pakistan

Links:
  Code:      https://github.com/mahmood726-cyber/surroNMA
  Protocol:  https://github.com/mahmood726-cyber/surroNMA/blob/main/E156-PROTOCOL.md
  Dashboard: https://mahmood726-cyber.github.io/surronma/

References (topic pack: diagnostic meta-analysis (DTA)):
  1. Reitsma JB et al. 2005. Bivariate analysis of sensitivity and specificity produces informative summary measures in diagnostic reviews. J Clin Epidemiol. 58(10):982-990. doi:10.1016/j.jclinepi.2005.02.022
  2. Rutter CM, Gatsonis CA. 2001. A hierarchical regression approach to meta-analysis of diagnostic test accuracy evaluations. Stat Med. 20(19):2865-2884. doi:10.1002/sim.942

Data availability: No patient-level data used. Analysis derived exclusively
  from publicly available aggregate records. All source identifiers are in
  the protocol document linked above.

Ethics: Not required. Study uses only publicly available aggregate data; no
  human participants; no patient-identifiable information; no individual-
  participant data. No institutional review board approval sought or required
  under standard research-ethics guidelines for secondary methodological
  research on published literature.

Funding: None.

Competing interests: MA serves on the editorial board of Synthēsis (the
  target journal); MA had no role in editorial decisions on this
  manuscript, which was handled by an independent editor of the journal.

Author contributions (CRediT):
  [STUDENT REWRITER, first author] — Writing – original draft, Writing –
    review & editing, Validation.
  [SUPERVISING FACULTY, last/senior author] — Supervision, Validation,
    Writing – review & editing.
  Mahmood Ahmad (middle author, NOT first or last) — Conceptualization,
    Methodology, Software, Data curation, Formal analysis, Resources.

AI disclosure: Computational tooling (including AI-assisted coding via
  Claude Code [Anthropic]) was used to develop analysis scripts and assist
  with data extraction. The final manuscript was human-written, reviewed,
  and approved by the author; the submitted text is not AI-generated. All
  quantitative claims were verified against source data; cross-validation
  was performed where applicable. The author retains full responsibility for
  the final content.

Preprint: Not preprinted.

Reporting checklist: PRISMA 2020 (methods-paper variant — reports on review corpus).

Target journal: ◆ Synthēsis (https://www.synthesis-medicine.org/index.php/journal)
  Section: Methods Note — submit the 156-word E156 body verbatim as the main text.
  The journal caps main text at ≤400 words; E156's 156-word, 7-sentence
  contract sits well inside that ceiling. Do NOT pad to 400 — the
  micro-paper length is the point of the format.

Manuscript license: CC-BY-4.0.
Code license: MIT.

SUBMITTED: [ ]
```


---

_Auto-generated from the workbook by `C:/E156/scripts/create_missing_protocols.py`. If something is wrong, edit `rewrite-workbook.txt` and re-run the script — it will overwrite this file via the GitHub API._