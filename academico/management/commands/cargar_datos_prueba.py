import random
from datetime import date
from calendar import monthrange
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from academico.models import Grado, Grupo, Materia, Asignacion, Inscripcion
from asistencias.models import Asistencia
from calificaciones.models import Periodo, Calificacion

Usuario = get_user_model()

PROFESORES = [
    ('CAR0001', 'Carlos', 'García Mendoza', 'carlos.garcia'),
    ('MAR0002', 'María', 'López Torres', 'maria.lopez'),
    ('JOS0003', 'José', 'Ramírez Flores', 'jose.ramirez'),
    ('ANA0004', 'Ana', 'Martínez Ríos', 'ana.martinez'),
    ('LUI0005', 'Luis', 'Hernández Paredes', 'luis.hernandez'),
]

ALUMNOS = [
    ('AL001', 'Sofía', 'Mendoza Torres', 'sofia.mendoza'),
    ('AL002', 'Mateo', 'García López', 'mateo.garcia'),
    ('AL003', 'Valentina', 'Ramírez Martínez', 'valentina.ramirez'),
    ('AL004', 'Santiago', 'López Hernández', 'santiago.lopez'),
    ('AL005', 'Isabella', 'Torres Flores', 'isabella.torres'),
    ('AL006', 'Sebastián', 'Flores Ríos', 'sebastian.flores'),
    ('AL007', 'Camila', 'Paredes García', 'camila.paredes'),
    ('AL008', 'Benjamín', 'Ríos Mendoza', 'benjamin.rios'),
    ('AL009', 'Luciana', 'Mendoza López', 'luciana.mendoza'),
    ('AL010', 'Emilio', 'Torres García', 'emilio.torres'),
    ('AL011', 'Emma', 'García Flores', 'emma.garcia'),
    ('AL012', 'Joaquín', 'López Ramírez', 'joaquin.lopez'),
]

class Command(BaseCommand):
    help = 'Carga datos de prueba: profesores, alumnos, grupos, asignaciones, asistencias y calificaciones'

    def handle(self, *args, **options):
        periodos = self._crear_periodos()
        self._crear_grupos()
        profes = self._crear_profesores()
        alumnos = self._crear_alumnos()
        grupos = list(Grupo.objects.all())
        asignaciones = self._crear_asignaciones(profes, grupos)
        inscripciones = self._crear_inscripciones(alumnos, grupos)
        self._crear_asistencias(inscripciones, asignaciones)
        self._crear_calificaciones(inscripciones, asignaciones, periodos)
        self._crear_admin_si_no_existe()
        self.stdout.write(self.style.SUCCESS('\nDatos de prueba cargados exitosamente.'))

    def _crear_periodos(self):
        year = 2026
        periodos = [
            ('Primer Bimestre', date(year, 3, 1), date(year, 4, 30)),
            ('Segundo Bimestre', date(year, 5, 1), date(year, 6, 30)),
            ('Tercer Bimestre', date(year, 8, 1), date(year, 9, 30)),
            ('Cuarto Bimestre', date(year, 10, 1), date(year, 12, 15)),
        ]
        creados = []
        for nombre, inicio, fin in periodos:
            p, _ = Periodo.objects.get_or_create(
                nombre=f'{nombre} {year}',
                defaults={'fecha_inicio': inicio, 'fecha_fin': fin},
            )
            if _:
                self.stdout.write(f'  OK Periodo: {p.nombre}')
            creados.append(p)
        return creados

    def _crear_grupos(self):
        count = 0
        for grado in Grado.objects.all():
            for letra in ['A', 'B']:
                g, created = Grupo.objects.get_or_create(nombre=letra, grado=grado)
                if created:
                    count += 1
        if count:
            self.stdout.write(f'  OK {count} grupos creados')

    def _crear_profesores(self):
        users = []
        for cod, nom, ape, user in PROFESORES:
            u, created = Usuario.objects.get_or_create(
                username=user,
                defaults={
                    'first_name': nom, 'last_name': ape,
                    'email': f'{user}@valdelomar.edu.pe',
                    'rol': 'profesor', 'telefono': f'999{random.randint(100000, 999999)}',
                },
            )
            if created:
                u.set_password('profesor123')
                u.save()
                self.stdout.write(f'  OK Profesor: {u.get_full_name()} ({user}/profesor123)')
            users.append(u)
        return users

    def _crear_alumnos(self):
        users = []
        for cod, nom, ape, user in ALUMNOS:
            u, created = Usuario.objects.get_or_create(
                username=user,
                defaults={
                    'first_name': nom, 'last_name': ape,
                    'email': f'{user}@estudiante.edu.pe',
                    'rol': 'alumno', 'telefono': f'9{random.randint(10000000, 99999999)}',
                },
            )
            if created:
                u.set_password('123456')
                u.save()
                self.stdout.write(f'  OK Alumno: {u.get_full_name()} ({user}/123456)')
            users.append(u)
        return users

    def _crear_asignaciones(self, profesores, grupos):
        asignaciones = []
        count = 0
        for grupo in grupos:
            for materia in Materia.objects.filter(grado=grupo.grado):
                a, created = Asignacion.objects.get_or_create(
                    profesor=random.choice(profesores), materia=materia, grupo=grupo,
                )
                if created:
                    count += 1
                asignaciones.append(a)
        self.stdout.write(f'  OK {count} asignaciones creadas (total: {len(asignaciones)})')
        return asignaciones

    def _crear_inscripciones(self, alumnos, grupos):
        count = 0
        grupos_list = list(set(grupos))
        for i, alumno in enumerate(alumnos):
            g = grupos_list[i % len(grupos_list)]
            ins, created = Inscripcion.objects.get_or_create(alumno=alumno, grupo=g, defaults={'activo': True})
            if created:
                count += 1
        inscripciones = list(Inscripcion.objects.all())
        self.stdout.write(f'  OK {count} inscripciones creadas (total: {len(inscripciones)})')
        return inscripciones

    def _crear_asistencias(self, inscripciones, asignaciones):
        estados = ['presente', 'presente', 'presente', 'presente', 'tarde', 'falta']
        admin = Usuario.objects.filter(rol='admin').first()
        ins_ids = {i.id for i in inscripciones}
        asig_por_grupo = {}
        for a in asignaciones:
            asig_por_grupo.setdefault(a.grupo_id, []).append(a)

        objs = []
        for ins in inscripciones:
            for mes in range(3, 7):
                _, dias = monthrange(2026, mes)
                for dia in [5, 15, 25]:
                    if dia > dias: continue
                    fecha = date(2026, mes, dia)
                    if fecha.weekday() >= 5: continue
                    for asig in asig_por_grupo.get(ins.grupo_id, [])[:2]:
                        objs.append(Asistencia(
                            usuario_id=ins.alumno_id, fecha=fecha, materia_id=asig.materia_id,
                            estado=random.choice(estados), registrado_por=admin,
                        ))

        Asistencia.objects.bulk_create(objs, ignore_conflicts=True)
        self.stdout.write(f'  OK {len(objs)} asistencias registradas')

    def _crear_calificaciones(self, inscripciones, asignaciones, periodos):
        admin = Usuario.objects.filter(rol='admin').first()
        asig_por_grupo = {}
        for a in asignaciones:
            asig_por_grupo.setdefault(a.grupo_id, []).append(a)

        objs = []
        for ins in inscripciones:
            for asig in asig_por_grupo.get(ins.grupo_id, []):
                for p in periodos:
                    nota = round(random.uniform(5, 20), 2)
                    obs = None
                    if nota < 8: obs = 'Requiere apoyo adicional'
                    elif nota >= 18: obs = 'Excelente desempeño'
                    elif nota >= 14: obs = 'Buen rendimiento'
                    objs.append(Calificacion(
                        alumno_id=ins.alumno_id, materia_id=asig.materia_id, periodo=p,
                        nota=nota, observaciones=obs, registrado_por=admin,
                    ))

        Calificacion.objects.bulk_create(objs, ignore_conflicts=True)
        self.stdout.write(f'  OK {len(objs)} calificaciones registradas')

    def _crear_admin_si_no_existe(self):
        if not Usuario.objects.filter(username='admin').exists():
            Usuario.objects.create_superuser('admin', 'admin@valdelomar.edu.pe', 'admin123', rol='admin')
            self.stdout.write('  OK Admin recreado')
