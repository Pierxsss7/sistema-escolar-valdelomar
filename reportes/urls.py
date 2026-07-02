from django.urls import path
from . import views

urlpatterns = [
    path('dashboard/', views.dashboard, name='dashboard'),
    path('calificaciones/', views.reporte_calificaciones, name='reporte_calificaciones'),
    path('asistencias/', views.reporte_asistencias, name='reporte_asistencias'),
    path('exportar/calificaciones/', views.exportar_csv_calificaciones, name='exportar_calificaciones'),
    path('exportar/asistencias/', views.exportar_csv_asistencias, name='exportar_asistencias'),
]
