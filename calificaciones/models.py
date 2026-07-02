from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator
from academico.models import Materia


class Periodo(models.Model):
    nombre = models.CharField(max_length=100, help_text="Ej: Primer Bimestre, Segundo Trimestre")
    fecha_inicio = models.DateField()
    fecha_fin = models.DateField()

    class Meta:
        verbose_name = 'Periodo'
        verbose_name_plural = 'Periodos'

    def __str__(self):
        return self.nombre


class Calificacion(models.Model):
    alumno = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='calificaciones',
        limit_choices_to={'rol': 'alumno'},
    )
    materia = models.ForeignKey(Materia, on_delete=models.CASCADE, related_name='calificaciones')
    periodo = models.ForeignKey(Periodo, on_delete=models.CASCADE, related_name='calificaciones')
    nota = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        validators=[MinValueValidator(0), MaxValueValidator(20)],
    )
    observaciones = models.TextField(blank=True, null=True)
    fecha_registro = models.DateTimeField(auto_now_add=True)
    registrado_por = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='calificaciones_registradas',
    )

    class Meta:
        verbose_name = 'Calificación'
        verbose_name_plural = 'Calificaciones'
        unique_together = ['alumno', 'materia', 'periodo']

    def __str__(self):
        return f"{self.alumno.get_full_name()} - {self.materia.nombre} - {self.periodo.nombre}: {self.nota}"
