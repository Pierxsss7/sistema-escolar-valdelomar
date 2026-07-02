from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.admin.views.decorators import staff_member_required
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from .models import Grado, Grupo, Materia, Asignacion, Inscripcion
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
        materias_por_nivel[nivel] = Materia.objects.filter(grado__nivel=nivel).select_related('grado').order_by('grado__orden', 'nombre')
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
