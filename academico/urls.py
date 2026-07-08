from django.urls import path
from . import views

urlpatterns = [
    path('grados/', views.lista_grados, name='lista_grados'),
    path('grados/crear/', views.crear_grado, name='crear_grado'),
    path('materias/', views.lista_materias, name='lista_materias'),
    path('materias/<int:grado_id>/', views.lista_materias, name='materias_por_grado'),
    path('grupos/', views.lista_grupos, name='lista_grupos'),
    path('asignaciones/', views.lista_asignaciones, name='lista_asignaciones'),
    path('grupos/<int:grupo_id>/alumnos/', views.alumnos_por_grupo, name='alumnos_por_grupo'),
    path('horarios/', views.lista_horarios, name='lista_horarios'),
    path('horarios/mis-horarios/', views.mis_horarios, name='mis_horarios'),
    path('horarios/crear/', views.crear_horario, name='crear_horario'),
    path('mis-cursos/', views.mis_cursos, name='mis_cursos'),
    path('plan-estudios/', views.plan_estudios, name='plan_estudios'),
]
