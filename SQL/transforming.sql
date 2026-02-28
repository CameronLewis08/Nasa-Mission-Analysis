-- ============================================================
-- transformed_table.sql
-- Creates the clean working table from staging with:
--   - Dropped sparse/redundant columns
--   - Binary flags for complex mission components
--   - Complexity score for risk analysis
--   - Calculated fields for budget, risk, and training views
-- ============================================================


-- ============================================================
-- STEP 1: CREATE CLEAN TABLE
-- ============================================================

DROP TABLE IF EXISTS missions_clean;

CREATE TABLE missions_clean AS
SELECT
    -- --------------------------------------------------------
    -- IDENTIFIERS & CATEGORICALS
    -- --------------------------------------------------------
    Mission,
    Initiative,
    Destination,
    Success,
    Mission_Type,
    Launch_Vehicle,

    -- --------------------------------------------------------
    -- SCHEDULE
    -- --------------------------------------------------------
    StartY,
    LaunchY,
    Funding                                         AS Funding_Date,
    Launch                                          AS Launch_Date,
    EoM                                             AS End_of_Mission,
    PDR                                             AS Preliminary_Design_Review_Date,     -- date PDR was completed
    CDR                                             AS Critical_Design_Review_Date,        -- date CDR was completed
    PDS                                             AS Proposed_Design_Schedule_Months,    -- planned months from funding to launch
    PMS                                             AS Proposed_Mission_Schedule_Yrs,      -- planned years from launch to end of mission
    RDS                                             AS Realized_Design_Schedule_Months,    -- actual months from funding to launch
    CDS                                             AS Calculated_Design_Schedule_Months,  -- calculated months funding to launch date
    RMS                                             AS Realized_Mission_Schedule_Yrs,      -- actual years from launch to current/end status
    CMS                                             AS Calculated_Mission_Schedule_Yrs,    -- calculated years launch to end of mission date

    -- Design review gap fields (longer gaps may indicate design problems)
    CASE
        WHEN CDR IS NOT NULL AND PDR IS NOT NULL
        THEN DATEDIFF(CDR, PDR)
        ELSE NULL
    END                                             AS PDR_to_CDR_Days,

    CASE
        WHEN Launch IS NOT NULL AND CDR IS NOT NULL
        THEN DATEDIFF(Launch, CDR)
        ELSE NULL
    END                                             AS CDR_to_Launch_Days,

    -- --------------------------------------------------------
    -- COST (NSII inflation-adjusted, millions $)
    -- Dropped: Then-Year (TMCT etc.) and PCEPI (TMCP etc.)
    -- --------------------------------------------------------
    PMCT                                            AS Proposed_Cost,       -- your BudgetAmount
    CMCT                                            AS Realized_Cost,       -- your ActualCost
    TMCN                                            AS Total_Mission_Cost,
    TDCN                                            AS Total_Dev_Cost,
    TLCN                                            AS Total_Launch_Cost,
    TOCN                                            AS Total_Ops_Cost,
    TECN                                            AS Total_Extension_Cost,

    -- --------------------------------------------------------
    -- CALCULATED COST FIELDS
    -- --------------------------------------------------------
    CMCT - PMCT                                     AS Cost_Variance,       -- positive = over budget
    CASE
        WHEN PMCT > 0 THEN ROUND((CMCT - PMCT) / PMCT * 100, 2)
        ELSE NULL
    END                                             AS Cost_Variance_Pct,   -- % over/under budget

    -- --------------------------------------------------------
    -- MISSION DURATION
    -- --------------------------------------------------------
    CASE
        WHEN EoM IS NOT NULL AND Launch IS NOT NULL
        THEN ROUND(DATEDIFF(EoM, Launch) / 365.25, 2)
        ELSE NULL
    END                                             AS Mission_Duration_Yrs,

    CASE
        WHEN EoM IS NOT NULL AND Funding IS NOT NULL
        THEN ROUND(DATEDIFF(EoM, Funding) / 365.25, 2)
        ELSE NULL
    END                                             AS Total_Program_Yrs,

    -- --------------------------------------------------------
    -- SCHEDULE VARIANCE
    -- --------------------------------------------------------
    CASE
        WHEN RDS IS NOT NULL AND PDS IS NOT NULL
        THEN ROUND(RDS - PDS, 2)
        ELSE NULL
    END                                             AS Schedule_Variance_Months, -- positive = delayed

    -- --------------------------------------------------------
    -- TECHNICAL / MASS
    -- --------------------------------------------------------
    LM                                              AS Launch_Mass_kg,
    SCdry                                           AS Dry_Mass_kg,
    SVbus                                           AS Bus_Mass_kg,
    Svpay                                           AS Payload_Mass_kg,
    Fuel                                            AS Fuel_Mass_kg,
    Lander                                          AS Lander_Mass_kg,
    BV                                              AS Bus_Volume_m3,

    -- --------------------------------------------------------
    -- INSTRUMENTS & POWER
    -- --------------------------------------------------------
    Obj                                             AS Num_Objectives,
    Ins                                             AS Num_Instruments,
    InsMass                                         AS Instrument_Mass_kg,
    InsPwr                                          AS Instrument_Power_W,
    Deploy                                          AS Num_Deployments,
    SA                                              AS Power_Source,
    SAT                                             AS Solar_Array_Type,
    SAA                                             AS Solar_Array_Area_m2,
    BoLP                                            AS BOL_Power_W,
    BoMPwr                                          AS BOM_Power_W,
    BoSPwr                                          AS BOS_Power_W,

    -- --------------------------------------------------------
    -- COMPLEXITY FLAGS (for risk analysis)
    -- NULL in staging = mission did not have this component
    -- --------------------------------------------------------
    CASE WHEN AKM    IS NOT NULL THEN 1 ELSE 0 END  AS Has_AKM,
    CASE WHEN Probe  IS NOT NULL THEN 1 ELSE 0 END  AS Has_Probe,
    CASE WHEN Cruise IS NOT NULL THEN 1 ELSE 0 END  AS Has_Cruise,
    CASE WHEN Aero   IS NOT NULL THEN 1 ELSE 0 END  AS Has_Aeroshield,
    CASE WHEN Ball   IS NOT NULL THEN 1 ELSE 0 END  AS Has_Ballast,
    CASE WHEN Lander IS NOT NULL THEN 1 ELSE 0 END  AS Has_Lander,

    -- --------------------------------------------------------
    -- COMPOSITE COMPLEXITY SCORE (0-6)
    -- Higher score = more mission components = higher risk
    -- --------------------------------------------------------
    (
        CASE WHEN AKM    IS NOT NULL THEN 1 ELSE 0 END +
        CASE WHEN Probe  IS NOT NULL THEN 1 ELSE 0 END +
        CASE WHEN Cruise IS NOT NULL THEN 1 ELSE 0 END +
        CASE WHEN Aero   IS NOT NULL THEN 1 ELSE 0 END +
        CASE WHEN Ball   IS NOT NULL THEN 1 ELSE 0 END +
        CASE WHEN Lander IS NOT NULL THEN 1 ELSE 0 END
    )                                               AS Complexity_Score,

    -- --------------------------------------------------------
    -- SUCCESS FLAG (easier to filter than string)
    -- --------------------------------------------------------
    CASE WHEN Success = 'Success'     THEN 1 ELSE 0 END AS Is_Success,
    CASE WHEN Success = 'Failure'     THEN 1 ELSE 0 END AS Is_Failure,
    CASE WHEN Success = 'Operational' THEN 1 ELSE 0 END AS Is_Operational

FROM reports_staging;


-- ============================================================
-- STEP 2: QUICK VALIDATION
-- ============================================================

-- Confirm row count matches staging
SELECT COUNT(*) AS total_rows FROM missions_clean;

-- Preview calculated fields
SELECT
    Mission,
    Proposed_Cost,
    Realized_Cost,
    Cost_Variance,
    Cost_Variance_Pct,
    Mission_Duration_Yrs,
    Schedule_Variance_Months,
    Complexity_Score,
    Success
FROM missions_clean
LIMIT 10;

