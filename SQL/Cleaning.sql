SELECT * FROM MISSION_REPORTS;

CREATE TABLE REPORTS_STAGING AS SELECT * FROM MISSION_REPORTS;

-- ============================================================
-- STEP 1: NULLIF CLEANUP (must run while all columns are still VARCHAR)
-- Handles both 'na' and empty string '' entries
-- ============================================================

UPDATE reports_staging SET
    Mission        = NULLIF(NULLIF(TRIM(Mission),        'na'), ''),
    COSPAR         = NULLIF(NULLIF(TRIM(COSPAR),         'na'), ''),
    Initiative     = NULLIF(NULLIF(TRIM(Initiative),     'na'), ''),
    Destination    = NULLIF(NULLIF(TRIM(Destination),    'na'), ''),
    Success        = NULLIF(NULLIF(TRIM(Success),        'na'), ''),
    Mission_Type   = NULLIF(NULLIF(TRIM(Mission_Type),   'na'), ''),
    Launch_Vehicle = NULLIF(NULLIF(TRIM(Launch_Vehicle), 'na'), ''),
    PDS            = NULLIF(NULLIF(TRIM(PDS),            'na'), ''),
    PMS            = NULLIF(NULLIF(TRIM(PMS),            'na'), ''),
    RDS            = NULLIF(NULLIF(TRIM(RDS),            'na'), ''),
    CDS            = NULLIF(NULLIF(TRIM(CDS),            'na'), ''),
    RMS            = NULLIF(NULLIF(TRIM(RMS),            'na'), ''),
    CMS            = NULLIF(NULLIF(TRIM(CMS),            'na'), ''),
    Feasibility    = NULLIF(NULLIF(TRIM(Feasibility),    'na'), ''),
    Funding        = NULLIF(NULLIF(TRIM(Funding),        'na'), ''),
    PDR            = NULLIF(NULLIF(TRIM(PDR),            'na'), ''),
    CDR            = NULLIF(NULLIF(TRIM(CDR),            'na'), ''),
    Launch         = NULLIF(NULLIF(TRIM(Launch),         'na'), ''),
    On_Station     = NULLIF(NULLIF(TRIM(On_Station),     'na'), ''),
    Science        = NULLIF(NULLIF(TRIM(Science),        'na'), ''),
    Extend         = NULLIF(NULLIF(TRIM(Extend),         'na'), ''),
    EoM            = NULLIF(NULLIF(TRIM(EoM),            'na'), ''),
    StartY         = NULLIF(NULLIF(TRIM(StartY),         'na'), ''),
    LaunchY        = NULLIF(NULLIF(TRIM(LaunchY),        'na'), ''),
    PMCT           = NULLIF(NULLIF(TRIM(PMCT),           'na'), ''),
    CMCT           = NULLIF(NULLIF(TRIM(CMCT),           'na'), ''),
    TMCT           = NULLIF(NULLIF(TRIM(TMCT),           'na'), ''),
    TDCT           = NULLIF(NULLIF(TRIM(TDCT),           'na'), ''),
    TLCT           = NULLIF(NULLIF(TRIM(TLCT),           'na'), ''),
    TOCT           = NULLIF(NULLIF(TRIM(TOCT),           'na'), ''),
    TECT           = NULLIF(NULLIF(TRIM(TECT),           'na'), ''),
    TMCN           = NULLIF(NULLIF(TRIM(TMCN),           'na'), ''),
    TDCN           = NULLIF(NULLIF(TRIM(TDCN),           'na'), ''),
    TLCN           = NULLIF(NULLIF(TRIM(TLCN),           'na'), ''),
    TOCN           = NULLIF(NULLIF(TRIM(TOCN),           'na'), ''),
    TECN           = NULLIF(NULLIF(TRIM(TECN),           'na'), ''),
    TMCP           = NULLIF(NULLIF(TRIM(TMCP),           'na'), ''),
    TDCP           = NULLIF(NULLIF(TRIM(TDCP),           'na'), ''),
    TLCP           = NULLIF(NULLIF(TRIM(TLCP),           'na'), ''),
    TOCP           = NULLIF(NULLIF(TRIM(TOCP),           'na'), ''),
    TECP           = NULLIF(NULLIF(TRIM(TECP),           'na'), ''),
    LM             = NULLIF(NULLIF(TRIM(LM),             'na'), ''),
    Fuel           = NULLIF(NULLIF(TRIM(Fuel),           'na'), ''),
    AKM            = NULLIF(NULLIF(TRIM(AKM),            'na'), ''),
    Ball           = NULLIF(NULLIF(TRIM(Ball),           'na'), ''),
    SCdry          = NULLIF(NULLIF(TRIM(SCdry),          'na'), ''),
    SVbus          = NULLIF(NULLIF(TRIM(SVbus),          'na'), ''),
    Svpay          = NULLIF(NULLIF(TRIM(Svpay),          'na'), ''),
    Probe          = NULLIF(NULLIF(TRIM(Probe),          'na'), ''),
    Cruise         = NULLIF(NULLIF(TRIM(Cruise),         'na'), ''),
    Lander         = NULLIF(NULLIF(TRIM(Lander),         'na'), ''),
    Aero           = NULLIF(NULLIF(TRIM(Aero),           'na'), ''),
    Obj            = NULLIF(NULLIF(TRIM(Obj),            'na'), ''),
    Ins            = NULLIF(NULLIF(TRIM(Ins),            'na'), ''),
    InsMass        = NULLIF(NULLIF(TRIM(InsMass),        'na'), ''),
    InsPwr         = NULLIF(NULLIF(TRIM(InsPwr),         'na'), ''),
    Deploy         = NULLIF(NULLIF(TRIM(Deploy),         'na'), ''),
    BV             = NULLIF(NULLIF(TRIM(BV),             'na'), ''),
    SA             = NULLIF(NULLIF(TRIM(SA),             'na'), ''),  -- text: 'SA' or 'RTG'
    BoLP           = NULLIF(NULLIF(TRIM(BoLP),           'na'), ''),
    BoMPwr         = NULLIF(NULLIF(TRIM(BoMPwr),         'na'), ''),
    BoSPwr         = NULLIF(NULLIF(TRIM(BoSPwr),         'na'), ''),
    SAA            = NULLIF(NULLIF(TRIM(SAA),            'na'), ''),
    SAT            = NULLIF(NULLIF(TRIM(SAT),            'na'), '');  -- text: array type description


-- ============================================================
-- STEP 2: CONVERT DATE COLUMNS (still VARCHAR at this point)
-- Includes Feasibility and Funding which were missed before
-- ============================================================

UPDATE reports_staging SET
    Feasibility = STR_TO_DATE(Feasibility, '%m/%d/%Y'),
    Funding     = STR_TO_DATE(Funding,     '%m/%d/%Y'),
    PDR         = STR_TO_DATE(PDR,         '%m/%d/%Y'),
    CDR         = STR_TO_DATE(CDR,         '%m/%d/%Y'),
    Launch      = STR_TO_DATE(Launch,      '%m/%d/%Y'),
    On_Station  = STR_TO_DATE(On_Station,  '%m/%d/%Y'),
    Science     = STR_TO_DATE(Science,     '%m/%d/%Y'),
    Extend      = STR_TO_DATE(Extend,      '%m/%d/%Y'),
    EoM         = STR_TO_DATE(EoM,         '%m/%d/%Y');


-- ============================================================
-- STEP 3: ALTER COLUMN TYPES
-- ============================================================

ALTER TABLE reports_staging

    -- Date columns
    MODIFY Feasibility  DATE,
    MODIFY Funding      DATE,
    MODIFY PDR          DATE,
    MODIFY CDR          DATE,
    MODIFY Launch       DATE,
    MODIFY On_Station   DATE,
    MODIFY Science      DATE,
    MODIFY Extend       DATE,
    MODIFY EoM          DATE,

    -- Year columns (integer, just a 4-digit year)
    MODIFY StartY       INT,
    MODIFY LaunchY      INT,

    -- Schedule columns (months or years, can have decimals)
    MODIFY PDS          DECIMAL(6,2),   -- proposed design schedule (months)
    MODIFY PMS          DECIMAL(6,2),   -- proposed mission schedule (years)
    MODIFY RDS          DECIMAL(6,2),   -- realized design schedule (months)
    MODIFY CDS          DECIMAL(6,2),   -- calculated design schedule (months)
    MODIFY RMS          DECIMAL(6,2),   -- realized mission schedule (years)
    MODIFY CMS          DECIMAL(6,2),   -- calculated mission schedule (years)

    -- Cost columns in Then-Year dollars (millions)
    MODIFY PMCT         DECIMAL(12,2),
    MODIFY CMCT         DECIMAL(12,2),
    MODIFY TMCT         DECIMAL(12,2),
    MODIFY TDCT         DECIMAL(12,2),
    MODIFY TLCT         DECIMAL(12,2),
    MODIFY TOCT         DECIMAL(12,2),
    MODIFY TECT         DECIMAL(12,2),

    -- Cost columns NSII inflation adjusted (millions)
    MODIFY TMCN         DECIMAL(12,2),
    MODIFY TDCN         DECIMAL(12,2),
    MODIFY TLCN         DECIMAL(12,2),
    MODIFY TOCN         DECIMAL(12,2),
    MODIFY TECN         DECIMAL(12,2),

    -- Cost columns PCEPI inflation adjusted (millions)
    MODIFY TMCP         DECIMAL(12,2),
    MODIFY TDCP         DECIMAL(12,2),
    MODIFY TLCP         DECIMAL(12,2),
    MODIFY TOCP         DECIMAL(12,2),
    MODIFY TECP         DECIMAL(12,2),

    -- Mass columns (kg)
    MODIFY LM           DECIMAL(12,2),
    MODIFY Fuel         DECIMAL(12,2),
    MODIFY AKM          DECIMAL(12,2),
    MODIFY Ball         DECIMAL(12,2),
    MODIFY SCdry        DECIMAL(12,2),
    MODIFY SVbus        DECIMAL(12,2),
    MODIFY Svpay        DECIMAL(12,2),
    MODIFY Probe        DECIMAL(12,2),
    MODIFY Cruise       DECIMAL(12,2),
    MODIFY Lander       DECIMAL(12,2),
    MODIFY Aero         DECIMAL(12,2),

    -- Count columns (whole numbers)
    MODIFY Obj          INT,            -- number of objectives
    MODIFY Ins          INT,            -- number of instruments
    MODIFY Deploy       INT,            -- number of deployments

    -- Instrument columns
    MODIFY InsMass      DECIMAL(12,2),  -- kg
    MODIFY InsPwr       DECIMAL(12,2),  -- watts
    MODIFY BV           DECIMAL(12,4),  -- bus volume (m3)

    -- Power columns (watts)
    MODIFY BoLP         DECIMAL(12,2),
    MODIFY BoMPwr       DECIMAL(12,2),
    MODIFY BoSPwr       DECIMAL(12,2),

    -- Solar array area (m2)
    MODIFY SAA          DECIMAL(12,4);

    -- NOTE: SA and SAT are intentionally left as VARCHAR
    -- SA   = power source type: 'SA' (solar array) or 'RTG'
    -- SAT  = solar array type description e.g. '2-axis gimbal', 'fixed', 'wing'
    -- Casting these to DECIMAL would destroy the data


-- ============================================================
-- STEP 4: QUICK VALIDATION CHECKS
-- Run these after to confirm everything looks right
-- ============================================================

-- Check for any remaining 'na' strings that slipped through
SELECT COUNT(*) AS remaining_na
FROM reports_staging
WHERE CONCAT_WS('|',
    Mission, COSPAR, Initiative, Destination, Success,
    Mission_Type, Launch_Vehicle, SA, SAT
) LIKE '%na%';

-- Check date conversion worked
SELECT Mission, Launch, PDR, CDR
FROM reports_staging
WHERE Launch IS NOT NULL
LIMIT 5;

-- Check cost columns look reasonable (should be numbers in millions)
SELECT Mission, PMCT, CMCT, TMCT
FROM reports_staging
WHERE PMCT IS NOT NULL
LIMIT 5;

-- Check null rates per key column to understand data gaps
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN PMCT    IS NULL THEN 1 ELSE 0 END) AS missing_PMCT,
    SUM(CASE WHEN CMCT    IS NULL THEN 1 ELSE 0 END) AS missing_CMCT,
    SUM(CASE WHEN Launch  IS NULL THEN 1 ELSE 0 END) AS missing_Launch,
    SUM(CASE WHEN LM      IS NULL THEN 1 ELSE 0 END) AS missing_LM,
    SUM(CASE WHEN Success IS NULL THEN 1 ELSE 0 END) AS missing_Success
FROM reports_staging;

SELECT
    SUM(CASE WHEN Mission        IS NULL THEN 1 ELSE 0 END) AS missing_Mission,
    SUM(CASE WHEN COSPAR         IS NULL THEN 1 ELSE 0 END) AS missing_COSPAR,
    SUM(CASE WHEN Initiative     IS NULL THEN 1 ELSE 0 END) AS missing_Initiative,
    SUM(CASE WHEN Destination    IS NULL THEN 1 ELSE 0 END) AS missing_Destination,
    SUM(CASE WHEN Success        IS NULL THEN 1 ELSE 0 END) AS missing_Success,
    SUM(CASE WHEN Mission_Type   IS NULL THEN 1 ELSE 0 END) AS missing_Mission_Type,
    SUM(CASE WHEN Launch_Vehicle IS NULL THEN 1 ELSE 0 END) AS missing_Launch_Vehicle,
    SUM(CASE WHEN SA             IS NULL THEN 1 ELSE 0 END) AS missing_SA,
    SUM(CASE WHEN SAT            IS NULL THEN 1 ELSE 0 END) AS missing_SAT
FROM reports_staging;

UPDATE reports_staging
SET Initiative = 'Independent'
WHERE Initiative IS NULL;

