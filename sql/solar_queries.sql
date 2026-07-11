-------------------------------------------------
-- Project 1: Solar Farm Performance Analysis
-- SQL Query Bank
-- Author: Muhammad Imran
-- Date: 07/05/2026
-- Dataset: Kaggle Solar Power Generation Data
-- Plant: Plant 1 | 22 Inverters | 30.46 MW
-- Period: 15 May 2020 to 17 June 2020
----------------------------------------------------------------------------- 
-----------------------------------------------------------------------------

-- Q01: Total energy generated per day across all 22 inverters
-- Business question: How much did the plant generate each day?
-- Concept: GROUP BY + SUM + unit conversion (kW × 0.25hr = kWh)
-- Note: AC_POWER is in kW, and readings forevery 15 minutes (i.e 0.25 hours)

SELECT 
    date,
    ROUND(SUM(AC_POWER) * 0.25, 2)         AS total_kwh,
    ROUND(SUM(AC_POWER) * 0.25 / 1000, 3)  AS total_mwh
FROM solar_generation
GROUP BY date
ORDER BY date;
----------------------------------------------------------------------------
----------------------------------------------------------------------------



-- Q02: The 5 worst performing days
-- Business question: Which specific days underperformed and by how much?
-- Concept: ORDER BY ASC + LIMIT to surface the bottom performers

SELECT 
    date,
    ROUND(SUM(AC_POWER) * 0.25, 2)        AS daily_kwh,
    ROUND(SUM(AC_POWER) * 0.25 / 1000, 3) AS daily_mwh
FROM solar_generation
GROUP BY date
ORDER BY daily_kwh ASC
LIMIT 5;

-- This returns the 5 lowest-generation days.
----------------------------------------------------------------------------
----------------------------------------------------------------------------



-- Q03: The 5 best performing days
-- Business question: What does good performance look like for this plant?
-- Concept: ORDER BY DESC + LIMIT
-- Purpose: Establishes the performance ceiling and sets the benchmark

SELECT 
    date,
    ROUND(SUM(AC_POWER) * 0.25, 2)        AS daily_kwh,
    ROUND(SUM(AC_POWER) * 0.25 / 1000, 3) AS daily_mwh
FROM solar_generation
GROUP BY date
ORDER BY daily_kwh DESC
LIMIT 5;

-- This returns the 5 highest-generation days, which gives a benchmark for the plant's performance.
----------------------------------------------------------------------------
----------------------------------------------------------------------------



-- Q04: Average power output by hour of day across all 22 inverters
-- Business question: When does the plant generate the most power?
-- Concept: GROUP BY hour + AVG
-- This produces the 24-row generation profile (the solar bell curve)

SELECT 
    hour,
    ROUND(AVG(AC_POWER), 2)  AS avg_power_kw,
    ROUND(MAX(AC_POWER), 2)  AS peak_power_kw,
    ROUND(MIN(AC_POWER), 2)  AS min_power_kw
FROM solar_generation
GROUP BY hour
ORDER BY hour;

------------------------------------------------------------------------------
------------------------------------------------------------------------------




-- Q05: Daily capacity factor for the plant
-- Business question: What % of maximum possible generation did we achieve each day?
-- Concept: CTE (COMMON TABLE EXPRESSION, i.e the WITH clause) + formula calculation
-- Installed capacity = 30,460 kW (sum of all 22 inverter peaks)
-- Formula: Actual kWh / (Capacity kW × 24 hours) × 100

WITH daily_totals AS (
    SELECT 
        date,
        SUM(AC_POWER) * 0.25        AS actual_kwh,
        COUNT(DISTINCT hour) * 1.0  AS hours_of_data
    FROM solar_generation
    GROUP BY date
)
SELECT 
    date,
    ROUND(actual_kwh, 1)                              AS actual_kwh,
    ROUND(actual_kwh / (30460.0 * 24) * 100, 2)      AS capacity_factor_pct,
    CASE 
        WHEN actual_kwh / (30460.0 * 24) * 100 >= 20 THEN 'Excellent'
        WHEN actual_kwh / (30460.0 * 24) * 100 >= 15 THEN 'Good'
        WHEN actual_kwh / (30460.0 * 24) * 100 >= 10 THEN 'Below Average'
        ELSE 'Poor'
    END AS rating
FROM daily_totals
ORDER BY date;

------------------------------------------------------------------------------
------------------------------------------------------------------------------




-- Q06: Total generation per inverter across the full 34-day period
-- Business question: Are all 22 inverters contributing equally?
-- Concept: GROUP BY SOURCE_KEY (Inverter ID) + share calculation using subquery
-- An inverter generating significantly less than average needs investigation

WITH total_plant AS (
    SELECT SUM(AC_POWER) * 0.25 AS grand_total_kwh
    FROM solar_generation
),
per_inverter AS (
    SELECT 
        SOURCE_KEY                          AS inverter_id,
        ROUND(SUM(AC_POWER) * 0.25, 1)     AS total_kwh
    FROM solar_generation
    GROUP BY SOURCE_KEY
)
SELECT 
    p.inverter_id,
    p.total_kwh,
    ROUND(p.total_kwh / t.grand_total_kwh * 100, 2)  AS share_pct,
    ROUND(p.total_kwh / 34, 1)                        AS avg_daily_kwh,
    RANK() OVER (ORDER BY p.total_kwh DESC)            AS rank
FROM per_inverter p, total_plant t
ORDER BY p.total_kwh DESC;

------------------------------------------------------------------------------
------------------------------------------------------------------------------




-- Q07: Inverter DC-to-AC conversion efficiency per inverter
-- Business question: How efficiently is each inverter converting DC to AC power?
-- Concept: SUM ratio + NULLIF to prevent division by zero
-- IMPORTANT: DC_POWER has already been converted from W to kW in cleaning
-- Normal efficiency: 94-98%. Below 90% = fault investigation required.

SELECT 
    SOURCE_KEY                                                           AS inverter_id,
    ROUND(SUM(AC_POWER) / NULLIF(SUM(DC_POWER), 0) * 100, 2)           AS efficiency_pct,
    ROUND(SUM(DC_POWER - AC_POWER) * 0.25, 1)                           AS energy_lost_kwh,
    COUNT(CASE WHEN DC_POWER > 0 
               AND AC_POWER / NULLIF(DC_POWER, 0) < 0.90 
               THEN 1 END)                                               AS low_eff_readings
FROM solar_generation
WHERE DC_POWER > 0
GROUP BY SOURCE_KEY
ORDER BY efficiency_pct ASC;

------------------------------------------------------------------------------
------------------------------------------------------------------------------




-- Q08: Hours of zero generation during daylight hours per day
-- Business question: When was the plant not generating when it should have been?
-- Concept: WHERE filter on daytime hours + HAVING to filter meaningful outages
-- Daylight defined as 06:00 to 18:00 for this dataset's location
-- Dividing by 22 inverters gives plant-level downtime, not inverter×hours

SELECT 
    date,
    COUNT(*) * 0.25 / 22.0                     AS plant_downtime_hours,
    COUNT(*)                                    AS zero_reading_count,
    MIN(hour)                                   AS first_zero_hour,
    MAX(hour)                                   AS last_zero_hour
FROM solar_generation
WHERE AC_POWER = 0
  AND hour BETWEEN 6 AND 18
GROUP BY date
HAVING COUNT(*) >= 4
ORDER BY plant_downtime_hours DESC;

------------------------------------------------------------------------------
------------------------------------------------------------------------------




-- Q09: Week-over-week generation change
-- Business question: Is plant performance improving or declining over time?
-- Concept: LAG window function to compare each week to the previous week
-- LAG(value, 1) means "get the value from 1 row behind in this window"

WITH weekly AS (
    SELECT 
        week,
        ROUND(SUM(AC_POWER) * 0.25, 1)  AS weekly_kwh
    FROM solar_generation
    GROUP BY week
    ORDER BY week
)
SELECT 
    week,
    weekly_kwh,
    LAG(weekly_kwh, 1) OVER (ORDER BY week)   AS prev_week_kwh,
    ROUND(
        (weekly_kwh - LAG(weekly_kwh, 1) OVER (ORDER BY week)) 
        / NULLIF(LAG(weekly_kwh, 1) OVER (ORDER BY week), 0) * 100
    , 1)                                       AS wow_change_pct
FROM weekly;

------------------------------------------------------------------------------
------------------------------------------------------------------------------




-- Q10: Average generation on weekdays vs weekends
-- Business question: Does time of week affect plant performance?
-- Concept: CASE WHEN on is_weekend column + comparison grouping
-- Solar output should NOT differ by day of week (sun doesn't take weekends off)
-- If it does differ, it signals a data or operational issue

SELECT 
    CASE WHEN is_weekend = 1 THEN 'Weekend' ELSE 'Weekday' END  AS day_type,
    COUNT(DISTINCT date)                                          AS days_count,
    ROUND(AVG(daily_kwh), 1)                                     AS avg_daily_kwh,
    ROUND(MIN(daily_kwh), 1)                                     AS min_daily_kwh,
    ROUND(MAX(daily_kwh), 1)                                     AS max_daily_kwh
FROM (
    SELECT 
        date,
        is_weekend,
        SUM(AC_POWER) * 0.25  AS daily_kwh
    FROM solar_generation
    GROUP BY date, is_weekend
) daily_summary
GROUP BY day_type;

------------------------------------------------------------------------------
------------------------------------------------------------------------------




-- Q11: Average generation at different irradiation levels
-- Business question: Does output increase proportionally with irradiance?
-- Concept: CASE WHEN to create irradiance ranges + comparison across ranges
-- Uses the solar_merged table which joined generation and weather data

SELECT 
    CASE 
        WHEN IRRADIATION = 0            THEN '0 - No sun'
        WHEN IRRADIATION < 0.2          THEN '0.0-0.2 - Low'
        WHEN IRRADIATION < 0.4          THEN '0.2-0.4 - Moderate'
        WHEN IRRADIATION < 0.6          THEN '0.4-0.6 - Good'
        WHEN IRRADIATION < 0.8          THEN '0.6-0.8 - Strong'
        WHEN IRRADIATION < 1.0          THEN '0.8-1.0 - Very Strong'
        ELSE                                 '1.0+ - Peak'
    END                                                AS irradiance_group,
    COUNT(*)                                           AS reading_count,
    ROUND(AVG(AC_POWER), 1)                            AS avg_ac_power_kw,
    ROUND(MAX(AC_POWER), 1)                            AS max_ac_power_kw
FROM solar_merged
GROUP BY irradiance_group
ORDER BY AVG(IRRADIATION);

------------------------------------------------------------------------------
------------------------------------------------------------------------------




-- Q12: Average performance ratio at different module temperatures
-- Business question: Does high panel temperature reduce output?
-- Concept: CASE WHEN temperature buckets + performance ratio calculation
-- This query quantifies the temperature penalty in real generation terms

SELECT 
    CASE 
        WHEN MODULE_TEMPERATURE < 25  THEN 'Under 25C - Cool'
        WHEN MODULE_TEMPERATURE < 35  THEN '25-35C - Warm'
        WHEN MODULE_TEMPERATURE < 45  THEN '35-45C - Hot'
        WHEN MODULE_TEMPERATURE < 55  THEN '45-55C - Very Hot'
        ELSE                               'Over 55C - Extreme'
    END                                                         AS temp_bucket,
    COUNT(*)                                                     AS readings,
    ROUND(AVG(AC_POWER), 1)                                     AS avg_power_kw,
    ROUND(AVG(AC_POWER) / NULLIF(AVG(IRRADIATION) * 30460, 0), 4)  AS avg_performance_ratio
FROM solar_merged
WHERE IRRADIATION > 0.1
GROUP BY temp_bucket
ORDER BY AVG(MODULE_TEMPERATURE);

------------------------------------------------------------------------------
------------------------------------------------------------------------------




-- Q13: Running total of generation across all 34 days
-- Business question: At what pace is the plant accumulating energy output?
-- Concept: SUM() as a window function to create a running total
-- This running total line is used in the executive dashboard

WITH daily AS (
    SELECT 
        date,
        ROUND(SUM(AC_POWER) * 0.25 / 1000, 3)  AS daily_mwh
    FROM solar_generation
    GROUP BY date
)
SELECT 
    date,
    daily_mwh,
    ROUND(SUM(daily_mwh) OVER (ORDER BY date), 2)       AS cumulative_mwh,
    ROUND(SUM(daily_mwh) OVER (ORDER BY date) 
          / ROW_NUMBER() OVER (ORDER BY date) * 34, 1)  AS projected_34day_total
FROM daily
ORDER BY date;

------------------------------------------------------------------------------
------------------------------------------------------------------------------




-- Q14: Flag days where generation drops more than 25% vs the previous day
-- Business question: Which days had sudden unexpected drops in output?
-- Concept: Self-join to compare each day with the day before it
-- These flagged days are your maintenance investigation list

WITH daily AS (
    SELECT 
        date,
        ROUND(SUM(AC_POWER) * 0.25, 1)  AS daily_kwh
    FROM solar_generation
    GROUP BY date
)
SELECT 
    today.date                                                     AS anomaly_date,
    ROUND(today.daily_kwh, 1)                                      AS today_kwh,
    ROUND(yesterday.daily_kwh, 1)                                  AS yesterday_kwh,
    ROUND((today.daily_kwh - yesterday.daily_kwh) 
          / NULLIF(yesterday.daily_kwh, 0) * 100, 1)               AS change_pct,
    CASE 
        WHEN (today.daily_kwh - yesterday.daily_kwh) 
             / NULLIF(yesterday.daily_kwh, 0) < -0.25 
        THEN 'INVESTIGATE'
        ELSE 'Normal'
    END                                                             AS action
FROM daily today
JOIN daily yesterday 
    ON yesterday.date = DATE(today.date, '-1 day')
ORDER BY change_pct ASC;

------------------------------------------------------------------------------
------------------------------------------------------------------------------


-- Q15: Complete performance summary per inverter for the full period
-- Business question: Which inverters are reliable and which need attention?
-- Concept: Multiple aggregations + CASE WHEN status classification
-- This is your maintenance team's reference table

SELECT 
    SOURCE_KEY                                                          AS inverter_id,
    ROUND(SUM(AC_POWER) * 0.25, 1)                                     AS total_kwh,
    ROUND(AVG(AC_POWER), 2)                                            AS avg_power_kw,
    ROUND(MAX(AC_POWER), 2)                                            AS peak_power_kw,
    ROUND(SUM(AC_POWER) / NULLIF(SUM(DC_POWER), 0) * 100, 2)          AS efficiency_pct,
    COUNT(CASE WHEN AC_POWER = 0 
               AND hour BETWEEN 6 AND 18 
               THEN 1 END) * 0.25                                       AS daytime_zero_hours,
    CASE 
        WHEN SUM(AC_POWER) / NULLIF(SUM(DC_POWER), 0) >= 0.95 
             AND COUNT(CASE WHEN AC_POWER = 0 
                            AND hour BETWEEN 6 AND 18 
                            THEN 1 END) < 10
        THEN 'Healthy'
        WHEN SUM(AC_POWER) / NULLIF(SUM(DC_POWER), 0) >= 0.90
        THEN 'Monitor'
        ELSE 'Investigate'
    END                                                                 AS status
FROM solar_generation
WHERE DC_POWER > 0
GROUP BY SOURCE_KEY
ORDER BY total_kwh DESC;


------------------------------------------------------------------------------
------------------------------------------------------------------------------