from django.contrib import admin
from .models import DispositivoBiometrico, HuellaDocente, EventoBiometrico


@admin.register(DispositivoBiometrico)
class DispositivoBiometricoAdmin(admin.ModelAdmin):
    list_display = ['nombre', 'ip', 'puerto', 'activo', 'ultima_conexion']
    list_filter = ['activo']
    search_fields = ['nombre', 'ip', 'numero_serie']


@admin.register(HuellaDocente)
class HuellaDocenteAdmin(admin.ModelAdmin):
    list_display = ['usuario', 'dispositivo', 'user_id_zk', 'activo']
    list_filter = ['activo', 'dispositivo']
    search_fields = ['usuario__username', 'usuario__first_name', 'usuario__last_name']


@admin.register(EventoBiometrico)
class EventoBiometricoAdmin(admin.ModelAdmin):
    list_display = ['usuario', 'dispositivo', 'tipo', 'timestamp', 'procesado']
    list_filter = ['procesado', 'tipo', 'dispositivo']
    date_hierarchy = 'timestamp'
