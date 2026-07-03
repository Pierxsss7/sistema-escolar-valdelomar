"""
Agente Local ZKTeco
Conecta con el dispositivo biométrico ZKTeco por TCP/IP,
obtiene los marcajes de asistencia y los envía al servidor web.

Requisitos:
    pip install pyzk requests

Uso:
    python agente_zk.py --ip 192.168.1.100 --api-key MI_CLAVE_API
    python agente_zk.py --ip 192.168.1.100 --puerto 4370 --api-key MI_CLAVE_API --url https://tudominio.com
"""
import argparse
import json
import time
import logging
import sys
from datetime import datetime

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)],
)
log = logging.getLogger('agente_zk')


def conectar_zk(ip, puerto=4370, password=0, timeout=10):
    try:
        from zk import ZK
        conn = None
        zk = ZK(ip, port=puerto, timeout=timeout, password=password, force_udp=False)
        conn = zk.connect()
        log.info(f'Conectado a ZKTeco {ip}:{puerto}')
        return conn, zk
    except Exception as e:
        log.error(f'Error conectando a {ip}:{puerto} - {e}')
        return None, None


def obtener_marcajes(conn, ultimo_id=0):
    try:
        asistencias = conn.get_attendance()
        nuevos = [a for a in asistencias if a.uid > ultimo_id]
        return nuevos
    except Exception as e:
        log.error(f'Error obteniendo marcajes: {e}')
        return []


def enviar_al_servidor(eventos, api_key, url_servidor):
    payload = {
        'api_key': api_key,
        'eventos': [
            {
                'user_id': e.user_id,
                'timestamp': e.timestamp.isoformat(),
                'tipo': 'entrada',
            }
            for e in eventos
        ],
    }
    try:
        import requests
        resp = requests.post(
            f'{url_servidor}/biometrico/api/evento/',
            json=payload,
            timeout=15,
        )
        if resp.status_code == 200:
            data = resp.json()
            log.info(f'Enviados {len(eventos)} eventos - OK: {data.get("eventos_creados", 0)} creados')
            return True
        else:
            log.error(f'Error servidor: {resp.status_code} - {resp.text[:200]}')
            return False
    except ImportError:
        log.error('requests no instalado. pip install requests')
        return False
    except Exception as e:
        log.error(f'Error enviando al servidor: {e}')
        return False


def registrar_usuarios(conn, usuarios):
    for uid, nombre, user_id in usuarios:
        try:
            conn.set_user(uid=uid, name=nombre, user_id=str(user_id), password='')
            log.info(f'Usuario registrado: {nombre} (ID: {user_id})')
        except Exception as e:
            log.error(f'Error registrando usuario {nombre}: {e}')


def main():
    parser = argparse.ArgumentParser(description='Agente ZKTeco para asistencia biométrica')
    parser.add_argument('--ip', required=True, help='IP del dispositivo ZKTeco')
    parser.add_argument('--puerto', type=int, default=4370, help='Puerto TCP (4370)')
    parser.add_argument('--api-key', required=True, help='API Key del dispositivo en el servidor web')
    parser.add_argument('--url', default='https://lavish-smile-production-9681.up.railway.app', help='URL del servidor web')
    parser.add_argument('--intervalo', type=int, default=30, help='Segundos entre polls (30)')
    parser.add_argument('--password', type=int, default=0, help='Password del dispositivo (0 si no tiene)')
    args = parser.parse_args()

    log.info(f'Iniciando agente ZKTeco - {args.ip}:{args.puerto}')
    log.info(f'Servidor web: {args.url}')
    log.info(f'Intervalo: {args.intervalo}s')

    ultimo_id = 0
    while True:
        conn, zk = conectar_zk(args.ip, args.puerto, args.password)
        if conn:
            nuevos = obtener_marcajes(conn, ultimo_id)
            if nuevos:
                max_id = max(a.uid for a in nuevos)
                log.info(f'{len(nuevos)} nuevos marcajes (ultimo_id: {max_id})')
                if enviar_al_servidor(nuevos, args.api_key, args.url):
                    ultimo_id = max_id
            try:
                conn.disconnect()
            except Exception:
                pass
        time.sleep(args.intervalo)


if __name__ == '__main__':
    main()
