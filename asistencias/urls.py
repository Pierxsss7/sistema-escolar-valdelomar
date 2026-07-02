from django.urls import path
from . import views

urlpatterns = [
    path('tomar/<int:asignacion_id>/', views.tomar_asistencia, name='tomar_asistencia'),
    path('lista/', views.lista_asistencias, name='lista_asistencias'),
    path('mis-asistencias/', views.mis_asistencias, name='mis_asistencias'),
]
