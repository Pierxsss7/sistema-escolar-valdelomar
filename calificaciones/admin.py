from django.contrib import admin
from .models import Periodo, Calificacion


@admin.register(Periodo)
class PeriodoAdmin(admin.ModelAdmin):
    list_display = ['nombre', 'fecha_inicio', 'fecha_fin']


@admin.register(Calificacion)
class CalificacionAdmin(admin.ModelAdmin):
    list_display = ['alumno', 'materia', 'periodo', 'nota']
    list_filter = ['periodo', 'materia__grado']
    search_fields = ['alumno__first_name', 'alumno__last_name']
