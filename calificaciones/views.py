from django.db import models
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from .models import Calificacion, Periodo
from academico.models import Asignacion


@login_required
def registrar_calificaciones(request, asignacion_id):
    asignacion = get_object_or_404(Asignacion, id=asignacion_id)
    inscripciones = asignacion.grupo.inscripciones.filter(activo=True).select_related('alumno')
    periodos = Periodo.objects.all()

    if request.method == 'POST':
        periodo_id = request.POST.get('periodo')
        for insc in inscripciones:
            nota = request.POST.get(f'nota_{insc.alumno.id}')
            if nota:
                Calificacion.objects.update_or_create(
                    alumno=insc.alumno,
                    materia=asignacion.materia,
                    periodo_id=periodo_id,
                    defaults={
                        'nota': nota,
                        'registrado_por': request.user,
                    },
                )
        messages.success(request, 'Calificaciones registradas correctamente')
        return redirect('lista_calificaciones')

    alumnos = [i.alumno for i in inscripciones]
    return render(request, 'calificaciones/registrar.html', {
        'asignacion': asignacion,
        'alumnos': alumnos,
        'periodos': periodos,
    })


@login_required
def lista_calificaciones(request):
    if request.user.rol == 'alumno':
        calificaciones = Calificacion.objects.filter(alumno=request.user).select_related('materia', 'periodo')
        return render(request, 'calificaciones/mis_calificaciones.html', {'calificaciones': calificaciones})
    else:
        calificaciones = Calificacion.objects.select_related('alumno', 'materia', 'periodo').all()
        return render(request, 'calificaciones/lista.html', {'calificaciones': calificaciones})


@login_required
def boleta_alumno(request, alumno_id):
    calificaciones = Calificacion.objects.filter(alumno_id=alumno_id).select_related('materia', 'periodo')
    promedio = calificaciones.aggregate(models.Avg('nota'))['nota__avg'] if calificaciones else 0
    return render(request, 'calificaciones/boleta.html', {
        'calificaciones': calificaciones,
        'promedio': promedio,
    })
