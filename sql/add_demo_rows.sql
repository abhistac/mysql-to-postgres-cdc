USE customers_data;

INSERT INTO customers (customerKey, addressKey, title, firstName, lastName, birthdate, gender, maritalStatus, email)
VALUES
('2001', 'B01', 'Mr', 'Rahul', 'Sharma', '1991-05-10 00:00:00', 'MALE', 'SINGLE', 'rahul.sharma@example.com'),
('2002', 'B02', 'Ms', 'Priya', 'Reddy',  '1993-02-14 00:00:00', 'FEMALE', 'MARRIED','priya.reddy@example.com');

UPDATE customers SET email='john.new@example.com' WHERE customerKey='1001';
DELETE FROM customers WHERE customerKey='1005';
