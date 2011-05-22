from django.db import models
from django.utils.encoding import *
# Create your models here.

class Student(models.Model):
    studentID = models.AutoField(primary_key=True)
    name = models.CharField(max_length=40, blank=True, null=True)
    phone = models.CharField(max_length=10, blank=True, null=True)
    Freecaller = models.CharField(max_length=1, blank=True, null=True)
    class Meta:
        db_table = 'I_students'
    def __unicode__(self):
        return self.name

class Subject(models.Model):
    subjectID = models.AutoField(primary_key=True)
    Title = models.CharField(max_length=40, blank=True, null=True)
    class Meta:
        db_table = 'I_subjects'
    def __unicode__(self):
        return self.Title

class Course_registration(models.Model):
    ID = models.AutoField(primary_key=True)
    studentID = models.ForeignKey(Student, db_column='studentID')
    subjectID = models.ForeignKey(Subject, db_column='subjectID')
    class Meta:
        db_table = 'I_course_registered'
    def __unicode__(self):
        return smart_unicode(self.studentID, encoding='utf-8', strings_only=False, errors='strict')

class Responder(models.Model):
    Responder_id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=40, blank=True, null=True)
    phone = models.CharField(max_length=10, blank=True, null=True)
    subject = models.ForeignKey(Subject, db_column='subject')
    position = models.CharField(max_length=10, blank=True, null=True)
    Freecaller = models.CharField(max_length=1, blank=True, null=True)
    class Meta:
        db_table = 'I_Responder'
    def __unicode__(self):
        return self.name

class New_registration(models.Model):
    name = models.CharField(max_length=40, blank=True, null=True)
    phone = models.CharField(max_length=10, blank=True, null=True, primary_key=True)
    subjects = models.IntegerField() 
    Freecaller = models.CharField(max_length=1, blank=True, null=True)
    class Meta:
        db_table = 'new_reg'
    def __unicode__(self):
        return self.name

class Question(models.Model):
    QuestionID = models.AutoField(primary_key=True)
    Askedby = models.ForeignKey(Student, db_column='Askedby')
    subject_id = models.ForeignKey(Subject, db_column='subject_id')
    posting_date = models.DateField()
    file_name = models.CharField(max_length=20, blank=True, null=True)
    class Meta:
        db_table = 'I_question'
    def __unicode__(self):
        return self.file_name

class Response(models.Model):
    Answerid = models.AutoField(primary_key=True)
    questionid = models.ForeignKey(Question, db_column='questionid')
    posting_date = models.DateField()
    repliedby = models.ForeignKey(Responder,db_column='repliedby')
    file_name = models.CharField(max_length=20, blank=True, null=True)
    class Meta:
        db_table = 'I_answer'
    def __unicode__(self):
        return self.file_name

class Assignment(models.Model):
    id = models.AutoField(primary_key=True)
    questionid = models.ForeignKey(Question, db_column='questionid')
    posting_date = models.DateField()
    assignedto = models.ForeignKey(Responder, db_column='assignedto')
    replied = models.CharField(max_length=1, blank=True, null=True)
    class Meta:
        db_table = 'I_assignment'
    def __unicode__(self):
        return smart_unicode(self.assignedto, encoding='utf-8', strings_only=False, errors='strict')


class Call_detail(models.Model):
    callID = models.AutoField(primary_key=True)
    device = models.CharField(max_length=20, blank=True, null=True)
    caller = models.CharField(max_length=10, blank=True, null=True)
    callie = models.CharField(max_length=10, blank=True, null=True)
    starttime = models.IntegerField()
    endtime = models.IntegerField()
    class Meta:
        db_table = 'I_call_details'
    def __unicode__(self):
        return smart_unicode(self.caller, encoding='utf-8', strings_only=False, errors='strict')

