-- Receipts make retries exactly-once at this local service boundary.
CREATE TABLE IF NOT EXISTS session_events (
 session_id TEXT NOT NULL REFERENCES sessions(session_id), request_id TEXT NOT NULL,
 kind TEXT NOT NULL, payload_sha256 TEXT NOT NULL, result_json TEXT NOT NULL CHECK(json_valid(result_json)),
 created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY(session_id,request_id)
);
