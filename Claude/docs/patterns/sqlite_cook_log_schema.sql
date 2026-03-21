-- TJ Data Kitchen — Cook Log Schema
-- Matches Project Bible Section 7 (Data Schema)
-- Execute this to initialize the database.

-- ============================================
-- EQUIPMENT PROFILES
-- ============================================
CREATE TABLE IF NOT EXISTS equipment_profiles (
    id TEXT PRIMARY KEY,                    -- e.g., 'offset_stick_burner'
    name TEXT NOT NULL,                     -- display name
    temp_variance_f REAL NOT NULL,          -- σ for Monte Carlo smoker temp noise (°F)
    recovery_speed TEXT NOT NULL,           -- 'slow', 'medium', 'fast'
    is_custom BOOLEAN DEFAULT 0,
    notes TEXT
);

-- Default presets (from Project Bible Section 6, Equipment Profiles)
INSERT OR IGNORE INTO equipment_profiles VALUES
    ('offset_stick', 'Offset Stick-Burner', 27.5, 'slow', 0, 'Massive temp swings, high skill floor'),
    ('pellet_grill', 'Pellet Grill (Traeger, RecTeq)', 6.5, 'fast', 0, 'PID-controlled, tight variance'),
    ('kamado', 'Kamado (BGE, Kamado Joe)', 10.0, 'slow', 0, 'Excellent insulation, stable'),
    ('wsm', 'Weber Smokey Mountain', 15.0, 'medium', 0, 'Well-characterized baseline'),
    ('custom', 'Custom / Other', 15.0, 'medium', 1, 'User-defined variance');

-- ============================================
-- COOK SESSIONS
-- ============================================
CREATE TABLE IF NOT EXISTS cooks (
    cook_id TEXT PRIMARY KEY,               -- UUID, auto-generated
    created_at TEXT NOT NULL DEFAULT (datetime('now')),

    -- Section 7A: Protein & Geometry
    protein_category TEXT NOT NULL,          -- 'beef', 'pork', 'poultry', 'lamb', 'other'
    cut TEXT NOT NULL,                       -- e.g., 'brisket_packer', 'pork_butt'
    grade TEXT,                              -- 'select', 'choice', 'prime', 'wagyu'
    mass_lbs REAL NOT NULL,
    thickness_in REAL NOT NULL,             -- thickest point
    aspect_ratio REAL,                      -- length / width (recommended)
    initial_temp_f REAL NOT NULL,           -- fridge ~38°F or room ~68°F
    bone_in BOOLEAN NOT NULL DEFAULT 0,
    fat_cap_thickness_in REAL,              -- insulation layer

    -- Section 7C: Cooking Method
    equipment_id TEXT REFERENCES equipment_profiles(id),
    target_smoker_temp_f REAL NOT NULL,     -- setpoint
    fuel_source TEXT,                       -- 'charcoal', 'wood_oak', 'pellets', etc.
    target_internal_temp_f REAL NOT NULL,   -- desired pull temp

    -- Timing
    start_time TEXT,                        -- ISO timestamp
    end_time TEXT,                          -- ISO timestamp
    pull_temp_f REAL,                       -- actual final internal temp

    -- Rest
    rest_method TEXT,                       -- 'cooler', 'cambro', 'oven', 'none'
    rest_duration_min REAL,

    -- Predictions (saved for post-cook comparison)
    predicted_p10_min REAL,
    predicted_p50_min REAL,
    predicted_p90_min REAL,
    mc_seed INTEGER,                        -- for reproducibility

    -- Section 7D: Quality Assessment
    quality_tenderness INTEGER CHECK (quality_tenderness BETWEEN 1 AND 10),
    quality_moisture INTEGER CHECK (quality_moisture BETWEEN 1 AND 10),
    quality_bark INTEGER CHECK (quality_bark BETWEEN 1 AND 10),
    would_serve_to_guests BOOLEAN,
    notes TEXT
);

-- ============================================
-- PROBE READINGS (Manual V1, API V2+)
-- ============================================
CREATE TABLE IF NOT EXISTS probe_readings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cook_id TEXT NOT NULL REFERENCES cooks(cook_id),
    timestamp TEXT NOT NULL,                -- ISO timestamp
    temp_f REAL NOT NULL,
    -- Derived fields (calculated on insert)
    slope_f_per_min REAL,                   -- dT/dt from recent readings
    is_stall_detected BOOLEAN DEFAULT 0     -- set when slope < 0.02 for 10+ min
);

-- ============================================
-- INTERVENTION LOG (Wrap Events + Other)
-- ============================================
CREATE TABLE IF NOT EXISTS interventions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cook_id TEXT NOT NULL REFERENCES cooks(cook_id),
    timestamp TEXT NOT NULL,
    action TEXT NOT NULL,                   -- 'wrap_butcher_paper', 'wrap_foil',
                                            -- 'wrap_foil_boat', 'no_wrap_decision',
                                            -- 'lid_open', 'lid_close', 'spritz',
                                            -- 'fuel_add', 'temp_adjust'
    internal_temp_at_event REAL,
    stall_duration_at_event_min REAL,       -- for wrap events
    stall_probability_at_event REAL,        -- for wrap events
    duration_min REAL,                      -- for lid_open events
    notes TEXT
);

-- ============================================
-- WEATHER SNAPSHOTS (Cached from API)
-- ============================================
CREATE TABLE IF NOT EXISTS weather_snapshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cook_id TEXT NOT NULL REFERENCES cooks(cook_id),
    timestamp TEXT NOT NULL,
    temp_f REAL,
    humidity_pct REAL,
    wind_speed_mph REAL,
    wind_gust_mph REAL,
    pressure_hpa REAL,
    altitude_ft REAL,
    source TEXT DEFAULT 'openweather'       -- 'openweather', 'manual', 'gps'
);

-- ============================================
-- PAIRWISE COMPARISONS (V2+, schema ready now)
-- ============================================
CREATE TABLE IF NOT EXISTS pairwise_comparisons (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cook_a_id TEXT NOT NULL REFERENCES cooks(cook_id),
    cook_b_id TEXT NOT NULL REFERENCES cooks(cook_id),
    result TEXT NOT NULL CHECK (result IN ('a_better', 'b_better', 'equal')),
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    notes TEXT
);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_probe_cook ON probe_readings(cook_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_intervention_cook ON interventions(cook_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_weather_cook ON weather_snapshots(cook_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_cooks_protein ON cooks(protein_category, cut);
