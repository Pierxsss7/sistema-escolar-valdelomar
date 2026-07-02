from django.contrib import admin
from .models import Asistencia


@admin.register(Asistencia)
class AsistenciaAdmin(admin.ModelAdmin):
    list_display = ['usuario', 'fecha', 'materia', 'estado', 'hora_entrada']
    list_filter = ['estado', 'fecha']
    search_fields = ['usuario__first_name', 'usuario__last_name', 'usuario__username']
    date_hierarchy = 'fecha'
