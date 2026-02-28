-- ============================================================
-- SECTION 2: COST ANALYSIS
-- ============================================================

-- Total and average cost by destination
WITH Cost_Totals AS (
    SELECT
        Mission,
        Destination,
        Total_Mission_Cost
    FROM missions_clean
)
SELECT
    Destination,
    COUNT(*)                                        AS Mission_Count,
    ROUND(AVG(Total_Mission_Cost), 2)               AS Avg_Mission_Cost,
    ROUND(SUM(Total_Mission_Cost), 2)               AS Total_Portfolio_Cost
FROM Cost_Totals
GROUP BY Destination
ORDER BY Avg_Mission_Cost DESC;


-- Cost breakdown by phase per destination
SELECT
    Destination,
    COUNT(*)                                        AS Mission_Count,
    ROUND(AVG(Total_Dev_Cost), 2)                   AS Avg_Dev_Cost,
    ROUND(AVG(Total_Launch_Cost), 2)                AS Avg_Launch_Cost,
    ROUND(AVG(Total_Ops_Cost), 2)                   AS Avg_Ops_Cost,
    ROUND(AVG(Total_Extension_Cost), 2)             AS Avg_Extension_Cost,
    ROUND(AVG(Total_Mission_Cost), 2)               AS Avg_Total_Cost
FROM missions_clean
GROUP BY Destination
ORDER BY Avg_Total_Cost DESC;


-- Budget vs actual cost performance
SELECT
    Mission,
    Initiative,
    Destination,
    LaunchY,
    Proposed_Cost                                   AS Budget,
    Realized_Cost                                   AS Actual,
    Cost_Variance,
    Cost_Variance_Pct,
    CASE
        WHEN Cost_Variance > 0  THEN 'Over Budget'
        WHEN Cost_Variance < 0  THEN 'Under Budget'
        ELSE                         'On Budget'
    END                                             AS Budget_Status
FROM missions_clean
WHERE Proposed_Cost IS NOT NULL
  AND Realized_Cost IS NOT NULL
ORDER BY Cost_Variance_Pct DESC;

