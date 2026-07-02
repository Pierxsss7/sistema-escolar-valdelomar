from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from academico.models import Asignacion, Materia, Grupo
from usuarios.models import Usuario
from .models import Tarea


@login_required
def lista_tareas(request):
    if request.user.rol == 'profesor':
        tareas = Tarea.objects.filter(
            profesor=request.user
        ).select_related('materia', 'grupo', 'grupo__grado')
    elif request.user.rol in ('admin', 'director'):
        tareas = Tarea.objects.all().select_related('profesor', 'materia', 'grupo', 'grupo__grado')
    else:
        inscripciones = request.user.inscripciones.filter(activo=True)
        grupos_ids = inscripciones.values_list('grupo_id', flat=True)
        tareas = Tarea.objects.filter(
            grupo_id__in=grupos_ids, activo=True
        ).select_related('profesor', 'materia', 'grupo', 'grupo__grado')
    return render(request, 'tareas/lista_tareas.html', {'tareas': tareas})


@login_required
def crear_tarea(request):
    if request.user.rol not in ('profesor', 'admin', 'director'):
        messages.error(request, 'No tienes permiso para crear tareas.')
        return redirect('home')
    if request.user.rol == 'profesor':
        materias = Materia.objects.filter(asignaciones__profesor=request.user).distinct()
        grupos = Grupo.objects.filter(asignaciones__profesor=request.user).distinct()
    else:
        materias = Materia.objects.all()
        grupos = Grupo.objects.all()
    if request.method == 'POST':
        titulo = request.POST.get('titulo')
        descripcion = request.POST.get('descripcion', '')
        materia_id = request.POST.get('materia')
        grupo_id = request.POST.get('grupo')
        fecha_entrega = request.POST.get('fecha_entrega')
        archivo = request.FILES.get('archivo')
        if not all([titulo, materia_id, grupo_id, fecha_entrega]):
            messages.error(request, 'Completa todos los campos obligatorios.')
        else:
            if request.user.rol == 'profesor':
                profesor = request.user
            else:
                profesor_id = request.POST.get('profesor')
                if not profesor_id:
                    messages.error(request, 'Selecciona un profesor.')
                    return render(request, 'tareas/crear_tarea.html', {
                        'materias': materias, 'grupos': grupos, 'profesores': Usuario.objects.filter(rol='profesor'),
                    })
                profesor = get_object_or_404(Usuario, id=profesor_id, rol='profesor')
            Tarea.objects.create(
                titulo=titulo,
                descripcion=descripcion,
                archivo=archivo,
                fecha_entrega=fecha_entrega,
                profesor=profesor,
                materia_id=materia_id,
                grupo_id=grupo_id,
            )
            messages.success(request, 'Tarea creada correctamente.')
            return redirect('lista_tareas')
    return render(request, 'tareas/crear_tarea.html', {
        'materias': materias,
        'grupos': grupos,
        'profesores': Usuario.objects.filter(rol='profesor') if request.user.rol in ('admin', 'director') else [],
    })


@login_required
def editar_tarea(request, tarea_id):
    tarea = get_object_or_404(Tarea, id=tarea_id)
    if request.user.rol == 'profesor' and tarea.profesor != request.user:
        messages.error(request, 'No tienes permiso para editar esta tarea.')
        return redirect('lista_tareas')
    if request.method == 'POST':
        tarea.titulo = request.POST.get('titulo')
        tarea.descripcion = request.POST.get('descripcion', '')
        tarea.fecha_entrega = request.POST.get('fecha_entrega')
        if request.FILES.get('archivo'):
            tarea.archivo = request.FILES['archivo']
        tarea.save()
        messages.success(request, 'Tarea actualizada correctamente.')
        return redirect('lista_tareas')
    return render(request, 'tareas/editar_tarea.html', {'tarea': tarea})


@login_required
def eliminar_tarea(request, tarea_id):
    tarea = get_object_or_404(Tarea, id=tarea_id)
    if request.user.rol == 'profesor' and tarea.profesor != request.user:
        messages.error(request, 'No tienes permiso para eliminar esta tarea.')
    else:
        tarea.delete()
        messages.success(request, 'Tarea eliminada correctamente.')
    return redirect('lista_tareas')
