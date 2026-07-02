from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from django.contrib.auth import login, logout, authenticate
from django.views.decorators.csrf import ensure_csrf_cookie
from django.contrib import messages
from .models import CredencialBiometrica
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
