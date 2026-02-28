-- ============================================================
-- SECTION 3: SCHEDULE ANALYSIS
-- ============================================================

-- Average operational duration by destination
SELECT
    Destination,
    COUNT(*)                                        AS Mission_Count,
    ROUND(AVG(Mission_Duration_Yrs), 2)             AS Avg_Duration_Yrs,
    ROUND(AVG(Schedule_Variance_Months), 2)         AS Avg_Schedule_Overrun_Months
FROM missions_clean
WHERE Mission_Duration_Yrs IS NOT NULL
GROUP BY Destination
ORDER BY Avg_Duration_Yrs DESC;


-- Schedule variance by initiative
SELECT
    Initiative,
    COUNT(*)                                        AS Mission_Count,
    ROUND(AVG(Proposed_Design_Schedule_Months), 2)  AS Avg_Planned_Dev_Months,
    ROUND(AVG(Realized_Design_Schedule_Months), 2)  AS Avg_Actual_Dev_Months,
    ROUND(AVG(Schedule_Variance_Months), 2)         AS Avg_Schedule_Variance_Months
FROM missions_clean
WHERE Realized_Design_Schedule_Months IS NOT NULL
GROUP BY Initiative
ORDER BY Avg_Schedule_Variance_Months DESC;


-- Design review timeline per mission
SELECT
    Mission,
    Initiative,
    Destination,
    Success,
    Preliminary_Design_Review_Date,
    Critical_Design_Review_Date,
    Launch_Date,
    PDR_to_CDR_Days,
    CDR_to_Launch_Days,
    Schedule_Variance_Months,
    Cost_Variance_Pct
FROM missions_clean
WHERE Preliminary_Design_Review_Date IS NOT NULL
  AND Critical_Design_Review_Date IS NOT NULL
ORDER BY PDR_to_CDR_Days DESC;


-- Average design review gaps by mission type
SELECT
    Mission_Type,
    COUNT(*)                                        AS Mission_Count,
    ROUND(AVG(PDR_to_CDR_Days), 0)                  AS Avg_PDR_to_CDR_Days,
    ROUND(AVG(CDR_to_Launch_Days), 0)               AS Avg_CDR_to_Launch_Days,
    ROUND(AVG(Schedule_Variance_Months), 2)         AS Avg_Schedule_Variance_Months,
    SUM(Is_Failure)                                 AS Failures
FROM missions_clean
WHERE PDR_to_CDR_Days IS NOT NULL
GROUP BY Mission_Type
ORDER BY Avg_PDR_to_CDR_Days DESC;


-- Proposed vs realized mission duration
SELECT
    Mission,
    Initiative,
    Destination,
    Success,
    Proposed_Mission_Schedule_Yrs                   AS Planned_Mission_Yrs,
    Realized_Mission_Schedule_Yrs                   AS Actual_Mission_Yrs,
    ROUND(Realized_Mission_Schedule_Yrs
        - Proposed_Mission_Schedule_Yrs, 2)         AS Mission_Duration_Variance_Yrs,
    CASE
        WHEN (Realized_Mission_Schedule_Yrs
            - Proposed_Mission_Schedule_Yrs) < 0    THEN 'Shorter Than Planned'
        WHEN (Realized_Mission_Schedule_Yrs
            - Proposed_Mission_Schedule_Yrs) = 0    THEN 'As Planned'
        WHEN (Realized_Mission_Schedule_Yrs
            - Proposed_Mission_Schedule_Yrs) <= 2   THEN 'Slightly Extended'
        ELSE                                             'Significantly Extended'
    END                                             AS Mission_Duration_Category,
    Schedule_Variance_Months                        AS Dev_Schedule_Variance_Months,
    Cost_Variance_Pct,
    Total_Extension_Cost
FROM missions_clean
WHERE Proposed_Mission_Schedule_Yrs IS NOT NULL
  AND Realized_Mission_Schedule_Yrs IS NOT NULL
ORDER BY Mission_Duration_Variance_Yrs DESC;

