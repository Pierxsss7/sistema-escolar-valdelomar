from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.admin.views.decorators import staff_member_required
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.db.models import Avg, Count
from .models import Grado, Grupo, Materia, Asignacion, Inscripcion, Horario, Anuncio
from usuarios.models import Usuario
from calificaciones.models import Calificacion
from tareas.models import Tarea
from asistencias.models import Asistencia
from datetime import date


@login_required
def lista_grados(request):
    grados = Grado.objects.all()
    return render(request, 'academico/grados.html', {'grados': grados})


@staff_member_required
def crear_grado(request):
    if request.method == 'POST':
        Grado.objects.create(
            nombre=request.POST['nombre'],
            nivel=request.POST['nivel'],
            orden=request.POST['orden'],
        )
        messages.success(request, 'Grado creado correctamente')
        return redirect('lista_grados')
    return render(request, 'academico/crear_grado.html')


@login_required
def lista_materias(request, grado_id=None):
    niveles = ['preescolar', 'primaria', 'secundaria']
    materias_por_nivel = {}
    for nivel in niveles:
        qs = Materia.objects.filter(grado__nivel=nivel).select_related('grado')
        agrupadas = {}
        for m in qs:
            agrupadas.setdefault(m.nombre, []).append(m.grado.nombre)
        materias_por_nivel[nivel] = [{'nombre': k, 'grados': sorted(v)} for k, v in sorted(agrupadas.items())]
    grados = Grado.objects.all()
    return render(request, 'academico/materias.html', {
        'materias_por_nivel': materias_por_nivel,
        'grados': grados,
        'grado_seleccionado': grado_id,
    })


@login_required
def lista_grupos(request):
    grupos = Grupo.objects.all()
    return render(request, 'academico/grupos.html', {'grupos': grupos})


@login_required
def lista_asignaciones(request):
    asignaciones = Asignacion.objects.select_related('profesor', 'materia', 'grupo').all()
    return render(request, 'academico/asignaciones.html', {'asignaciones': asignaciones})


@login_required
def alumnos_por_grupo(request, grupo_id):
    grupo = get_object_or_404(Grupo, id=grupo_id)
    inscripciones = Inscripcion.objects.filter(grupo=grupo, activo=True).select_related('alumno')
    return render(request, 'academico/alumnos_grupo.html', {
        'grupo': grupo,
        'inscripciones': inscripciones,
    })


@login_required
def mis_horarios(request):
    if request.user.rol != 'profesor':
        messages.error(request, 'Solo los docentes tienen horarios.')
        return redirect('home')
    horarios = Horario.objects.filter(profesor=request.user).select_related('materia', 'grupo', 'grupo__grado')
    dias_orden = ['LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB']
    horarios_por_dia = {d: [] for d in dias_orden}
    horas_set = set()
    for h in horarios:
        horarios_por_dia[h.dia].append(h)
        horas_set.add(f'{h.hora_inicio:%H:%M}')
    horas_orden = sorted(horas_set)
    grid = []
    for hora in horas_orden:
        fila = {'hora': hora, 'celdas': {}}
        for d in dias_orden:
            clases = [h for h in horarios_por_dia[d] if f'{h.hora_inicio:%H:%M}' == hora]
            fila['celdas'][d] = clases
        grid.append(fila)
    return render(request, 'academico/horarios.html', {
        'horarios_por_dia': horarios_por_dia,
        'dias_orden': dias_orden,
        'grid': grid,
    })


@staff_member_required
def crear_horario(request):
    if request.method == 'POST':
        Horario.objects.create(
            profesor_id=request.POST['profesor'],
            materia_id=request.POST['materia'],
            grupo_id=request.POST['grupo'],
            dia=request.POST['dia'],
            hora_inicio=request.POST['hora_inicio'],
            hora_fin=request.POST['hora_fin'],
        )
        messages.success(request, 'Horario creado correctamente.')
        return redirect('lista_horarios')
    profesores = Usuario.objects.filter(rol='profesor')
    materias = Materia.objects.all()
    grupos = Grupo.objects.all()
    return render(request, 'academico/crear_horario.html', {
        'profesores': profesores,
        'materias': materias,
        'grupos': grupos,
    })


@login_required
def lista_horarios(request):
    if request.user.rol == 'profesor':
        horarios = Horario.objects.filter(profesor=request.user).select_related('materia', 'grupo', 'grupo__grado')
    else:
        horarios = Horario.objects.all().select_related('profesor', 'materia', 'grupo', 'grupo__grado')
    return render(request, 'academico/lista_horarios.html', {'horarios': horarios})


@login_required
def mis_cursos(request):
    if request.user.rol != 'alumno':
        messages.error(request, 'Esta vista es solo para alumnos.')
        return redirect('home')

    inscripcion = Inscripcion.objects.filter(
        alumno=request.user, activo=True
    ).select_related('grupo', 'grupo__grado').first()

    if not inscripcion:
        messages.warning(request, 'No estás inscrito en ningún grupo.')
        return render(request, 'academico/mis_cursos.html', {'cursos': []})

    grupo = inscripcion.grupo
    asignaciones = Asignacion.objects.filter(
        grupo=grupo
    ).select_related('materia', 'profesor', 'materia__grado')

    cursos = []
    colores = ['#3b82f6', '#22c55e', '#a855f7', '#f97316', '#ef4444', '#06b6d4', '#eab308', '#ec4899', '#8b5cf6', '#14b8a6']
    imagenes = [
        '/static/img/curso-matematicas.jpg',
        '/static/img/curso-comunicacion.jpg',
        '/static/img/curso-ciencia.jpg',
        '/static/img/curso-historia.jpg',
        '/static/img/curso-ingles.jpg',
        '/static/img/curso-arte.jpg',
        '/static/img/curso-edufisica.jpg',
        '/static/img/curso-tic.jpg',
    ]

    for i, asig in enumerate(asignaciones):
        califs = Calificacion.objects.filter(
            alumno=request.user, materia=asig.materia
        )
        promedio = califs.aggregate(prom=Avg('nota'))['prom']
        total_notas = califs.count()
        aprobado = promedio is not None and promedio >= 11

        tareas_count = Tarea.objects.filter(
            materia=asig.materia, grupo=grupo, activo=True
        ).count()

        tareas_pendientes = Tarea.objects.filter(
            materia=asig.materia, grupo=grupo, activo=True,
            fecha_entrega__gte=date.today()
        ).count()

        cursos.append({
            'id': asig.materia.id,
            'nombre': asig.materia.nombre,
            'grado': asig.materia.grado.nombre,
            'profesor': asig.profesor,
            'promedio': round(promedio, 1) if promedio else None,
            'total_notas': total_notas,
            'aprobado': aprobado,
            'tareas_count': tareas_count,
            'tareas_pendientes': tareas_pendientes,
            'color': colores[i % len(colores)],
            'imagen': imagenes[i % len(imagenes)],
        })

    return render(request, 'academico/mis_cursos.html', {
        'cursos': cursos,
        'grupo': grupo,
        'total_aprobados': sum(1 for c in cursos if c['aprobado']),
        'total_cursos': len(cursos),
    })


@login_required
def plan_estudios(request):
    if request.user.rol != 'alumno':
        messages.error(request, 'Esta vista es solo para alumnos.')
        return redirect('home')

    inscripcion = Inscripcion.objects.filter(
        alumno=request.user, activo=True
    ).select_related('grupo', 'grupo__grado').first()

    if not inscripcion:
        messages.warning(request, 'No estás inscrito en ningún grupo.')
        return render(request, 'academico/plan_estudios.html', {'materias_plan': []})

    grupo = inscripcion.grupo
    todas_materias = Materia.objects.filter(
        grado=grupo.grado
    ).select_related('grado')

    asignadas_ids = Asignacion.objects.filter(
        grupo=grupo
    ).values_list('materia_id', flat=True)

    materias_plan = []
    for mat in todas_materias:
        calif = Calificacion.objects.filter(
            alumno=request.user, materia=mat
        ).aggregate(prom=Avg('nota'), total=Count('id'))

        promedio = calif['prom']
        total_notas = calif['total']
        aprobado = promedio is not None and promedio >= 11
        asignada = mat.id in asignadas_ids

        materias_plan.append({
            'materia': mat,
            'asignada': asignada,
            'promedio': round(promedio, 1) if promedio else None,
            'total_notas': total_notas,
            'aprobado': aprobado,
        })

    total_aprobadas = sum(1 for m in materias_plan if m['aprobado'])
    total_materias = len(materias_plan)

    return render(request, 'academico/plan_estudios.html', {
        'materias_plan': materias_plan,
        'grupo': grupo,
        'total_aprobadas': total_aprobadas,
        'total_materias': total_materias,
        'porcentaje_avance': round(total_aprobadas / total_materias * 100) if total_materias else 0,
    })
