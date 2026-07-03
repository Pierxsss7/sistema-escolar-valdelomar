import json
from datetime import date
from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.admin.views.decorators import staff_member_required
from django.contrib import messages
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone
from django.db.models import Count
from .models import DispositivoBiometrico, HuellaDocente, EventoBiometrico
from asistencias.models import Asistencia
from usuarios.models import Usuario


@csrf_exempt
def api_recibir_evento(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Solo POST'}, status=405)
    try:
        data = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({'error': 'JSON inválido'}, status=400)

    api_key = data.get('api_key')
    if not api_key:
        return JsonResponse({'error': 'api_key requerida'}, status=401)

    dispositivo = get_object_or_404(DispositivoBiometrico, api_key=api_key, activo=True)
    dispositivo.ultima_conexion = timezone.now()
    dispositivo.save(update_fields=['ultima_conexion'])

    eventos_recibidos = data.get('eventos', [])
    creados = 0
    for ev in eventos_recibidos:
        user_id = ev.get('user_id')
        ts = ev.get('timestamp')
        tipo = ev.get('tipo', 'entrada')
        if not user_id or not ts:
            continue
        evento = EventoBiometrico.objects.create(
            dispositivo=dispositivo,
            user_id_zk=user_id,
            tipo=tipo,
            timestamp=timezone.datetime.fromisoformat(ts) if isinstance(ts, str) else timezone.datetime.fromtimestamp(ts),
        )
        _procesar_evento(evento)
        creados += 1

    return JsonResponse({'ok': True, 'eventos_creados': creados, 'dispositivo': dispositivo.nombre})


def _procesar_evento(evento):
    huella = HuellaDocente.objects.filter(
        dispositivo=evento.dispositivo,
        user_id_zk=evento.user_id_zk,
        activo=True,
    ).first()
    if not huella:
        return

    evento.usuario = huella.usuario
    evento.save(update_fields=['usuario'])

    asignacion = huella.usuario.mis_asignaciones.first()
    if not asignacion:
        return

    hoy = timezone.localtime().date()
    if Asistencia.objects.filter(usuario=huella.usuario, fecha=hoy, materia=asignacion.materia).exists():
        return

    Asistencia.objects.create(
        usuario=huella.usuario,
        materia=asignacion.materia,
        fecha=hoy,
        hora=timezone.localtime().time(),
        estado='presente',
        registrado_por=huella.usuario,
    )
    evento.procesado = True
    evento.save(update_fields=['procesado'])


@staff_member_required
def lista_dispositivos(request):
    dispositivos = DispositivoBiometrico.objects.annotate(
        total_eventos=Count('eventos')
    ).order_by('-activo', 'nombre')
    return render(request, 'biometrico/dispositivos.html', {'dispositivos': dispositivos})


@staff_member_required
def eventos_dispositivo(request, dispositivo_id):
    dispositivo = get_object_or_404(DispositivoBiometrico, id=dispositivo_id)
    eventos = EventoBiometrico.objects.filter(dispositivo=dispositivo).select_related('usuario')[:100]
    return render(request, 'biometrico/eventos.html', {'dispositivo': dispositivo, 'eventos': eventos})


@staff_member_required
def vincular_docente(request):
    docentes = Usuario.objects.filter(rol='profesor', is_active=True)
    dispositivos = DispositivoBiometrico.objects.filter(activo=True)
    huellas = HuellaDocente.objects.filter(activo=True).select_related('usuario', 'dispositivo')

    if request.method == 'POST':
        usuario_id = request.POST.get('usuario')
        dispositivo_id = request.POST.get('dispositivo')
        user_id_zk = request.POST.get('user_id_zk')
        if usuario_id and dispositivo_id and user_id_zk:
            HuellaDocente.objects.update_or_create(
                dispositivo_id=dispositivo_id,
                user_id_zk=user_id_zk,
                defaults={'usuario_id': usuario_id, 'activo': True},
            )
            messages.success(request, 'Docente vinculado al dispositivo biométrico')

    return render(request, 'biometrico/vincular.html', {
        'docentes': docentes,
        'dispositivos': dispositivos,
        'huellas': huellas,
    })
