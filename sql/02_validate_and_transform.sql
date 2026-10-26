-- Run after importing data/support_tickets_prepared.csv into staging.
SET datestyle TO 'ISO, YMD';
--===================================================================================
SELECT COUNT(*) AS total_tickets
FROM support_tickets_staging;

SELECT
    ticket_id,
    opened_at,
    resolved_at,
    first_response_min,
    reopened,
    csat,
    resolution_hours,
    timing_check,
    analysis_first_response_min,
    analysis_resolution_hours
FROM support_tickets_staging
ORDER BY ticket_id
LIMIT 10;
---------------------------------------------------------------
SELECT
    COUNT(*) AS total_tickets,
    COUNT(DISTINCT ticket_id) AS unique_ticket_ids,
    COUNT(NULLIF(TRIM(first_response_min), '')) AS response_values,
    COUNT(NULLIF(TRIM(resolved_at), '')) AS resolution_values,
    COUNT(NULLIF(TRIM(csat), '')) AS csat_values,
    COUNT(*) FILTER (
        WHERE TRIM(timing_check) = 'Review'
    ) AS timing_conflicts,
    COUNT(NULLIF(TRIM(analysis_first_response_min), ''))
        AS analysis_response_values,
    COUNT(NULLIF(TRIM(analysis_resolution_hours), ''))
        AS analysis_resolution_values
FROM support_tickets_staging;
---------------------------------------------------------------
CREATE TABLE support_tickets AS
SELECT
    TRIM(ticket_id) AS ticket_id,
    NULLIF(TRIM(opened_at), '')::TIMESTAMP AS opened_at,
    TRIM(channel) AS channel,
    TRIM(queue) AS queue,
    TRIM(priority) AS priority,
    subject,
    NULLIF(TRIM(first_response_min), '')::NUMERIC
        AS first_response_min,
    NULLIF(TRIM(resolved_at), '')::TIMESTAMP AS resolved_at,
    NULLIF(TRIM(reopened), '')::BOOLEAN AS reopened,
    NULLIF(TRIM(csat), '')::INTEGER AS csat,
    NULLIF(TRIM(resolution_hours), '')::NUMERIC
        AS resolution_hours,
    TRIM(timing_check) AS timing_check,
    NULLIF(TRIM(id_count), '')::INTEGER AS id_count,
    NULLIF(TRIM(analysis_first_response_min), '')::NUMERIC
        AS analysis_first_response_min,
    NULLIF(TRIM(analysis_resolution_hours), '')::NUMERIC
        AS analysis_resolution_hours
FROM support_tickets_staging;
---------------------------------------------------------------
SELECT
    COUNT(*) AS total_tickets,
    MIN(opened_at) AS earliest_opened,
    MAX(opened_at) AS latest_opened,
    COUNT(*) FILTER (
        WHERE resolved_at < opened_at
    ) AS invalid_date_order,
    COUNT(*) FILTER (
        WHERE ABS(
            resolution_hours
            - EXTRACT(EPOCH FROM (resolved_at - opened_at)) / 3600
        ) > 0.006
    ) AS resolution_mismatches
FROM support_tickets;
--===================================================================================
