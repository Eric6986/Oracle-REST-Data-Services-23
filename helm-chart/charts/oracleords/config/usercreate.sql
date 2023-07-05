-- Copyright (c) 2019, 2021 Oracle and/or its affiliates. All rights reserved.
-- Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

SET SERVEROUTPUT ON;
SET VERIFY OFF;
BEGIN
	-- Schema User Creation
	DECLARE
		schemaUserExists INTEGER;
	BEGIN
		SELECT COUNT(*) 
		INTO schemaUserExists 
		FROM ALL_USERS 
		WHERE username = '&1';
		DBMS_OUTPUT.PUT_LINE ('** User creation steps - &_DATE');
		IF schemaUserExists = 0 THEN
			DBMS_OUTPUT.PUT_LINE ('Creating schema = &1 ...');
			EXECUTE IMMEDIATE 'CREATE USER "&1" IDENTIFIED BY "&2"';
			EXECUTE IMMEDIATE 'GRANT SODA_APP, CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE, CREATE PROCEDURE, CREATE JOB, CREATE TRIGGER, UNLIMITED TABLESPACE TO "&1"';
			EXECUTE IMMEDIATE 'GRANT UNLIMITED TABLESPACE TO "&1"';
		ELSE
			DBMS_OUTPUT.PUT_LINE ('Schema User = &1 exists, steps ignored');
		END IF;
	END;
END;
/

quit;
/