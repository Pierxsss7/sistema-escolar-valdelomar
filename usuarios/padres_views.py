from django.shortcuts import render, get_object_or_404
from django.contrib.auth.decorators import login_required
from .models import Parentesco
from asistencias.models import Asistencia
from calificaciones.models import Calificacion


@login_required
def dashboard_padre(request):
    hijos = Parentesco.objects.filter(padre=request.user, activo=True).select_related('hijo')
    hijos_data = []
    for p in hijos:
        hijo = p.hijo
        asistencias = Asistencia.objects.filter(usuario=hijo).order_by('-fecha')[:5]
        calificaciones = Calificacion.objects.filter(alumno=hijo).select_related('materia', 'periodo')[:10]
        hijos_data.append({
            'hijo': hijo,
            'parentesco': p.get_parentesco_display(),
            'asistencias': asistencias,
            'calificaciones': calificaciones,
        })
    return render(request, 'usuarios/dashboard_padre.html', {'hijos_data': hijos_data})


@login_required
def hijo_asistencias(request, hijo_id):
    parentesco = get_object_or_404(Parentesco, padre=request.user, hijo_id=hijo_id, activo=True)
    asistencias = Asistencia.objects.filter(usuario=parentesco.hijo).select_related('materia').order_by('-fecha')
    return render(request, 'usuarios/hijo_asistencias.html', {
        'hijo': parentesco.hijo,
        'asistencias': asistencias,
    })


@login_required
def hijo_calificaciones(request, hijo_id):
    parentesco = get_object_or_404(Parentesco, padre=request.user, hijo_id=hijo_id, activo=True)
    calificaciones = Calificacion.objects.filter(alumno=parentesco.hijo).select_related('materia', 'periodo').order_by('periodo', 'materia')
    return render(request, 'usuarios/hijo_calificaciones.html', {
        'hijo': parentesco.hijo,
        'calificaciones': calificaciones,
    })
