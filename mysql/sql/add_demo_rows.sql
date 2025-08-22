INSERT INTO customers_data.customers
  (customerKey, addressKey, title, firstName, lastName, birthdate, gender, maritalStatus, email, creationDate)
VALUES
  ('2001','B01','Mr','Ravi','Menon','1985-05-12 00:00:00','MALE','MARRIED','ravi.m@example.com',CURRENT_TIMESTAMP),
  ('2002','B02','Ms','Anita','Pillai','1990-03-22 00:00:00','FEMALE','SINGLE','anita.p@example.com',CURRENT_TIMESTAMP),
  ('2003','B03','Dr','Wei','Zhang','1979-11-01 00:00:00','MALE','MARRIED','wei.z@example.com',CURRENT_TIMESTAMP);
