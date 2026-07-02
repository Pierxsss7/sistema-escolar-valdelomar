from django.db import models
from django.conf import settings


class Grado(models.Model):
    nombre = models.CharField(max_length=100)
    nivel = models.CharField(max_length=50, choices=[
        ('preescolar', 'Preescolar'),
        ('primaria', 'Primaria'),
        ('secundaria', 'Secundaria'),
    ])
    orden = models.IntegerField(help_text="Orden del grado (1, 2, 3, etc.)")

    class Meta:
        verbose_name = 'Grado'
        verbose_name_plural = 'Grados'
        ordering = ['nivel', 'orden']

    def __str__(self):
        return f"{self.nombre}"


class Grupo(models.Model):
    nombre = models.CharField(max_length=10, help_text="Ej: A, B, C, Único")
    grado = models.ForeignKey(Grado, on_delete=models.CASCADE, related_name='grupos')

    class Meta:
        verbose_name = 'Grupo'
        verbose_name_plural = 'Grupos'

    def __str__(self):
        return f"{self.grado.nombre} - Grupo {self.nombre}"


class Materia(models.Model):
    nombre = models.CharField(max_length=100)
    grado = models.ForeignKey(Grado, on_delete=models.CASCADE, related_name='materias')

    class Meta:
        verbose_name = 'Materia'
        verbose_name_plural = 'Materias'

    def __str__(self):
        return f"{self.nombre} ({self.grado.nombre})"


class Asignacion(models.Model):
    profesor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='asignaciones',
        limit_choices_to={'rol': 'profesor'},
    )
    materia = models.ForeignKey(Materia, on_delete=models.CASCADE, related_name='asignaciones')
    grupo = models.ForeignKey(Grupo, on_delete=models.CASCADE, related_name='asignaciones')

    class Meta:
        verbose_name = 'Asignación'
        verbose_name_plural = 'Asignaciones'
        unique_together = ['profesor', 'materia', 'grupo']

    def __str__(self):
        return f"{self.profesor.get_full_name()} - {self.materia.nombre} - {self.grupo}"


class Inscripcion(models.Model):
    alumno = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='inscripciones',
        limit_choices_to={'rol': 'alumno'},
    )
    grupo = models.ForeignKey(Grupo, on_delete=models.CASCADE, related_name='inscripciones')
    fecha_inscripcion = models.DateField(auto_now_add=True)
    activo = models.BooleanField(default=True)

    class Meta:
        verbose_name = 'Inscripción'
        verbose_name_plural = 'Inscripciones'
        unique_together = ['alumno', 'grupo']

    def __str__(self):
        return f"{self.alumno.get_full_name()} -> {self.grupo}"


class Horario(models.Model):
    DIAS = [
        ('LUN', 'Lunes'),
        ('MAR', 'Martes'),
        ('MIE', 'Miércoles'),
        ('JUE', 'Jueves'),
        ('VIE', 'Viernes'),
        ('SAB', 'Sábado'),
    ]
    profesor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='horarios',
        limit_choices_to={'rol': 'profesor'},
    )
    materia = models.ForeignKey(Materia, on_delete=models.CASCADE, related_name='horarios')
    grupo = models.ForeignKey(Grupo, on_delete=models.CASCADE, related_name='horarios')
    dia = models.CharField(max_length=3, choices=DIAS, verbose_name='Día')
    hora_inicio = models.TimeField(verbose_name='Hora de inicio')
    hora_fin = models.TimeField(verbose_name='Hora de fin')

    class Meta:
        verbose_name = 'Horario'
        verbose_name_plural = 'Horarios'
        ordering = ['dia', 'hora_inicio']

    def __str__(self):
        return f"{self.get_dia_display()} {self.hora_inicio:%H:%M}-{self.hora_fin:%H:%M} | {self.materia.nombre}"


class Anuncio(models.Model):
    titulo = models.CharField(max_length=200, verbose_name='Título')
    contenido = models.TextField(verbose_name='Contenido')
    autor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='anuncios',
        verbose_name='Autor',
    )
    fecha_creacion = models.DateTimeField(auto_now_add=True, verbose_name='Fecha de creación')
    activo = models.BooleanField(default=True, verbose_name='Activo')

    class Meta:
        verbose_name = 'Anuncio'
        verbose_name_plural = 'Anuncios'
        ordering = ['-fecha_creacion']

    def __str__(self):
        return self.titulo
