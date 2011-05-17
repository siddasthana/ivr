from iiitd.Rendezvous.models import Student, Course_registration, Responder, New_registration, Subject, Question, Response, Assignment, Call_detail
from django.contrib import admin

class Courses(admin.ModelAdmin):
    list_display = ('studentID', 'subjectID')
    list_filter = ('studentID', 'subjectID')


admin.site.register(Student)
admin.site.register(Course_registration,Courses)
admin.site.register(Responder)
admin.site.register(New_registration)
admin.site.register(Subject)
admin.site.register(Question)
admin.site.register(Response)
admin.site.register(Assignment)
admin.site.register(Call_detail)
