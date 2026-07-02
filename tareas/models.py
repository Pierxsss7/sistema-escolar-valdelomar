from django.db import models
from django.conf import settings
from academico.models import Materia, Grupo


class Tarea(models.Model):
    titulo = models.CharField(max_length=200, verbose_name='Título')
    descripcion = models.TextField(blank=True, verbose_name='Descripción')
    archivo = models.FileField(upload_to='tareas/', blank=True, null=True, verbose_name='Archivo adjunto')
    fecha_entrega = models.DateField(verbose_name='Fecha de entrega')
    profesor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='tareas_creadas',
        limit_choices_to={'rol': 'profesor'},
        verbose_name='Profesor',
    )
    materia = models.ForeignKey(Materia, on_delete=models.CASCADE, related_name='tareas', verbose_name='Materia')
    grupo = models.ForeignKey(Grupo, on_delete=models.CASCADE, related_name='tareas', verbose_name='Grupo')
    fecha_creacion = models.DateTimeField(auto_now_add=True, verbose_name='Fecha de creación')
    activo = models.BooleanField(default=True, verbose_name='Activo')

    class Meta:
        verbose_name = 'Tarea'
        verbose_name_plural = 'Tareas'
        ordering = ['-fecha_creacion']

    def __str__(self):
        return self.titulo
