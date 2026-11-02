ALTER TABLE users ADD COLUMN password_iterations INTEGER NOT NULL DEFAULT 100000;
CREATE TABLE IF NOT EXISTS ai_minute_usage (username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE, minute_bucket INTEGER NOT NULL, count INTEGER NOT NULL DEFAULT 0 CHECK(count >= 0 AND count <= 3), PRIMARY KEY(username, minute_bucket));
CREATE INDEX IF NOT EXISTS ai_minute_usage_bucket_idx ON ai_minute_usage(minute_bucket);
