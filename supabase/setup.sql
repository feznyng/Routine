-- Create enum type for friction
CREATE TYPE friction_type AS ENUM ('none', 'delay', 'intention', 'code');

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
    recurring BOOLEAN NOT NULL,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL,
    groups TEXT[] NOT NULL,
    num_breaks_taken INTEGER,
    last_break_at TIMESTAMPTZ,
    paused_until TIMESTAMPTZ,
    max_breaks INTEGER,
    max_break_duration INTEGER NOT NULL DEFAULT 15,
    friction friction_type NOT NULL,
    friction_len INTEGER,
    conditions TEXT,
    snoozed_until TIMESTAMPTZ,
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