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
    elif request.user.rol == 'alumno':
        inscripcion = Inscripcion.objects.filter(
            alumno=request.user, activo=True
        ).select_related('grupo', 'grupo__grado').first()

        grupo = inscripcion.grupo if inscripcion else None
        contexto_alumno = _contexto_alumno(request.user, grupo)
        context.update(contexto_alumno)
        context['mis_asignaciones'] = []

    else:
        context['mis_asignaciones'] = []

    return render(request, 'home.html', context)


def _contexto_alumno(user, grupo):
    ctx = {}
    if not grupo:
        ctx['alumno_grupo'] = None
        ctx['mis_materias_grupo'] = []
        ctx['mis_calificaciones'] = []
        ctx['mis_asistencias_recientes'] = []
        ctx['alumno_stats'] = {
            'promedio': 0, 'total_notas': 0, 'aprobadas': 0,
            'asistencias_total': 0, 'asistencias_presente': 0,
            'asistencias_tarde': 0, 'asistencias_falta': 0,
            'pct_asistencia': 0, 'materias_count': 0,
        }
        ctx['alumno_calif_por_materia'] = []
        ctx['alumno_por_periodo'] = []
        ctx['alumno_cursos_detalle'] = []
        ctx['tareas_pendientes'] = 0
        ctx['proximas_tareas_alumno'] = []
        ctx['comunicados_recientes'] = []
        return ctx

    materias_ids = Asignacion.objects.filter(
        grupo=grupo
    ).values_list('materia_id', flat=True).distinct()

    ctx['alumno_grupo'] = grupo
    ctx['mis_materias_grupo'] = Materia.objects.filter(
        id__in=materias_ids
    ).select_related('grado')

    todas_calif = Calificacion.objects.filter(
        alumno=user, materia_id__in=materias_ids
    ).select_related('materia', 'periodo').order_by('-periodo__fecha_inicio', 'materia__nombre')

    ctx['mis_calificaciones'] = todas_calif[:8]

    total_notas = todas_calif.count()
    aprobadas = todas_calif.filter(nota__gte=11).count()
    promedio = todas_calif.aggregate(Avg('nota'))['nota__avg'] or 0

    todas_asist = Asistencia.objects.filter(usuario=user)
    asist_total = todas_asist.count()
    asist_presente = todas_asist.filter(estado='presente').count()
    asist_tarde = todas_asist.filter(estado='tarde').count()
    asist_falta = todas_asist.filter(estado='falta').count()
    pct_asistencia = round(asist_presente / asist_total * 100) if asist_total else 0

    ctx['alumno_stats'] = {
        'promedio': round(promedio, 1),
        'total_notas': total_notas,
        'aprobadas': aprobadas,
        'asistencias_total': asist_total,
        'asistencias_presente': asist_presente,
        'asistencias_tarde': asist_tarde,
        'asistencias_falta': asist_falta,
        'pct_asistencia': pct_asistencia,
        'materias_count': len(materias_ids),
    }

    tareas_pendientes = Tarea.objects.filter(
        materia_id__in=materias_ids, activo=True,
        fecha_entrega__gte=date.today(),
    ).count()
    ctx['tareas_pendientes'] = tareas_pendientes

    calif_por_materia = (
        todas_calif.values('materia__nombre')
        .annotate(promedio_materia=Avg('nota'), total=Count('id'))
        .order_by('materia__nombre')
    )
    ctx['alumno_calif_por_materia'] = [
        {
            'nombre': c['materia__nombre'],
            'promedio': round(c['promedio_materia'] or 0, 1),
            'total': c['total'],
        }
        for c in calif_por_materia
    ]

    periodos_con_calif = (
        todas_calif.values('periodo__nombre')
        .annotate(promedio_periodo=Avg('nota'))
        .order_by('-periodo__fecha_inicio')
    )
    ctx['alumno_por_periodo'] = [
        {
            'nombre': p['periodo__nombre'],
            'promedio': round(p['promedio_periodo'] or 0, 1),
        }
        for p in periodos_con_calif
    ]

    ctx['mis_asistencias_recientes'] = todas_asist.select_related(
        'materia'
    ).order_by('-fecha', '-id')[:6]

    asignaciones_grupo = Asignacion.objects.filter(
        grupo=grupo
    ).select_related('materia', 'profesor')

    cursos_detalle = []
    for asig in asignaciones_grupo:
        ultima_calif = todas_calif.filter(
            materia=asig.materia
        ).select_related('periodo').order_by('-fecha_registro').first()
        prom_materia = todas_calif.filter(
            materia=asig.materia
        ).aggregate(prom=Avg('nota'))['prom']
        cursos_detalle.append({
            'materia': asig.materia,
            'profesor': asig.profesor,
            'ultima_nota': ultima_calif.nota if ultima_calif else None,
            'ultima_nota_periodo': ultima_calif.periodo.nombre if ultima_calif else None,
            'promedio': round(prom_materia, 1) if prom_materia else None,
        })
    ctx['alumno_cursos_detalle'] = cursos_detalle

    ctx['proximas_tareas_alumno'] = Tarea.objects.filter(
        materia_id__in=materias_ids, activo=True,
        fecha_entrega__gte=date.today(),
    ).select_related('materia').order_by('fecha_entrega')[:5]

    ctx['comunicados_recientes'] = Anuncio.objects.filter(
        activo=True
    ).select_related('autor').order_by('-fecha_creacion')[:5]

    return ctx


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
    path('biometrico/', include('biometrico.urls')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
