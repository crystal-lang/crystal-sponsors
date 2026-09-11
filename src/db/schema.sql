-- GitHub
CREATE TABLE IF NOT EXISTS github_sponsors (
  login             TEXT PRIMARY KEY,
  name              TEXT NOT NULL,
  url               TEXT,
  logo              TEXT,
  since             TEXT NOT NULL,
  total_contributed REAL NOT NULL DEFAULT 0,
  last_payment      REAL NOT NULL DEFAULT 0,
  last_billed_at    TEXT NOT NULL,
  is_active         INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS github_runs (
  login      TEXT NOT NULL REFERENCES github_sponsors(login),
  week_start TEXT NOT NULL,
  tier       REAL NOT NULL,
  PRIMARY KEY (login, week_start)
);

-- OpenCollective
CREATE TABLE IF NOT EXISTS opencollective_members (
  name                    TEXT PRIMARY KEY,
  type                    TEXT NOT NULL,
  role                    TEXT NOT NULL,
  is_active               INTEGER NOT NULL DEFAULT 0,
  twitter                 TEXT,
  github                  TEXT,
  website                 TEXT,
  image                   TEXT,
  total_donated           REAL NOT NULL DEFAULT 0,
  last_transaction_amount REAL NOT NULL DEFAULT 0,
  created_at              TEXT NOT NULL,
  last_transaction_at     TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS opencollective_transactions (
  member_name TEXT NOT NULL REFERENCES opencollective_members(name),
  month       TEXT NOT NULL,
  amount      REAL NOT NULL,
  PRIMARY KEY (member_name, month)
);