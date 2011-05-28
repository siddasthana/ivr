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

-----------------------------------------------------------------------
-----------------------------------------------------------------------
GRANT ALL PRIVILEGES on ivr.I_course_registered To web;
GRANT ALL PRIVILEGES on ivr.I_students To web;


GRANT ALL PRIVILEGES on  ivr.I_Responder To web;


GRANT ALL PRIVILEGES on  ivr.I_subjects To web;


GRANT ALL PRIVILEGES on  ivr.I_answer To web;


GRANT ALL PRIVILEGES on ivr.I_assignment To web;


GRANT SELECT on ivr.I_question To web;
GRANT ALL on ivr.auth_group To web;         
 GRANT ALL on ivr.auth_group_permissions To web;     
 GRANT ALL on ivr.auth_message To web;    
 GRANT ALL on ivr.auth_permission To web;            
 GRANT ALL on ivr.auth_user To web;           
 GRANT ALL on ivr.auth_user_groups To web;           
 GRANT ALL on ivr.auth_user_user_permissions To web; 
 GRANT ALL on ivr.django_admin_log To web;
 GRANT ALL on ivr.django_content_type To web;        
 GRANT ALL on ivr.django_flatpage To web;       
 GRANT ALL on ivr.django_flatpage_sites To web;      
 GRANT ALL on ivr.django_session To web;     
 GRANT ALL on ivr.django_site To web;            
 GRANT ALL on ivr.new_reg To web;               
 GRANT ALL on ivr.sms_received To web;               
 GRANT ALL on ivr.sms_sent To web;


