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

-- Atomic full-snapshot sync. The client posts its whole local snapshot, this
-- merges it against stored state in one transaction, and returns the result.

-- Tombstone retention. Past this, a device is forced through the reset path.
CREATE OR REPLACE FUNCTION sync_tombstone_ttl()
RETURNS interval LANGUAGE sql IMMUTABLE AS $fn$
  SELECT interval '90 days'
$fn$;

-- Overlay a client row's dirty fields onto the corresponding remote row.
CREATE OR REPLACE FUNCTION sync_merge_row(remote jsonb, local_row jsonb)
RETURNS jsonb LANGUAGE sql IMMUTABLE AS $fn$
  SELECT CASE
    -- Remote-only: nothing local to overlay.
    WHEN local_row IS NULL THEN remote
    -- Local-only: a row this client created (or a tombstone it still holds).
    WHEN remote IS NULL THEN local_row - 'changes' - 'last_pulled_at' - 'fcm_token'
    -- Both sides: remote wins except on fields the client marked dirty.
    ELSE remote || COALESCE((
      SELECT jsonb_object_agg(t.k, local_row -> t.k)
      FROM jsonb_array_elements_text(COALESCE(local_row -> 'changes', '[]'::jsonb)) AS t(k)
      WHERE local_row ? t.k
        AND t.k NOT IN ('id', 'user_id', 'fcm_token', 'last_pulled_at')
    ), '{}'::jsonb)
  END
$fn$;

-- Merge client rows against stored rows, returning only those that actually
-- differ -- otherwise updated_at churns and every sync notifies peers, who sync
-- and notify back. jsonb_populate_record coerces client JSON to real column
-- types first, so the diff is type-accurate and follows the schema.
CREATE OR REPLACE FUNCTION sync_merge_table(
  tbl regclass,
  uid uuid,
  local_rows jsonb,
  ts timestamptz,
  reset boolean
) RETURNS jsonb LANGUAGE plpgsql AS $fn$
DECLARE
  result jsonb;
BEGIN
  -- Takes a regclass and EXECUTE defaults to PUBLIC, so pin the reachable set.
  IF tbl NOT IN ('devices'::regclass, 'groups'::regclass, 'routines'::regclass) THEN
    RAISE EXCEPTION 'sync_merge_table: table % is not syncable', tbl;
  END IF;

  EXECUTE format($q$
    SELECT COALESCE(jsonb_agg(n.merged || jsonb_build_object('updated_at', $3::timestamptz)), '[]'::jsonb)
    FROM (
      SELECT to_jsonb(jsonb_populate_record(
               NULL::%1$s,
               sync_merge_row(m.remote_j, m.local_j) || jsonb_build_object('user_id', $1::uuid)
             )) AS merged,
             m.remote_j
      FROM (
        SELECT l.j AS local_j, r.j AS remote_j
        FROM (SELECT x ->> 'id' AS id, x AS j
                FROM jsonb_array_elements($2::jsonb) x) l
        FULL OUTER JOIN
             (SELECT t.id, to_jsonb(t) AS j FROM %1$s t WHERE t.user_id = $1::uuid) r
          ON r.id = l.id
        -- Reset: this device may hold rows whose tombstones were already
        -- collected, so drop its local-only rows rather than resurrect deletes.
        WHERE NOT ($4::boolean AND r.id IS NULL)
      ) m
    ) n
    WHERE n.merged - 'updated_at' IS DISTINCT FROM n.remote_j - 'updated_at'
  $q$, tbl)
  INTO result
  USING uid, COALESCE(local_rows, '[]'::jsonb), ts, reset;

  RETURN result;
END
$fn$;

-- Upsert pre-merged rows. Column list is derived from the catalog so the
-- function does not need updating when the schema gains a column.
CREATE OR REPLACE FUNCTION sync_apply(
  tbl regclass,
  rows jsonb,
  exclude_cols text[] DEFAULT '{}'
) RETURNS void LANGUAGE plpgsql AS $fn$
DECLARE
  assignments text;
BEGIN
  IF tbl NOT IN ('devices'::regclass, 'groups'::regclass, 'routines'::regclass) THEN
    RAISE EXCEPTION 'sync_apply: table % is not syncable', tbl;
  END IF;

  IF rows IS NULL OR jsonb_array_length(rows) = 0 THEN
    RETURN;
  END IF;

  SELECT string_agg(format('%I = excluded.%I', attname, attname), ', ')
  INTO assignments
  FROM pg_attribute
  WHERE attrelid = tbl
    AND attnum > 0
    AND NOT attisdropped
    AND attname <> 'id'
    AND NOT (attname = ANY(exclude_cols));

  EXECUTE format($q$
    INSERT INTO %1$s
    SELECT (jsonb_populate_record(NULL::%1$s, x)).*
    FROM jsonb_array_elements($1::jsonb) x
    ON CONFLICT (id) DO UPDATE SET %2$s
  $q$, tbl, assignments)
  USING rows;
END
$fn$;

-- Entry point. payload: { device_id, devices[], groups[], routines[],
-- emergencies[], prune_emergencies_before }, rows carrying a "changes" array of
-- dirty column names. Returns the merged snapshot, tombstones excluded.
CREATE OR REPLACE FUNCTION sync_snapshot(payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $fn$
DECLARE
  uid           uuid        := auth.uid();
  v_now         timestamptz := transaction_timestamp();
  v_device      text        := payload ->> 'device_id';
  v_prune       timestamptz := nullif(payload ->> 'prune_emergencies_before', '')::timestamptz;
  v_last_pulled timestamptz;
  v_known       boolean     := false;
  v_reset       boolean;
  v_devices     jsonb;
  v_groups      jsonb;
  v_routines    jsonb;
  v_emg_old     jsonb;
  v_emg_new     jsonb;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'sync_snapshot: not authenticated';
  END IF;
  IF v_device IS NULL THEN
    RAISE EXCEPTION 'sync_snapshot: device_id is required';
  END IF;

  INSERT INTO users (id, emergencies) VALUES (uid, '[]'::jsonb)
  ON CONFLICT (id) DO NOTHING;

  SELECT true, last_pulled_at INTO v_known, v_last_pulled
  FROM devices WHERE id = v_device AND user_id = uid;

  -- A device we have never seen is a first sync, not a stale one.
  v_reset := COALESCE(v_known, false)
             AND v_last_pulled IS NOT NULL
             AND v_last_pulled < v_now - sync_tombstone_ttl();

  -- Devices before groups (groups.device references them).
  v_devices  := sync_merge_table('devices'::regclass,  uid, payload -> 'devices',  v_now, v_reset);
  PERFORM sync_apply('devices'::regclass, v_devices, ARRAY['fcm_token', 'last_pulled_at']);

  v_groups   := sync_merge_table('groups'::regclass,   uid, payload -> 'groups',   v_now, v_reset);
  PERFORM sync_apply('groups'::regclass, v_groups);

  v_routines := sync_merge_table('routines'::regclass, uid, payload -> 'routines', v_now, v_reset);
  PERFORM sync_apply('routines'::regclass, v_routines);

  -- Union by id, earliest-known end wins, then close out all but the most
  -- recent. The prune cutoff is client-computed, since "this week" is local.
  SELECT COALESCE(emergencies, '[]'::jsonb) INTO v_emg_old FROM users WHERE id = uid;

  WITH l AS (
    SELECT e ->> 'id' AS id, e FROM jsonb_array_elements(COALESCE(payload -> 'emergencies', '[]'::jsonb)) e
  ), r AS (
    SELECT e ->> 'id' AS id, e FROM jsonb_array_elements(v_emg_old) e
  ), u AS (
    SELECT
      COALESCE(l.id, r.id) AS id,
      COALESCE(l.e ->> 'started_at', r.e ->> 'started_at') AS started_at,
      COALESCE(l.e ->> 'ended_at',   r.e ->> 'ended_at')   AS ended_at
    FROM l FULL OUTER JOIN r ON r.id = l.id
  ), kept AS (
    SELECT * FROM u
    WHERE v_prune IS NULL OR started_at::timestamptz >= v_prune
  ), windowed AS (
    SELECT k.*,
           first_value(started_at) OVER (ORDER BY started_at::timestamptz DESC) AS latest_started_at
    FROM kept k
  )
  SELECT COALESCE(jsonb_agg(
           jsonb_strip_nulls(jsonb_build_object(
             'id', id,
             'started_at', started_at,
             'ended_at', CASE WHEN started_at = latest_started_at
                              THEN ended_at
                              ELSE COALESCE(ended_at, latest_started_at) END
           )) ORDER BY started_at::timestamptz
         ), '[]'::jsonb)
  INTO v_emg_new
  FROM windowed;

  -- users.*_updated_at is maintained only so clients still on the old
  -- incremental sync keep working during rollout; nothing here reads it.
  UPDATE users SET
    emergencies        = v_emg_new,
    updated_at         = CASE WHEN v_emg_new IS DISTINCT FROM v_emg_old THEN v_now ELSE updated_at END,
    devices_updated_at = CASE WHEN jsonb_array_length(v_devices)  > 0 THEN v_now ELSE devices_updated_at END,
    groups_updated_at  = CASE WHEN jsonb_array_length(v_groups)   > 0 THEN v_now ELSE groups_updated_at END,
    routines_updated_at= CASE WHEN jsonb_array_length(v_routines) > 0 THEN v_now ELSE routines_updated_at END
  WHERE id = uid;

  -- Collect expired tombstones. Reverse FK order.
  DELETE FROM routines WHERE user_id = uid AND deleted AND updated_at < v_now - sync_tombstone_ttl();
  DELETE FROM groups   WHERE user_id = uid AND deleted AND updated_at < v_now - sync_tombstone_ttl();
  DELETE FROM devices  WHERE user_id = uid AND deleted AND updated_at < v_now - sync_tombstone_ttl();

  -- Watermark, for the calling device only.
  UPDATE devices SET last_pulled_at = v_now WHERE id = v_device AND user_id = uid;

  RETURN jsonb_build_object(
    'synced_at', v_now,
    'reset',     v_reset,
    -- Drives peer notification, so it must stay false on no-op syncs.
    'changed',   jsonb_array_length(v_devices) > 0
                 OR jsonb_array_length(v_groups) > 0
                 OR jsonb_array_length(v_routines) > 0
                 OR v_emg_new IS DISTINCT FROM v_emg_old,
    'devices',  (SELECT COALESCE(jsonb_agg(to_jsonb(t) - 'fcm_token'), '[]'::jsonb)
                   FROM devices t  WHERE t.user_id = uid AND NOT t.deleted),
    'groups',   (SELECT COALESCE(jsonb_agg(to_jsonb(t)), '[]'::jsonb)
                   FROM groups t   WHERE t.user_id = uid AND NOT t.deleted),
    'routines', (SELECT COALESCE(jsonb_agg(to_jsonb(t)), '[]'::jsonb)
                   FROM routines t WHERE t.user_id = uid AND NOT t.deleted),
    'emergencies', v_emg_new
  );
END
$fn$;

GRANT EXECUTE ON FUNCTION sync_snapshot(jsonb) TO authenticated;