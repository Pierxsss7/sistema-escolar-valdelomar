from django.urls import path
from . import views

urlpatterns = [
    path('api/evento/', views.api_recibir_evento, name='api_biometrico_evento'),
    path('dispositivos/', views.lista_dispositivos, name='lista_dispositivos'),
    path('dispositivos/<int:dispositivo_id>/eventos/', views.eventos_dispositivo, name='eventos_dispositivo'),
    path('vincular/', views.vincular_docente, name='vincular_docente'),
]
