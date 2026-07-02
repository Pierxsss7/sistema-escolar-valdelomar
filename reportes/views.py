from django.shortcuts import render
from django.contrib.admin.views.decorators import staff_member_required
from django.http import HttpResponse
from calificaciones.models import Calificacion
from asistencias.models import Asistencia
from academico.models import Grado, Materia
from usuarios.models import Usuario
import csv


@staff_member_required
def reporte_calificaciones(request):
    calificaciones = Calificacion.objects.select_related('alumno', 'materia', 'periodo').all()
    return render(request, 'reportes/calificaciones.html', {'calificaciones': calificaciones})


@staff_member_required
def reporte_asistencias(request):
    asistencias = Asistencia.objects.select_related('usuario', 'materia').all()
    return render(request, 'reportes/asistencias.html', {'asistencias': asistencias})


@staff_member_required
def exportar_csv_calificaciones(request):
    response = HttpResponse(content_type='text/csv')
    response['Content-Disposition'] = 'attachment; filename="calificaciones.csv"'
    writer = csv.writer(response)
    writer.writerow(['Alumno', 'Materia', 'Periodo', 'Nota'])
    for c in Calificacion.objects.select_related('alumno', 'materia', 'periodo').all():
        writer.writerow([c.alumno.get_full_name(), c.materia.nombre, c.periodo.nombre, c.nota])
    return response


@staff_member_required
def exportar_csv_asistencias(request):
    response = HttpResponse(content_type='text/csv')
    response['Content-Disposition'] = 'attachment; filename="asistencias.csv"'
    writer = csv.writer(response)
    writer.writerow(['Usuario', 'Fecha', 'Materia', 'Estado'])
    for a in Asistencia.objects.select_related('usuario', 'materia').all():
        writer.writerow([a.usuario.get_full_name(), a.fecha, a.materia, a.get_estado_display()])
    return response


@staff_member_required
def dashboard(request):
    total_alumnos = Usuario.objects.filter(rol='alumno').count()
    total_profesores = Usuario.objects.filter(rol='profesor').count()
    total_materias = Materia.objects.count()
    total_grados = Grado.objects.count()
    ultimas_asistencias = Asistencia.objects.select_related('usuario').order_by('-fecha')[:10]

    return render(request, 'reportes/dashboard.html', {
        'total_alumnos': total_alumnos,
        'total_profesores': total_profesores,
        'total_materias': total_materias,
        'total_grados': total_grados,
        'ultimas_asistencias': ultimas_asistencias,
    })
