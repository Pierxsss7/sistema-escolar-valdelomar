from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from django.contrib.auth import login, logout, authenticate
from django.views.decorators.csrf import ensure_csrf_cookie
from django.contrib import messages
from .models import Usuario, CredencialBiometrica
from .forms import RegistroForm


def cerrar_sesion(request):
    logout(request)
    return redirect('/')


@login_required
def registrar_huella(request):
    if request.method == 'POST':
        credential_id = request.POST.get('credential_id')
        public_key = request.POST.get('public_key')
        if credential_id and public_key:
            CredencialBiometrica.objects.create(
                usuario=request.user,
                credential_id=credential_id,
                public_key=public_key,
            )
            return redirect('home')
    return render(request, 'usuarios/registrar_huella.html')


def registrar(request):
    if request.method == 'POST':
        form = RegistroForm(request.POST)
        if form.is_valid():
            user = form.save()
            user.backend = 'django.contrib.auth.backends.ModelBackend'
            login(request, user)
            messages.success(request, f'Cuenta creada correctamente. ¡Bienvenido {user.first_name}!')
            return redirect('home')
    else:
        form = RegistroForm()
    return render(request, 'registration/registro.html', {'form': form})


@login_required
def perfil(request):
    if request.method == 'POST':
        user = request.user
        user.dni = request.POST.get('dni', '') or None
        user.telefono = request.POST.get('telefono', '') or None
        user.direccion = request.POST.get('direccion', '') or None
        user.especialidad = request.POST.get('especialidad', '') or None
        user.titulo_profesional = request.POST.get('titulo_profesional', '') or None
        fecha_nac = request.POST.get('fecha_nacimiento', '') or None
        if fecha_nac:
            from datetime import datetime
            try:
                user.fecha_nacimiento = datetime.strptime(fecha_nac, '%Y-%m-%d').date()
            except ValueError:
                pass
        if request.FILES.get('foto'):
            user.foto = request.FILES['foto']
        user.save()
        messages.success(request, 'Perfil actualizado correctamente.')
        return redirect('perfil')
    return render(request, 'usuarios/perfil.html')
