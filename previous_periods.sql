-- randomize kpi values
DROP TABLE IF EXISTS barak_mor.kpi_values;
CREATE TABLE barak_mor.kpi_values AS
WITH RECURSIVE randomize (date, kpi) AS (
SELECT '2021-12-01'::DATE AS "date",
       (RANDOM() * 100 + 1)::INT AS kpi
UNION ALL
SELECT DATEADD(day, 1, "date")::DATE AS following_date,
       (RANDOM() * 100 + 1)::INT AS kpi
FROM randomize
WHERE "date" < '2022-07-05'
)
SELECT * FROM randomize;

WITH periods_table AS (
SELECT 1 AS period_id,
         '2022-01-01'::DATE AS from_date,
         '2022-01-05'::DATE AS to_date
UNION ALL
SELECT 2 AS period_id,
         '2022-04-01'::DATE AS from_date,
         '2022-04-03'::DATE AS to_date
UNION ALL
SELECT 3 AS period_id,
         '2022-07-05'::DATE AS from_date,
         '2022-07-24'::DATE AS to_date
)
, vars AS (
SELECT 4 AS past_periods
)
SELECT period_id,
       from_date,
       to_date,
       DATEDIFF('day', from_date, to_date) + 1 AS days_in_period,
       DATEADD('day', -days_in_period * v.past_periods, from_date)::DATE AS previos_periods_start_date,
       DATEADD('day', -1, from_date)::DATE AS previos_period_end_date
FROM periods_table
    CROSS JOIN vars v
;

WITH special_period_kpi AS (
SELECT p.period_id,
       AVG(k.kpi) AS avg_kpi
FROM barak_mor.kpi_values k
    JOIN barak_mor.periods_grouped_by_days p
        ON k."date" BETWEEN p.from_date AND p.to_date
GROUP BY 1
)
, previous_period_kpi AS (
SELECT p.period_id,
       AVG(k.kpi) AS avg_kpi
FROM barak_mor.kpi_values 
    JOIN barak_mor.periods_grouped_by_days p
        ON k."date" BETWEEN p.previos_periods_start_date AND p.previos_period_end_date
GROUP BY 1
)
SELECT s.period_id,
       s.avg_kpi AS special_period_kpi
       p.avg_kpi AS previous_period_kpi
FROM special_period_kpi 
    JOIN previous_period_kpi p
        ON s.period_id = p.period_id
;
