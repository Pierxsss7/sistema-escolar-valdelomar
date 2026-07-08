import datetime
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from academico.models import Asignacion, Grupo
from tareas.models import Tarea

Usuario = get_user_model()


class Command(BaseCommand):
    help = 'Crea tareas de ejemplo para los cursos asignados'

    def handle(self, *args, **options):
        tareas_creadas = 0

        grupos = Grupo.objects.all()
        for grupo in grupos:
            asignaciones = Asignacion.objects.filter(
                grupo=grupo
            ).select_related('materia', 'profesor')

            for asig in asignaciones:
                tareas_data = [
                    {
                        'titulo': f'Ejercarios de {asig.materia.nombre} - Unidad 1',
                        'descripcion': f'Resolver los ejercicios del capítulo 1 de {asig.materia.nombre}.',
                        'dias_entrega': 7,
                    },
                    {
                        'titulo': f'Investigación: Tema relevante de {asig.materia.nombre}',
                        'descripcion': f'Investigar y elaborar un ensayo sobre un tema de {asig.materia.nombre}.',
                        'dias_entrega': 14,
                    },
                    {
                        'titulo': f'Práctica evaluativa de {asig.materia.nombre}',
                        'descripcion': f'Realizar la práctica evaluativa correspondiente.',
                        'dias_entrega': 21,
                    },
                    {
                        'titulo': f'Tarea colaborativa: Proyecto de {asig.materia.nombre}',
                        'descripcion': f'Elaborar un proyecto en equipo sobre {asig.materia.nombre}.',
                        'dias_entrega': 30,
                    },
                    {
                        'titulo': f'Revisión de contenidos: {asig.materia.nombre}',
                        'descripcion': f'Estudiar y resumir los contenidos vistos en clase.',
                        'dias_entrega': 10,
                    },
                ]

                for td in tareas_data:
                    existe = Tarea.objects.filter(
                        titulo=td['titulo'],
                        materia=asig.materia,
                        grupo=grupo,
                    ).exists()

                    if not existe:
                        Tarea.objects.create(
                            titulo=td['titulo'],
                            descripcion=td['descripcion'],
                            fecha_entrega=datetime.date.today() + datetime.timedelta(days=td['dias_entrega']),
                            profesor=asig.profesor,
                            materia=asig.materia,
                            grupo=grupo,
                            activo=True,
                        )
                        tareas_creadas += 1

        self.stdout.write(self.style.SUCCESS(
            f'Se crearon {tareas_creadas} tareas de ejemplo.'
        ))
