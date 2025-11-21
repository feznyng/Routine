-- Create Devices table
CREATE TABLE devices (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL,
    last_pulled_at TIMESTAMPTZ,
    user_id uuid not null references auth.users on delete cascade,
    fcm_token text
);

-- Create Routines table
CREATE TABLE routines (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    monday BOOLEAN NOT NULL,
    tuesday BOOLEAN NOT NULL,
    wednesday BOOLEAN NOT NULL,
    thursday BOOLEAN NOT NULL,
    friday BOOLEAN NOT NULL,
    saturday BOOLEAN NOT NULL,
    sunday BOOLEAN NOT NULL,
    start_time INTEGER NOT NULL,
    end_time INTEGER NOT NULL,
    recurrence BOOLEAN NOT NULL,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL,
    groups TEXT[] NOT NULL,
    num_breaks_taken INTEGER,
    last_break_at TIMESTAMPTZ,
    paused_until TIMESTAMPTZ,
    max_breaks INTEGER,
    max_break_duration INTEGER NOT NULL DEFAULT 15,
    friction TEXT NOT NULL,
    friction_len INTEGER,
    conditions JSONB,
    snoozed_until TIMESTAMPTZ,
    strict_mode BOOLEAN NOT NULL DEFAULT FALSE,
    completable_before INTEGER NOT NULL DEFAULT 0,
    user_id uuid not null references auth.users on delete cascade
);

-- Create Groups table
CREATE TABLE groups (
    id TEXT PRIMARY KEY,
    name TEXT,
    device TEXT NOT NULL REFERENCES devices(id),
    allow BOOLEAN NOT NULL,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL,
    user_id uuid not null references auth.users on delete cascade
);

CREATE TABLE users (
    id uuid not null primary key references auth.users on delete cascade,
    emergencies JSONB,
    routines_updated_at timestamptz,
    groups_updated_at timestamptz,
    devices_updated_at timestamptz,
    updated_at timestamptz
);

-- Enable Row Level Security for all tables
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE routines ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for devices table
-- Policy for selecting devices (read)
CREATE POLICY devices_select_policy ON devices
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy for inserting devices
CREATE POLICY devices_insert_policy ON devices
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy for updating devices
CREATE POLICY devices_update_policy ON devices
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy for deleting devices
CREATE POLICY devices_delete_policy ON devices
    FOR DELETE
    USING (auth.uid() = user_id);

-- Create RLS policies for routines table
-- Policy for selecting routines (read)
CREATE POLICY routines_select_policy ON routines
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy for inserting routines
CREATE POLICY routines_insert_policy ON routines
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy for updating routines
CREATE POLICY routines_update_policy ON routines
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy for deleting routines
CREATE POLICY routines_delete_policy ON routines
    FOR DELETE
    USING (auth.uid() = user_id);

-- Create RLS policies for groups table
-- Policy for selecting groups (read)
CREATE POLICY groups_select_policy ON groups
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy for inserting groups
CREATE POLICY groups_insert_policy ON groups
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy for updating groups
CREATE POLICY groups_update_policy ON groups
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy for deleting groups
CREATE POLICY groups_delete_policy ON groups
    FOR DELETE
    USING (auth.uid() = user_id);

-- Create RLS policies for users table
-- Policy for selecting users (read)
CREATE POLICY users_select_policy ON users
    FOR SELECT
    USING (auth.uid() = id);

-- Policy for inserting users
CREATE POLICY users_insert_policy ON users
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Policy for updating users
CREATE POLICY users_update_policy ON users
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Policy for deleting users
CREATE POLICY users_delete_policy ON users
    FOR DELETE
    USING (auth.uid() = id);