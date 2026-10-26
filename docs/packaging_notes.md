# Review notes

## Corrections in this package

- Uploaded support_tickets_prepared.csv contained only 10 original columns. Replaced the packaged CSV with all 15 columns exported from the supplied Excel support-tickets sheet. Original uploaded files were not overwritten.
- Preserved datetime seconds and numeric precision in the new CSV rather than exporting Excel's display formatting.
- Added the missing semicolon after SQL question 7 and separated setup, transformation and analysis so CSV import occurs at the correct point.
- Kept the original Excel, Word and PBIX files unchanged. Excel Cleaning_Notes B5 contains a merged wording typo ('do notPreserved'); the intended rule is clearly stated in the README and metric definitions.
- Included a Markdown version of the Word findings for convenient GitHub reading.

## Validation performed

Independently recalculated row uniqueness, missingness, elapsed resolution duration, timing exclusions, overall means, CSAT, reopening counts and assumed SLA breach counts from the Excel data. Results match the reported overall project metrics. No cached Excel error cells found. Packaged CSV includes 4,000 rows and 15 columns.

## Checks still requiring the author's applications

- PostgreSQL was not available here, so the SQL has not been executed against a PostgreSQL server during packaging.
- PBIX archive includes DataModel and two report pages: Support Overview and SLA & Quality. Desktop refresh and embedded model calculations were not executed here.
- Replace the supplied report-build screenshots with fresh exports after final formatting if desired; existing preview images are explicitly labelled as earlier screenshots in the README.
- Verify source redistribution terms before making the dataset public.

No GitHub repository was created or modified during packaging.
