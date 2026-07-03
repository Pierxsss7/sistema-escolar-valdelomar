from django.db import models
from django.conf import settings


class DispositivoBiometrico(models.Model):
    nombre = models.CharField(max_length=100)
    ip = models.GenericIPAddressField(verbose_name='Dirección IP')
    puerto = models.IntegerField(default=4370, help_text='Puerto TCP (4370 por defecto ZKTeco)')
    numero_serie = models.CharField(max_length=100, blank=True)
    api_key = models.CharField(max_length=64, unique=True, help_text='Clave secreta para autenticar el dispositivo')
    ubicacion = models.CharField(max_length=200, blank=True, help_text='Ej: Entrada principal, Sala de profesores')
    activo = models.BooleanField(default=True)
    ultima_conexion = models.DateTimeField(null=True, blank=True)
    fecha_registro = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Dispositivo Biométrico'
        verbose_name_plural = 'Dispositivos Biométricos'

    def __str__(self):
        return f'{self.nombre} ({self.ip}:{self.puerto})'


class HuellaDocente(models.Model):
    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='huellas')
    dispositivo = models.ForeignKey(DispositivoBiometrico, on_delete=models.CASCADE, related_name='huellas')
    user_id_zk = models.IntegerField(verbose_name='ID en ZKTeco', help_text='ID numérico del usuario en el dispositivo')
    template = models.TextField(blank=True, help_text='Plantilla de huella (base64)')
    activo = models.BooleanField(default=True)
    fecha_registro = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Huella de Docente'
        verbose_name_plural = 'Huellas de Docentes'
        unique_together = ['dispositivo', 'user_id_zk']

    def __str__(self):
        return f'{self.usuario.get_full_name()} - ID ZK: {self.user_id_zk}'


class EventoBiometrico(models.Model):
    TIPO_EVENTO = [
        ('entrada', 'Entrada'),
        ('salida', 'Salida'),
        ('desconocido', 'Desconocido'),
    ]
    dispositivo = models.ForeignKey(DispositivoBiometrico, on_delete=models.CASCADE, related_name='eventos')
    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    user_id_zk = models.IntegerField(help_text='ID del usuario registrado por el dispositivo')
    tipo = models.CharField(max_length=20, choices=TIPO_EVENTO, default='entrada')
    timestamp = models.DateTimeField(help_text='Fecha/hora del marcaje según el dispositivo')
    procesado = models.BooleanField(default=False, help_text='¿Ya se registró la asistencia en el sistema?')
    recibido_en = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Evento Biométrico'
        verbose_name_plural = 'Eventos Biométricos'
        ordering = ['-timestamp']

    def __str__(self):
        return f'{self.usuario or self.user_id_zk} - {self.tipo} - {self.timestamp}'
