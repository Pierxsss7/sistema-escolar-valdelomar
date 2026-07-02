from django.contrib.auth.models import AbstractUser
from django.db import models


class Usuario(AbstractUser):
    TIPO_USUARIO = [
        ('admin', 'Administrador'),
        ('director', 'Director'),
        ('profesor', 'Profesor'),
        ('alumno', 'Alumno'),
        ('padre', 'Padre de Familia'),
    ]

    rol = models.CharField(max_length=20, choices=TIPO_USUARIO, default='alumno')
    dni = models.CharField(max_length=8, unique=True, blank=True, null=True, verbose_name='DNI')
    telefono = models.CharField(max_length=15, blank=True, null=True)
    direccion = models.TextField(blank=True, null=True)
    foto = models.ImageField(upload_to='fotos/', blank=True, null=True)
    especialidad = models.CharField(max_length=200, blank=True, null=True, verbose_name='Especialidad')
    titulo_profesional = models.CharField(max_length=200, blank=True, null=True, verbose_name='Título Profesional')
    fecha_nacimiento = models.DateField(blank=True, null=True, verbose_name='Fecha de Nacimiento')

    class Meta:
        verbose_name = 'Usuario'
        verbose_name_plural = 'Usuarios'

    def __str__(self):
        return f"{self.get_full_name() or self.username} ({self.get_rol_display()})"


class CredencialBiometrica(models.Model):
    usuario = models.ForeignKey(Usuario, on_delete=models.CASCADE, related_name='credenciales_biometricas')
    credential_id = models.TextField(unique=True)
    public_key = models.TextField()
    contador = models.IntegerField(default=0)
    creado = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Credencial Biométrica'
        verbose_name_plural = 'Credenciales Biométricas'

    def __str__(self):
        return f"Huella de {self.usuario.username}"


class Parentesco(models.Model):
    padre = models.ForeignKey(
        Usuario, on_delete=models.CASCADE, related_name='hijos',
        limit_choices_to={'rol': 'padre'},
    )
    hijo = models.ForeignKey(
        Usuario, on_delete=models.CASCADE, related_name='padres',
        limit_choices_to={'rol': 'alumno'},
    )
    parentesco = models.CharField(max_length=50, choices=[
        ('padre', 'Padre'),
        ('madre', 'Madre'),
        ('apoderado', 'Apoderado'),
    ], default='padre')
    activo = models.BooleanField(default=True)

    class Meta:
        verbose_name = 'Parentesco'
        verbose_name_plural = 'Parentescos'
        unique_together = ['padre', 'hijo']

    def __str__(self):
        return f"{self.padre.get_full_name()} -> {self.hijo.get_full_name()}"
