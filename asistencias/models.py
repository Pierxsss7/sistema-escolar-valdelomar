from django.db import models
from django.conf import settings
from academico.models import Materia


class Asistencia(models.Model):
    ESTADOS = [
        ('presente', 'Presente'),
        ('tarde', 'Tardanza'),
        ('falta', 'Falta'),
        ('justificada', 'Falta Justificada'),
    ]

    usuario = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='asistencias',
    )
    materia = models.ForeignKey(Materia, on_delete=models.CASCADE, related_name='asistencias', blank=True, null=True)
    fecha = models.DateField()
    hora_entrada = models.TimeField(blank=True, null=True)
    hora_salida = models.TimeField(blank=True, null=True)
    estado = models.CharField(max_length=20, choices=ESTADOS, default='presente')
    registrado_por = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='asistencias_registradas',
    )

    class Meta:
        verbose_name = 'Asistencia'
        verbose_name_plural = 'Asistencias'
        unique_together = ['usuario', 'fecha', 'materia']

    def __str__(self):
        return f"{self.usuario.get_full_name()} - {self.fecha} - {self.get_estado_display()}"
