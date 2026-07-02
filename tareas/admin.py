from django.contrib import admin
from .models import Tarea


@admin.register(Tarea)
class TareaAdmin(admin.ModelAdmin):
    list_display = ['titulo', 'profesor', 'materia', 'grupo', 'fecha_entrega', 'activo']
    list_filter = ['activo', 'materia', 'grupo']
    search_fields = ['titulo', 'descripcion']
