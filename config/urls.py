from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.shortcuts import render
from django.contrib.auth.decorators import login_required
from django.contrib.auth import views as auth_views
from usuarios.models import Usuario
from academico.models import Grado, Materia
from asistencias.models import Asistencia


@login_required
def home(request):
    context = {
        'total_alumnos': Usuario.objects.filter(rol='alumno').count(),
        'total_profesores': Usuario.objects.filter(rol='profesor').count(),
        'total_materias': Materia.objects.count(),
        'total_grados': Grado.objects.count(),
        'ultimas_asistencias': Asistencia.objects.select_related('usuario').order_by('-fecha', '-id')[:10],
    }
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
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
