-- Copyright (c) 2019, 2021 Oracle and/or its affiliates. All rights reserved.
-- Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

SET SERVEROUTPUT ON;
SET VERIFY OFF;
BEGIN

    BEGIN
	    -- Schema User Creation
	    DBMS_OUTPUT.PUT_LINE ('** Schema enable steps - &_DATE');
	    ORDS.ENABLE_SCHEMA;
    END;

    BEGIN
        -- Testing Schema Creation
        -- Relational model
		EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS student_dv';
		EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS student_schedule';
		EXECUTE IMMEDIATE 'DROP VIEW IF EXISTS teacher_schedule';
		EXECUTE IMMEDIATE 'DROP TABLE IF EXISTS student_course purge';
		EXECUTE IMMEDIATE 'DROP TABLE IF EXISTS student purge';
		EXECUTE IMMEDIATE 'DROP TABLE IF EXISTS course purge';
		EXECUTE IMMEDIATE 'DROP TABLE IF EXISTS teacher purge';

        -- Students
        EXECUTE IMMEDIATE 'CREATE TABLE student (id NUMBER PRIMARY KEY, name VARCHAR2(128) NOT NULL, info JSON)';
        EXECUTE IMMEDIATE 'INSERT INTO student (id,name) VALUES (3245, ''Jill''),(8524, ''John''),(1735, ''Jane''),(3409, ''Jim'')';

        -- Duality view defined in SQL
        EXECUTE IMMEDIATE 'CREATE OR REPLACE JSON Relational Duality view student_dv AS SELECT JSON {''_id'' : id, ''name'': name, ''info'': info} FROM student WITH (UPDATE, INSERT, DELETE)';

        -- Teachers
        EXECUTE IMMEDIATE 'CREATE TABLE teacher (id NUMBER PRIMARY KEY, name VARCHAR2(128) NOT NULL, salary NUMBER NOT NULL)';

        EXECUTE IMMEDIATE 'INSERT INTO teacher (id,name,salary) VALUES (1, ''Adam'', 1000), (2, ''Anita'', 1100)';
    
        EXECUTE IMMEDIATE 'CREATE TABLE course (id NUMBER PRIMARY KEY, name VARCHAR2(128) NOT NULL, room VARCHAR2(128), time VARCHAR2(5), tid NUMBER, CONSTRAINT fk_course_teacher FOREIGN KEY (tid) REFERENCES teacher(id))';
		
        EXECUTE IMMEDIATE 'CREATE INDEX i_course ON course(tid)';
        
        EXECUTE IMMEDIATE 'INSERT INTO course (id,name,room,time,tid) VALUES (12,''Math 101'',''A102'',''14:00'',1), (15,''Algorithms'',''A104'',''11:00'',2), (16,''Data Structures'',''B101'',''9:00'',2), (17,''Science 102'',''B405'',''16:00'',2)';
    
		EXECUTE IMMEDIATE 'CREATE TABLE student_course (id NUMBER PRIMARY KEY, sid NUMBER NOT NULL, cid NUMBER NOT NULL, CONSTRAINT fk_sc_student FOREIGN KEY (sid) REFERENCES student(id), CONSTRAINT fk_sc_course foreign key (cid) references course(id))';
        
        EXECUTE IMMEDIATE 'CREATE INDEX i_sc_student ON student_course(sid)';
        
        EXECUTE IMMEDIATE 'CREATE INDEX i_sc_course ON student_course(cid)';
        
        EXECUTE IMMEDIATE 'INSERT INTO student_course (id,sid,cid) VALUES (1,3245,12), (2,3245,17), (4,8524,12), (5,8524,15), (6,1735,16), (7,3409,16)';
    
        EXECUTE IMMEDIATE 'CREATE OR REPLACE JSON DUALITY VIEW student_schedule AS student {
          _id       : id
          student  : name
          schedule : student_course [ {
            course @unnest {
              time    : time
              course  : name
              room    : room
              courseId: id
              teacher @unnest {
                teacher  : name
                teacherId: id
              }
            }
            scheduleId: id
          } ]
        }';

		EXECUTE IMMEDIATE 'CREATE OR REPLACE JSON DUALITY VIEW teacher_schedule AS
        teacher @insert @update @delete {
          _id     : id
          teacher  : name
          salary   : salary
          courses : course [ {
            time    : time
            course  : name
            room    : room
            courseId: id
            students: student_course @insert @update @delete [ {
                student @update @nodelete @unnest {
                    name: name
                    studentId: id
                }
                scheduleId: id
            } ]
          } ]
        }';

	END;


    DECLARE col soda_collection_t;
    BEGIN
        col := DBMS_SODA.create_dualv_collection('student_documents', 'STUDENT_DV');
		col := DBMS_SODA.create_dualv_collection('student_schedule', 'STUDENT_SCHEDULE');
		col := DBMS_SODA.create_dualv_collection('teacher_schedule', 'TEACHER_SCHEDULE');
    END;

END;
/

quit;
/