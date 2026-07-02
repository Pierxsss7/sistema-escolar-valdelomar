from django.urls import path
from . import views, padres_views

urlpatterns = [
    path('logout/', views.cerrar_sesion, name='logout'),
    path('registrar/', views.registrar, name='registrar'),
    path('registrar-huella/', views.registrar_huella, name='registrar_huella'),
    path('perfil/', views.perfil, name='perfil'),
    path('padre/', padres_views.dashboard_padre, name='dashboard_padre'),
    path('padre/hijo/<int:hijo_id>/asistencias/', padres_views.hijo_asistencias, name='hijo_asistencias'),
    path('padre/hijo/<int:hijo_id>/calificaciones/', padres_views.hijo_calificaciones, name='hijo_calificaciones'),
]
