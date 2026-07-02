from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.utils import timezone
from .models import Asistencia
from academico.models import Asignacion


@login_required
def tomar_asistencia(request, asignacion_id):
    asignacion = get_object_or_404(Asignacion, id=asignacion_id)
    inscripciones = asignacion.grupo.inscripciones.filter(activo=True).select_related('alumno')

    if request.method == 'POST':
        fecha = request.POST.get('fecha', timezone.now().date())
        for insc in inscripciones:
            estado = request.POST.get(f'estado_{insc.alumno.id}', 'falta')
            Asistencia.objects.update_or_create(
                usuario=insc.alumno,
                fecha=fecha,
                materia=asignacion.materia,
                defaults={
                    'estado': estado,
                    'hora_entrada': timezone.now().time(),
                    'registrado_por': request.user,
                },
            )
        messages.success(request, 'Asistencia registrada correctamente')
        return redirect('lista_asistencias')

    alumnos = [i.alumno for i in inscripciones]
    return render(request, 'asistencias/tomar_asistencia.html', {
        'asignacion': asignacion,
        'alumnos': alumnos,
    })


@login_required
def lista_asistencias(request):
    if request.user.rol == 'admin':
        asistencias = Asistencia.objects.select_related('usuario', 'materia').all()
    elif request.user.rol == 'profesor':
        asistencias = Asistencia.objects.filter(registrado_por=request.user).select_related('usuario', 'materia').order_by('-fecha')
    elif request.user.rol == 'alumno':
        asistencias = Asistencia.objects.filter(usuario=request.user).select_related('materia').order_by('-fecha')
    else:
        asistencias = Asistencia.objects.select_related('usuario', 'materia').all()

    return render(request, 'asistencias/lista_asistencias.html', {'asistencias': asistencias})


@login_required
def mis_asistencias(request):
    asistencias = Asistencia.objects.filter(usuario=request.user).select_related('materia').order_by('-fecha')
    return render(request, 'asistencias/mis_asistencias.html', {'asistencias': asistencias})
