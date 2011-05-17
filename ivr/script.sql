create database ivr;

CREATE USER 'ivr'@'localhost' IDENTIFIED BY 'ivr';

GRANT ALL PRIVILEGES ON ivr.* TO 'ivr'@'localhost';

CREATE USER 'web'@'%' IDENTIFIED BY 'ivr';

create table I_students (studentID int primary key auto_increment, name VARCHAR(40),phone varchar(10), Freecaller varchar(1));

create table I_course_registered (ID int primary key auto_increment, studentID int, subjectID int);

create table I_Responder (Responder_id int primary key auto_increment, name VARCHAR(40),phone varchar(10), subject int, position varchar(10), Freecaller varchar(1));

create table new_reg (name VARCHAR(40),phone varchar(10), subjects int, Freecaller varchar(1));

create table I_subjects(subjectID int primary key auto_increment, Title VARCHAR(40));

create table I_question(QuestionID int primary key auto_increment, Askedby int , subject_id int,posting_date date, file_name varchar(20));

create table I_answer(Answerid int primary key auto_increment, questionid int,posting_date date, repliedby int, file_name varchar(20));

create table I_assignment(id int primary key auto_increment, questionid int,posting_date date, assignedto int, replied varchar(1));

create table I_call_details(callID int primary key auto_increment, device varchar(20),caller varchar(10), callie varchar(10), starttime int, endtime int);


GRANT INSERT ON ivr.new_reg TO 'web'@'%';


CREATE TRIGGER ResponseUpdate after UPDATE ON I_assignment
FOR EACH ROW
UPDATE I_assignment
SET replied = 'y'
WHERE questionid = OLD.questionid and replied = 'n';

