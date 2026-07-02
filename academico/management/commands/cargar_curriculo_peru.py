from django.core.management.base import BaseCommand
from academico.models import Grado, Materia


CURRICULO = {
    'preescolar': {
        'grados': [
            {'nombre': '3 años', 'orden': 1},
            {'nombre': '4 años', 'orden': 2},
            {'nombre': '5 años', 'orden': 3},
        ],
        'materias': [
            'Comunicación',
            'Matemática',
            'Ciencia y Ambiente',
            'Personal Social',
            'Psicomotricidad',
            'Arte y Cultura',
            'Inglés',
            'Educación Religiosa',
        ],
    },
    'primaria': {
        'grados': [
            {'nombre': '1° Primaria', 'orden': 1},
            {'nombre': '2° Primaria', 'orden': 2},
            {'nombre': '3° Primaria', 'orden': 3},
            {'nombre': '4° Primaria', 'orden': 4},
            {'nombre': '5° Primaria', 'orden': 5},
            {'nombre': '6° Primaria', 'orden': 6},
        ],
        'materias': [
            'Comunicación',
            'Matemática',
            'Ciencia y Tecnología',
            'Personal Social',
            'Arte y Cultura',
            'Educación Física',
            'Inglés',
            'Educación Religiosa',
            'Tutoría',
        ],
    },
    'secundaria': {
        'grados': [
            {'nombre': '1° Secundaria', 'orden': 1},
            {'nombre': '2° Secundaria', 'orden': 2},
            {'nombre': '3° Secundaria', 'orden': 3},
            {'nombre': '4° Secundaria', 'orden': 4},
            {'nombre': '5° Secundaria', 'orden': 5},
        ],
        'materias': [
            'Comunicación',
            'Matemática',
            'Ciencia y Tecnología',
            'Ciencias Sociales',
            'Desarrollo Personal, Ciudadanía y Cívica',
            'Educación Física',
            'Arte y Cultura',
            'Inglés',
            'Educación Religiosa',
            'Educación para el Trabajo',
            'Tutoría',
        ],
    },
}


class Command(BaseCommand):
    help = 'Carga todo el currículo peruano: grados y materias por nivel'

    def handle(self, *args, **options):
        for nivel, datos in CURRICULO.items():
            self.stdout.write(f"\n=== {nivel.upper()} ===")

            for g in datos['grados']:
                grado, created = Grado.objects.get_or_create(
                    nombre=g['nombre'],
                    defaults={'nivel': nivel, 'orden': g['orden']},
                )
                if created:
                    self.stdout.write(f"  OK Grado: {grado.nombre}")

                for mat in datos['materias']:
                    materia, created = Materia.objects.get_or_create(
                        nombre=mat,
                        grado=grado,
                    )
                    if created:
                        self.stdout.write(f"    OK Materia: {materia.nombre}")

        self.stdout.write("\nCarga completada.")
