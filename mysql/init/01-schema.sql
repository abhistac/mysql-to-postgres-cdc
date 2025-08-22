CREATE DATABASE IF NOT EXISTS customers_data;
USE customers_data;

CREATE TABLE IF NOT EXISTS customers (
  customerKey VARCHAR(32) PRIMARY KEY,
  addressKey  VARCHAR(32),
  title       VARCHAR(16),
  firstName   VARCHAR(64),
  lastName    VARCHAR(64),
  birthdate   DATETIME,
  gender      VARCHAR(16),
  maritalStatus VARCHAR(16),
  email       VARCHAR(128),
  creationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO customers (customerKey, addressKey, title, firstName, lastName, birthdate, gender, maritalStatus, email)
VALUES
('1001', 'A01', 'Mr',  'John',   'Doe',      '1985-03-01 00:00:00', 'MALE',   'SINGLE',  'john.doe@example.com'),
('1002', 'A02', 'Ms',  'Jane',   'Smith',    '1990-07-12 00:00:00', 'FEMALE', 'MARRIED', 'jane.smith@example.com'),
('1003', 'A03', 'Dr',  'Kiran',  'Nair',     '1989-11-05 00:00:00', 'MALE',   'MARRIED', 'k.nair@example.com'),
('1004', 'A04', 'Mr',  'Arjun',  'Kapoor',   '1995-01-22 00:00:00', 'MALE',   'SINGLE',  'arjun.k@example.com'),
('1005', 'A05', 'Mrs', 'Maya',   'Das',      '1992-09-30 00:00:00', 'FEMALE', 'MARRIED', 'maya.d@example.com');
