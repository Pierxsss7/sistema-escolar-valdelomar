from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.admin.views.decorators import staff_member_required
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from .models import Grado, Grupo, Materia, Asignacion, Inscripcion, Horario, Anuncio
from usuarios.models import Usuario


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
