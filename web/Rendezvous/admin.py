from iiitd.Rendezvous.models import Student, Course_registration, Responder, New_registration, Subject, Question, Response, Assignment, Call_detail
from django.contrib import admin

class Courses(admin.ModelAdmin):
    list_display = ('studentID', 'subjectID')
    list_filter = ('studentID', 'subjectID')

class SubjectInline(admin.TabularInline):
    model = Course_registration
class ResponderInline(admin.TabularInline):
    model = Responder
class QuestionInline(admin.TabularInline):
    model = Question
class StudentAdmin(admin.ModelAdmin):
    inlines = [SubjectInline, QuestionInline]
class SubjectAdmin(admin.ModelAdmin):
    inlines = [ResponderInline,SubjectInline, QuestionInline,]
class ResponseInline(admin.TabularInline):
    model = Response
class QuestionAdmin(admin.ModelAdmin):
    inlines = [ResponseInline,]
class ResponderAdmin(admin.ModelAdmin):
    list_display = ('name', 'subject','position')
    list_filter = ('subject','position')
    inlines = [ResponseInline,]
class ResponseAdmin(admin.ModelAdmin):
    list_display = ('file_name', 'repliedby','posting_date','questionid')
    list_filter = ('repliedby','posting_date')
    #inlines = [ResponseInline,]
admin.site.register(Student,StudentAdmin)
admin.site.register(Course_registration,Courses)
admin.site.register(Responder,ResponderAdmin)
#admin.site.register(StudentProfile)
admin.site.register(New_registration)
admin.site.register(Subject,SubjectAdmin)
admin.site.register(Question,QuestionAdmin)
admin.site.register(Response,ResponseAdmin)
admin.site.register(Assignment)
admin.site.register(Call_detail)
