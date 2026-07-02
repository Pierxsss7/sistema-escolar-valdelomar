from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.shortcuts import render
from django.contrib.auth.decorators import login_required
from django.contrib.auth import views as auth_views
from usuarios.models import Usuario
from django.db.models import Count, Avg
from datetime import date, timedelta
import json
from academico.models import Grado, Materia, Asignacion, Horario, Anuncio, Inscripcion
from asistencias.models import Asistencia
from calificaciones.models import Calificacion
from tareas.models import Tarea


@login_required
def home(request):
    niveles = {
        'Inicial': 'preescolar',
        'Primaria': 'primaria',
        'Secundaria': 'secundaria',
    }
    materias_por_nivel = {}
    for label, code in niveles.items():
        materias = list(Materia.objects.filter(
            grado__nivel=code
        ).values_list('nombre', flat=True).distinct().order_by('nombre'))
        if materias:
            materias_por_nivel[label] = materias

    estados_raw = Asistencia.objects.values('estado').annotate(
        total=Count('id')
    ).order_by('estado')
    asistencias_data = {e['estado']: e['total'] for e in estados_raw}

    calificaciones = Calificacion.objects.all()
    total_calif = calificaciones.count()
    calif_aprobadas = calificaciones.filter(nota__gte=11).count() if total_calif else 0
    calif_desaprobadas = total_calif - calif_aprobadas

    context = {
        'total_alumnos': Usuario.objects.filter(rol='alumno').count(),
        'total_profesores': Usuario.objects.filter(rol='profesor').count(),
        'total_materias': Materia.objects.count(),
        'total_grados': Grado.objects.count(),
        'ultimas_asistencias': Asistencia.objects.select_related('usuario').order_by('-fecha', '-id')[:10],
        'materias_por_nivel': materias_por_nivel,
        'asist_presente': asistencias_data.get('presente', 0),
        'asist_tarde': asistencias_data.get('tarde', 0),
        'asist_falta': asistencias_data.get('falta', 0),
        'asist_justificada': asistencias_data.get('justificada', 0),
        'total_calificaciones': total_calif,
        'calif_aprobadas': calif_aprobadas,
        'calif_desaprobadas': calif_desaprobadas,
        'anuncios': Anuncio.objects.filter(activo=True)[:5],
    }

    if request.user.rol == 'profesor':
        mis_asignaciones = Asignacion.objects.filter(
            profesor=request.user
        ).select_related('materia', 'grupo', 'grupo__grado')
        grupos_ids = mis_asignaciones.values_list('grupo_id', flat=True).distinct()
        materias_ids = mis_asignaciones.values_list('materia_id', flat=True).distinct()
        alumnos_ids = Inscripcion.objects.filter(
            grupo_id__in=grupos_ids, activo=True
        ).values_list('alumno_id', flat=True).distinct()

        context['mis_asignaciones'] = mis_asignaciones
        context['mis_ultimas_asistencias'] = Asistencia.objects.filter(
            registrado_por=request.user
        ).select_related('usuario', 'materia').order_by('-fecha', '-id')[:5]
        context['total_mis_alumnos'] = len(alumnos_ids)
        context['proximas_tareas'] = Tarea.objects.filter(
            profesor=request.user, activo=True,
            fecha_entrega__gte=date.today(),
        ).order_by('fecha_entrega')[:5]
        context['mis_horarios_hoy'] = Horario.objects.filter(
            profesor=request.user,
            dia=date.today().strftime('%a').upper()[:3],
        ).select_related('materia', 'grupo', 'grupo__grado')
        context['mis_horarios'] = Horario.objects.filter(
            profesor=request.user
        ).select_related('materia', 'grupo', 'grupo__grado').order_by('dia', 'hora_inicio')
        context['dia_labels'] = [
            ('LUN', 'Lunes'), ('MAR', 'Martes'), ('MIE', 'Miércoles'),
            ('JUE', 'Jueves'), ('VIE', 'Viernes'), ('SAB', 'Sábado'),
        ]
        horas_set = set()
        for h in context['mis_horarios']:
            horas_set.add(f'{h.hora_inicio:%H:%M}')
        horas_orden = sorted(horas_set)[:5]
        horarios_por_dia = {d[0]: [] for d in context['dia_labels']}
        for h in context['mis_horarios']:
            horarios_por_dia[h.dia].append(h)
        context['horario_grid'] = []
        for hora in horas_orden:
            fila = {'hora': hora, 'dias': {}}
            for d, _ in context['dia_labels']:
                fila['dias'][d] = [h for h in horarios_por_dia[d] if f'{h.hora_inicio:%H:%M}' == hora]
            context['horario_grid'].append(fila)
        context['today'] = date.today()
        mis_notas = Calificacion.objects.filter(
            materia_id__in=materias_ids,
            alumno_id__in=alumnos_ids,
        )
        context['mis_notas_total'] = mis_notas.count()
        context['mis_notas_aprobadas'] = mis_notas.filter(nota__gte=11).count() if mis_notas.count() else 0
        context['mis_notas_promedio'] = round(mis_notas.aggregate(Avg('nota'))['nota__avg'] or 0, 1)
        mis_asistencias = Asistencia.objects.filter(
            materia_id__in=materias_ids,
            usuario_id__in=alumnos_ids,
        )
        context['mis_asist_presente'] = mis_asistencias.filter(estado='presente').count()
        context['mis_asist_total'] = mis_asistencias.count()
    else:
        context['mis_asignaciones'] = []

    return render(request, 'home.html', context)


urlpatterns = [
    path('admin/', admin.site.urls),
    path('', auth_views.LoginView.as_view(template_name='registration/login.html'), name='login'),
    path('home/', home, name='home'),
    path('usuarios/', include('usuarios.urls')),
    path('academico/', include('academico.urls')),
    path('asistencias/', include('asistencias.urls')),
    path('calificaciones/', include('calificaciones.urls')),
    path('reportes/', include('reportes.urls')),
    path('tareas/', include('tareas.urls')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
