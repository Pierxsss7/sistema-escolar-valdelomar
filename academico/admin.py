from django.contrib import admin
from .models import Grado, Grupo, Materia, Asignacion, Inscripcion


@admin.register(Grado)
class GradoAdmin(admin.ModelAdmin):
    list_display = ['nombre', 'nivel', 'orden']
    list_filter = ['nivel']


@admin.register(Grupo)
class GrupoAdmin(admin.ModelAdmin):
    list_display = ['__str__', 'grado']


@admin.register(Materia)
class MateriaAdmin(admin.ModelAdmin):
    list_display = ['nombre', 'grado']
    list_filter = ['grado__nivel']


@admin.register(Asignacion)
class AsignacionAdmin(admin.ModelAdmin):
    list_display = ['profesor', 'materia', 'grupo']
    list_filter = ['materia__grado']


@admin.register(Inscripcion)
class InscripcionAdmin(admin.ModelAdmin):
    list_display = ['alumno', 'grupo', 'fecha_inscripcion', 'activo']
    list_filter = ['grupo__grado', 'activo']
