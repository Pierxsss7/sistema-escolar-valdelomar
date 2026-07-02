from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.shortcuts import render
from django.contrib.auth.decorators import login_required
from django.contrib.auth import views as auth_views
from usuarios.models import Usuario
from django.db.models import Count
import json
from academico.models import Grado, Materia
from asistencias.models import Asistencia
from calificaciones.models import Calificacion


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
    calif_aprobadas = calificaciones.filter(nota__gte=70).count() if total_calif else 0
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
