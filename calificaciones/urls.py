from django.urls import path
from . import views

urlpatterns = [
    path('registrar/<int:asignacion_id>/', views.registrar_calificaciones, name='registrar_calificaciones'),
    path('lista/', views.lista_calificaciones, name='lista_calificaciones'),
    path('boleta/<int:alumno_id>/', views.boleta_alumno, name='boleta_alumno'),
]
