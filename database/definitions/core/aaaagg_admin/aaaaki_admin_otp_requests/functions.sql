-- database/definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/functions.sql

-- Apply the shared utility trigger to automatically update 'updated_at'
CREATE TRIGGER tr_aaaaki_admin_otp_requests_updated_at
BEFORE UPDATE ON aaaaki_admin_otp_requests
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();

-- Verify an OTP atomically
-- AI CONTEXT: device_id_hmac is intentionally omitted from the WHERE clause 
-- to allow for standard cross-device email verification flows.
CREATE OR REPLACE FUNCTION aaaaki_verify_otp(
    p_email_hmac BYTEA,
    p_code TEXT,
    p_code_secret TEXT,         -- Replaced session variable with direct parameter
    p_purpose TEXT DEFAULT 'login',
    p_action TEXT DEFAULT NULL,
    p_max_attempts INT DEFAULT 5
)
RETURNS TABLE (ok BOOLEAN, reason TEXT, otp_id BIGINT, request_id UUID)
LANGUAGE plpgsql
AS $$
DECLARE
    v_code_hmac BYTEA;
    v_row aaaaki_admin_otp_requests%ROWTYPE;
BEGIN
    -- Guard against missing secret
    IF p_code_secret IS NULL OR length(p_code_secret) = 0 THEN
        RETURN QUERY SELECT false, 'missing_secret', NULL::BIGINT, NULL::UUID;
        RETURN;
    END IF;

    -- Compute HMAC(code)
    -- Requires pgcrypto extension to be enabled in shared definitions
    v_code_hmac := hmac(p_code::BYTEA, p_code_secret::BYTEA, 'sha256');

    -- Lock the most recent active candidate row to avoid races.
    SELECT *
    INTO v_row
    FROM aaaaki_admin_otp_requests
    WHERE email_hmac = p_email_hmac
      AND code_hash IS NOT NULL
      AND used_at IS NULL
      AND expires_at > NOW()
      AND purpose = p_purpose
      AND (p_purpose <> 'action' OR action = p_action)
    ORDER BY expires_at DESC, created_at DESC
    FOR UPDATE SKIP LOCKED
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'not_found', NULL::BIGINT, NULL::UUID;
        RETURN;
    END IF;

    -- If too many attempts, treat as exhausted/expired
    IF v_row.attempts >= p_max_attempts THEN
        UPDATE aaaaki_admin_otp_requests
        SET expires_at = LEAST(COALESCE(expires_at, NOW()), NOW())
        WHERE id = v_row.id;

        RETURN QUERY SELECT false, 'attempts_exceeded', v_row.id, v_row.request_id;
        RETURN;
    END IF;

    -- Compare hashes safely
    IF v_row.code_hash = v_code_hmac THEN
        -- Success: mark used
        UPDATE aaaaki_admin_otp_requests
        SET used_at = NOW()
        WHERE id = v_row.id;

        RETURN QUERY SELECT true, 'ok', v_row.id, v_row.request_id;
        RETURN;
    ELSE
        -- Failure: increment attempts
        UPDATE aaaaki_admin_otp_requests
        SET attempts = attempts + 1
        WHERE id = v_row.id;

        RETURN QUERY SELECT false, 'invalid_code', v_row.id, v_row.request_id;
        RETURN;
    END IF;
END;
$$;


-- Creates a canonical ledger entry for OTP requests
CREATE OR REPLACE FUNCTION aaaaki_create_otp_request(
    p_request_id UUID,
    p_email_hmac BYTEA,
    p_device_hmac BYTEA,
    p_ip INET,
    p_user_agent TEXT,
    p_locale TEXT,
    p_send_status TEXT, 
    p_code TEXT DEFAULT NULL,
    p_ttl_seconds INT DEFAULT 300,
    p_mail_status TEXT DEFAULT NULL,
    p_mail_headers JSONB DEFAULT NULL,
    p_code_secret TEXT DEFAULT NULL,
    p_purpose TEXT DEFAULT 'login',
    p_action TEXT DEFAULT NULL,
    p_action_meta JSONB DEFAULT NULL
)
RETURNS TABLE (id BIGINT, expires_at TIMESTAMPTZ)
LANGUAGE plpgsql
AS $$
DECLARE
    v_expires_at TIMESTAMPTZ := NULL;
    v_code_hmac BYTEA := NULL;
    v_code_last2 SMALLINT := NULL;
BEGIN
    -- Validate send_status
    IF p_send_status NOT IN ('sent', 'skipped_rate_limit', 'deferred', 'failed') THEN
        RAISE EXCEPTION 'aaaaki_create_otp_request: invalid p_send_status %', p_send_status
            USING errcode = '22023';
    END IF;

    -- Validate purpose/action relationship
    IF p_purpose NOT IN ('login', 'action') THEN
        RAISE EXCEPTION 'aaaaki_create_otp_request: invalid p_purpose %', p_purpose
            USING errcode = '22023';
    END IF;

    IF p_purpose = 'login' AND p_action IS NOT NULL THEN
        RAISE EXCEPTION 'aaaaki_create_otp_request: p_action must be NULL when p_purpose=login'
            USING errcode = '22023';
    END IF;

    IF p_purpose = 'action' AND p_action IS NULL THEN
        RAISE EXCEPTION 'aaaaki_create_otp_request: p_action required when p_purpose=action'
            USING errcode = '22023';
    END IF;

    -- Compute artifacts if actually sending
    IF p_send_status = 'sent' THEN
        IF p_code IS NULL OR length(p_code) = 0 THEN
            RAISE EXCEPTION 'aaaaki_create_otp_request: p_code required when p_send_status=sent'
                USING errcode = '22023';
        END IF;

        IF p_code_secret IS NULL OR length(p_code_secret) = 0 THEN
            RAISE EXCEPTION 'aaaaki_create_otp_request: p_code_secret is not set for hashing'
                USING errcode = '22023';
        END IF;

        v_code_hmac := hmac(p_code::BYTEA, p_code_secret::BYTEA, 'sha256');

        IF p_code ~ '\d{2}$' THEN
            v_code_last2 := right(p_code, 2)::SMALLINT;
        ELSE
            v_code_last2 := NULL;
        END IF;

        v_expires_at := NOW() + make_interval(secs => greatest(p_ttl_seconds, 1));
    END IF;

    RETURN QUERY
    INSERT INTO aaaaki_admin_otp_requests AS r (
        request_id, created_at, updated_at, email_hmac, device_id_hmac, ip, user_agent, locale,
        purpose, action, action_meta, code_hash, code_last2,
        expires_at, used_at, attempts, send_status, mail_status, mail_headers
    )
    VALUES (
        p_request_id, NOW(), NOW(), p_email_hmac, p_device_hmac, p_ip, p_user_agent, p_locale,
        p_purpose, p_action, p_action_meta, v_code_hmac, v_code_last2,
        v_expires_at, NULL, 0, p_send_status, p_mail_status, p_mail_headers
    )
    RETURNING r.id, r.expires_at;
END;
$$;


-- Maintenance helper: prune old OTP ledger rows
CREATE OR REPLACE FUNCTION aaaaki_prune_otp_requests(p_days INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_cutoff TIMESTAMPTZ := NOW() - make_interval(days => greatest(p_days, 1));
    v_deleted INT;
BEGIN
    DELETE FROM aaaaki_admin_otp_requests
    WHERE created_at < v_cutoff;

    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$;