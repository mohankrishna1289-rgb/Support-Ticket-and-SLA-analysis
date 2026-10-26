# Metric definitions

- Total tickets: row count; one unique ticket ID per row in this dataset.
- Unresolved: resolved_at is missing.
- Mean response: average of nonmissing analysis_first_response_min (3,708 records).
- Mean resolution: average of nonmissing analysis_resolution_hours (3,632 records).
- Rated tickets: nonmissing csat; mean CSAT uses these records only.
- CSAT coverage: rated tickets / all tickets.
- Reopened rate: reopened TRUE / nonmissing reopened. All 4,000 values are present here.
- SLA breach rate: breached / (breached + within target); cannot-assess excluded.
- timing_check: Review if response exceeds resolution duration in minutes; Cannot check if either duration missing; otherwise OK.
- id_count: occurrence count of each ticket ID.
- Analysis timing columns: original relevant duration unless Review; missing values remain missing.

Ticket volume, reopening and CSAT measures retain timing-conflict records. Timing exclusions do not prove the original timestamps or response values were corrected.
