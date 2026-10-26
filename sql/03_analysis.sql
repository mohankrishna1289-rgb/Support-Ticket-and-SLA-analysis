-- Run after 02_validate_and_transform.sql. Assumed SLA thresholds, elapsed time.
--1)What is the overall ticket volume, response speed, resolution speed, 
--  and satisfaction?

SELECT
    COUNT(*) AS total_tickets,
    COUNT(*) FILTER (
        WHERE resolved_at IS NULL
    ) AS unresolved_tickets,
    ROUND(AVG(analysis_first_response_min), 2)
        AS avg_first_response_minutes,
    ROUND(AVG(analysis_resolution_hours), 2)
        AS avg_resolution_hours,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE reopened IS TRUE)
        / NULLIF(COUNT(reopened), 0), 2
    ) AS reopened_pct,
    ROUND(AVG(csat), 2) AS avg_csat_score,
    COUNT(csat) AS rated_tickets,
    ROUND(
        100.0 * COUNT(csat) / NULLIF(COUNT(*), 0), 2
    ) AS csat_coverage_pct
FROM support_tickets;

--2)How does ticket volume change each month?

SELECT
    DATE_TRUNC('month', opened_at)::DATE AS month,
    COUNT(*) AS total_tickets
FROM support_tickets
GROUP BY DATE_TRUNC('month', opened_at)::DATE
ORDER BY month;

--3)Which support queues receive the most tickets?

SELECT
    queue,
    COUNT(*) AS total_tickets,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM support_tickets),
        2
    ) AS ticket_share_pct
FROM support_tickets
GROUP BY queue
ORDER BY total_tickets DESC;

--4)Which channels—chat,email,phone,or in-app—bring in the most support tickets?

select channel,
       COUNT(*) AS total_tickets,
       ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM support_tickets),
        2
        ) AS ticket_share_pct
from support_tickets		
group by channel
order by total_tickets desc;

--5)Which queues have the longest average response and resolution times?

select queue,
       COUNT(*) AS total_tickets,
	   COUNT(analysis_first_response_min) as response_sample_size,
	   round(avg(analysis_first_response_min), 2) as avg_response_minutes,
	   COUNT(analysis_resolution_hours) as resolution_sample_size,
	   round(avg(analysis_resolution_hours), 2) as avg_resolution_hours
from support_tickets	   
group by queue	   
order by avg_resolution_hours desc;

--6)Are urgent tickets receiving faster support?
	   
select priority,
       COUNT(*) AS total_tickets,
	   COUNT(analysis_first_response_min) as response_sample_size,
	   round(avg(analysis_first_response_min), 2) as avg_response_minutes,
	   COUNT(analysis_resolution_hours) as resolution_sample_size,
	   round(avg(analysis_resolution_hours), 2) as avg_resolution_hours
from support_tickets	   
group by priority   
order by avg_response_minutes asc;

--7)first-response SLA analysis.

select ticket_id,
       priority,
	   analysis_first_response_min,
       CASE 
           WHEN priority = 'urgent' then 30
           WHEN priority = 'high'   then 60
           WHEN priority = 'normal' then 240
           WHEN priority = 'low'    then 480
		END AS response_target_minutes
from support_tickets;


--8)

with response_targets as(
select ticket_id,
       priority,
	   analysis_first_response_min,
       CASE 
           WHEN priority = 'urgent' then 30
           WHEN priority = 'high'   then 60
           WHEN priority = 'normal' then 240
           WHEN priority = 'low'    then 480
		END AS response_target_minutes
from support_tickets
) 
select ticket_id,
       priority,
	   analysis_first_response_min,
	   response_target_minutes,
CASE 
    WHEN analysis_first_response_min IS NULL OR response_target_minutes IS NULL then 'Cannot assess'
	WHEN analysis_first_response_min >response_target_minutes then 'Breached'
	else 'Within target'
	end as response_sla_status	
from response_targets
order by ticket_id
limit 10;

--9)Across all 4,000 tickets, how many fall into each status under our assumed targets?

with response_targets as(
select ticket_id,
       priority,
	   analysis_first_response_min,
       CASE 
           WHEN priority = 'urgent' then 30
           WHEN priority = 'high'   then 60
           WHEN priority = 'normal' then 240
           WHEN priority = 'low'    then 480
		END AS response_target_minutes
from support_tickets
),
response_status as (
select ticket_id,
       priority,
	   analysis_first_response_min,
	   response_target_minutes,
CASE 
    WHEN analysis_first_response_min IS NULL OR response_target_minutes IS NULL then 'Cannot assess'
	WHEN analysis_first_response_min >response_target_minutes then 'Breached'
	else 'Within target'
	end as response_sla_status	
from response_targets
)
select response_sla_status,
       count(*) as total_tickets
from response_status	   
group by response_sla_status
;

--10)What percentage of assessable tickets breached our assumed response targets?


with response_targets as(
select ticket_id,
       priority,
	   analysis_first_response_min,
       CASE 
           WHEN priority = 'urgent' then 30
           WHEN priority = 'high'   then 60
           WHEN priority = 'normal' then 240
           WHEN priority = 'low'    then 480
		END AS response_target_minutes
from support_tickets
),
response_status as (
select ticket_id,
       priority,
	   analysis_first_response_min,
	   response_target_minutes,
CASE 
    WHEN analysis_first_response_min IS NULL OR response_target_minutes IS NULL then 'Cannot assess'
	WHEN analysis_first_response_min >response_target_minutes then 'Breached'
	else 'Within target'
	end as response_sla_status	
from response_targets
)
SELECT
    COUNT(CASE WHEN response_sla_status = 'Breached'
               THEN 1 END) AS breached_tickets,
    COUNT(CASE WHEN response_sla_status <> 'Cannot assess'
               THEN 1 END) AS assessable_tickets,
    ROUND(100.0 *
        COUNT(CASE WHEN response_sla_status = 'Breached' THEN 1 END)
                    /
        NULLIF(COUNT(CASE WHEN response_sla_status <> 'Cannot assess'
                       THEN 1 END), 0), 2
    ) AS response_breach_pct
FROM response_status;

--11)Which priority has the highest response breach rate? This shows where the overall 
--   percentage hides differences.

with response_targets as(
select ticket_id,
       priority,
	   analysis_first_response_min,
       CASE 
           WHEN priority = 'urgent' then 30
           WHEN priority = 'high'   then 60
           WHEN priority = 'normal' then 240
           WHEN priority = 'low'    then 480
		END AS response_target_minutes
from support_tickets
),
response_status as (
select ticket_id,
       priority,
	   analysis_first_response_min,
	   response_target_minutes,
CASE 
    WHEN analysis_first_response_min IS NULL OR response_target_minutes IS NULL then 'Cannot assess'
	WHEN analysis_first_response_min > response_target_minutes then 'Breached'
	else 'Within target'
	end as response_sla_status	
from response_targets
)
SELECT priority,
       COUNT(CASE WHEN response_sla_status = 'Breached'
               THEN 1 END) AS breached_tickets,
       COUNT(CASE WHEN response_sla_status <> 'Cannot assess'
               THEN 1 END) AS assessable_tickets,
       ROUND(100.0 *
          COUNT(CASE WHEN response_sla_status = 'Breached' THEN 1 END)
                    /
        NULLIF(COUNT(CASE WHEN response_sla_status <> 'Cannot assess'
                       THEN 1 END), 0), 2
    ) AS response_breach_pct
FROM response_status
group by priority
order by response_breach_pct desc;

--12)Which priority has the highest resolution breach percentage?

with resolution_targets as(
select ticket_id,
       priority,
	   analysis_resolution_hours,
       CASE 
           WHEN priority = 'urgent' then 24
           WHEN priority = 'high'   then 48
           WHEN priority = 'normal' then 72
           WHEN priority = 'low'    then 120
		END AS resolution_target_hours
from support_tickets
),
resolution_status as (
select ticket_id,
       priority,
	   analysis_resolution_hours,
	  resolution_target_hours,
CASE 
    WHEN analysis_resolution_hours IS NULL OR resolution_target_hours IS NULL then 'Cannot assess'
	WHEN analysis_resolution_hours > resolution_target_hours then 'Breached'
	else 'Within target'
	end as resolution_sla_status	
from resolution_targets
)
SELECT priority,
       COUNT(CASE WHEN resolution_sla_status = 'Breached'
               THEN 1 END) AS breached_tickets,
       COUNT(CASE WHEN resolution_sla_status <> 'Cannot assess'
               THEN 1 END) AS assessable_tickets,
       ROUND(100.0 *
          COUNT(CASE WHEN resolution_sla_status = 'Breached' THEN 1 END)
                    /
       NULLIF(COUNT(CASE WHEN resolution_sla_status <> 'Cannot assess'
                       THEN 1 END), 0), 2
    ) AS resolution_breach_pct
FROM resolution_status
group by priority
order by resolution_breach_pct desc;

--13)Which queue has the highest reopened-ticket percentage?

SELECT queue,
       COUNT(*) AS total_tickets,
       COUNT(CASE WHEN reopened = TRUE THEN 1 END) AS reopened_count,
       ROUND(
           100.0 * COUNT(CASE WHEN reopened = TRUE THEN 1 END)
           / NULLIF(COUNT(reopened), 0),
           2
       ) AS reopened_pct
FROM support_tickets
GROUP BY queue
ORDER BY reopened_pct DESC;

--14)Which queue has the lowest average customer satisfaction, and how much feedback 
--   supports that average?

select queue,
       count(*)as total_tickets,
	   count(csat) as Rated_tickets,
	   ROUND(AVG(CSAT),2) Average_csat,
	   ROUND(100.00 *  count(csat) / NULLIF (count(*),0),
	   2
	   ) AS csat_coverage_pct
from support_tickets
group by queue
order by Average_csat asc;
	   
--15)Do tickets that breached our assumed response targets have lower average CSAT?

with response_targets as (
select csat,
       ticket_id,
       priority,
	   analysis_first_response_min,
       CASE 
           WHEN priority = 'urgent' then 30
           WHEN priority = 'high'   then 60
           WHEN priority = 'normal' then 240
           WHEN priority = 'low'    then 480
	   END AS response_target_minutes
from support_tickets
),
response_status as (
select ticket_id,
       csat,
       priority,
	   analysis_first_response_min,
	   response_target_minutes,
CASE 
    WHEN analysis_first_response_min IS NULL OR response_target_minutes IS NULL then 'Cannot assess'
	WHEN analysis_first_response_min > response_target_minutes then 'Breached'
	else 'Within target'
	end as response_sla_status	
from response_targets
)
select response_sla_status,
       count(*)as total_tickets,
	   count(csat) as Rated_tickets,
	   ROUND(AVG(CSAT),2) Average_csat,
	   ROUND(100.00 *  count(csat) / NULLIF (count(*), 0),
	   2
	   ) AS csat_coverage_pct
from response_status	   
group by response_sla_status
order by average_csat asc;

--16)the final planned SQL question: Which queue–priority groups have the most 
--   unresolved tickets?

select queue,
       priority,
	   count(*) as unresolved_tickets
from support_tickets
where resolved_at IS NULL
GROUP BY QUEUE, priority
order by unresolved_tickets desc;







