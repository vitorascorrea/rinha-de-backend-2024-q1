CREATE TABLE customers (
  id SERIAL PRIMARY KEY,
  balance_limit INTEGER NOT NULL,
  current_balance INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP
);

CREATE TABLE transactions (
  id SERIAL PRIMARY KEY,
  customer_id INTEGER NOT NULL,
  amount INTEGER NOT NULL,
  kind CHAR(1) NOT NULL,
  description TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP
);

CREATE INDEX transactions_customer_id_index ON transactions(customer_id);

INSERT INTO customers(balance_limit)
VALUES (100000), (80000), (1000000), (10000000), (500000);