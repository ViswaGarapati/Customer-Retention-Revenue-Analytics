PRAGMA foreign_keys=ON;
CREATE TABLE calendar(month TEXT PRIMARY KEY, seq INTEGER UNIQUE NOT NULL);
CREATE TABLE account(id INTEGER PRIMARY KEY, channel TEXT NOT NULL, joined TEXT NOT NULL REFERENCES calendar);
CREATE TABLE contract_event(
 account_id INTEGER REFERENCES account, month TEXT REFERENCES calendar,
 mrr_cents INTEGER NOT NULL CHECK(mrr_cents>=0), PRIMARY KEY(account_id,month)
);
CREATE TABLE invoice(
 id INTEGER PRIMARY KEY, account_id INTEGER REFERENCES account, month TEXT REFERENCES calendar,
 amount INTEGER NOT NULL CHECK(amount>0), UNIQUE(account_id,month)
);
CREATE TABLE payment_attempt(
 invoice_id INTEGER REFERENCES invoice, attempt INTEGER CHECK(attempt IN (1,2)),
 collected INTEGER NOT NULL CHECK(collected>=0), PRIMARY KEY(invoice_id,attempt)
);
