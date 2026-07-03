from django.core.management.base import BaseCommand
from django.conf import settings
import subprocess
import sys
import os


class Command(BaseCommand):
    help = 'Ejecuta el agente ZKTeco para conectar con el dispositivo biométrico'

    def add_arguments(self, parser):
        parser.add_argument('--ip', required=True, help='IP del dispositivo ZKTeco')
        parser.add_argument('--puerto', type=int, default=4370)
        parser.add_argument('--api-key', required=True, help='API Key del dispositivo')
        parser.add_argument('--intervalo', type=int, default=30)

    def handle(self, *args, **options):
        script = os.path.join(settings.BASE_DIR, 'agente_zk.py')
        cmd = [
            sys.executable, script,
            '--ip', options['ip'],
            '--puerto', str(options['puerto']),
            '--api-key', options['api_key'],
            '--intervalo', str(options['intervalo']),
            '--url', f"{'https' if settings.SECURE_SSL_REDIRECT else 'http'}://{settings.ALLOWED_HOSTS[0] if settings.ALLOWED_HOSTS else 'localhost:8000'}",
        ]
        self.stdout.write(f'Ejecutando: {" ".join(cmd)}')
        subprocess.run(cmd)
