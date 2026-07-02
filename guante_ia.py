import argparse
import asyncio
import math
import os
import queue
import struct
import subprocess
import sys
import tempfile
import threading
import time
import unicodedata
from collections import Counter, deque
from dataclasses import dataclass
from typing import Deque, Dict, List, Optional, Tuple

import cv2
import mediapipe as mp

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    Image = None
    ImageDraw = None
    ImageFont = None

try:
    import serial
except ImportError:
    serial = None

try:
    from deep_translator import GoogleTranslator
except ImportError:
    GoogleTranslator = None

try:
    import speech_recognition as sr
except ImportError:
    sr = None

try:
    import pyttsx3
except ImportError:
    pyttsx3 = None

try:
    import edge_tts
except ImportError:
    edge_tts = None

try:
    from playsound import playsound
except ImportError:
    playsound = None

try:
    import pvporcupine
except ImportError:
    pvporcupine = None

try:
    import pyaudio
except ImportError:
    pyaudio = None


# ============================================================
# GUANTE IA - DETECTOR DE GESTOS CON CAMARA + ARDUINO OPCIONAL
# ============================================================

mp_hands = mp.solutions.hands
mp_draw = mp.solutions.drawing_utils


LANGUAGES: List[Tuple[str, str]] = [
    ("es", "Español"), ("en", "English"), ("fr", "Français"),
    ("pt", "Português"), ("it", "Italiano"), ("de", "Deutsch"), ("ja", "Japonés"),
]

VOICE_SOURCE_SPEECH = "es-ES"
VOICE_SOURCE_LANG = "es"
VOICE_TARGETS: List[Tuple[str, str]] = [
    ("en", "English"), ("fr", "Français"), ("pt", "Português"),
    ("it", "Italiano"), ("de", "Deutsch"), ("ja", "Japonés"),
]

EDGE_TTS_VOICES: Dict[str, str] = {
    "es": "es-ES-ElviraNeural", "en": "en-US-AriaNeural", "fr": "fr-FR-DeniseNeural",
    "pt": "pt-BR-FranciscaNeural", "it": "it-IT-ElsaNeural",
    "de": "de-DE-KatjaNeural", "ja": "ja-JP-NanamiNeural",
}

SIGN_SUGGESTIONS: Dict[str, str] = {
    "hola": "OPEN_HAND", "hello": "OPEN_HAND", "hi": "OPEN_HAND",
    "alto": "OPEN_HAND", "stop": "OPEN_HAND",
    "ok": "OK", "okay": "OK",
    "bien": "THUMBS_UP", "good": "THUMBS_UP", "yes": "THUMBS_UP", "si": "THUMBS_UP",
    "no": "THUMBS_DOWN", "bad": "THUMBS_DOWN", "mal": "THUMBS_DOWN",
    "paz": "PEACE", "peace": "PEACE", "victoria": "PEACE", "victory": "PEACE",
    "te quiero": "ILY", "i love you": "ILY", "love": "ILY", "amor": "ILY",
    "llamame": "LETTER_Y", "call me": "LETTER_Y",
    "senalar": "POINT", "señalar": "POINT", "point": "POINT",
}


@dataclass(frozen=True)
class Gesture:
    code: str
    text_es: str
    arduino_value: str


GESTURE_TEXTS: Dict[str, Gesture] = {
    "OK": Gesture("OK", "OK", "OK"),
    "FIST": Gesture("FIST", "Puño cerrado / Letra A aproximada", "FIST"),
    "OPEN_HAND": Gesture("OPEN_HAND", "Hola / Alto", "OPEN"),
    "LETTER_B": Gesture("LETTER_B", "Letra B aproximada", "B"),
    "LETTER_L": Gesture("LETTER_L", "Letra L aproximada", "L"),
    "LETTER_W": Gesture("LETTER_W", "Letra W aproximada", "W"),
    "LETTER_Y": Gesture("LETTER_Y", "Letra Y aproximada", "Y"),
    "POINT": Gesture("POINT", "Señalar", "POINT"),
    "PEACE": Gesture("PEACE", "Paz / Victoria", "PEACE"),
    "ROCK": Gesture("ROCK", "Rock / Cuernos", "ROCK"),
    "THUMBS_UP": Gesture("THUMBS_UP", "Pulgar arriba", "UP"),
    "THUMBS_DOWN": Gesture("THUMBS_DOWN", "Pulgar abajo", "DOWN"),
    "ILY": Gesture("ILY", "Te quiero", "ILY"),
    "CALL_ME": Gesture("CALL_ME", "Llámame", "CALL"),
    "UNKNOWN": Gesture("UNKNOWN", "Desconocido", "UNKNOWN"),
}


# Banco de palabras conversacionales para cada gesto (modo charla)
# Repetir el mismo gesto cicla a la siguiente palabra de la lista
GESTURE_WORDS: Dict[str, List[str]] = {
    "OK": ["ok", "vale", "listo", "de acuerdo"],
    "FIST": ["espera", "alto", "fuerte", "poder"],
    "OPEN_HAND": ["hola", "adiós", "alto", "pare"],
    "LETTER_B": ["b"],
    "LETTER_L": ["l"],
    "LETTER_W": ["w"],
    "LETTER_Y": ["y", "por qué"],
    "POINT": ["tú", "allí", "yo", "este"],
    "PEACE": ["paz", "victoria", "tranquilo"],
    "ROCK": ["genial", "fiesta", "divertido", "rock"],
    "THUMBS_UP": ["sí", "bien", "bueno", "vale"],
    "THUMBS_DOWN": ["no", "mal", "malo", "nunca"],
    "ILY": ["amor", "gracias", "te quiero", "familia"],
    "CALL_ME": ["llamar", "teléfono", "luego"],
    "UNKNOWN": [""],
}


GESTURE_TRANSLATIONS: Dict[str, Dict[str, str]] = {
    "es": {
        "OK": "OK", "FIST": "Puño cerrado / Letra A aproximada",
        "OPEN_HAND": "Hola / Alto", "LETTER_B": "Letra B aproximada",
        "LETTER_L": "Letra L aproximada", "LETTER_W": "Letra W aproximada",
        "LETTER_Y": "Letra Y aproximada", "POINT": "Señalar",
        "PEACE": "Paz / Victoria", "ROCK": "Rock / Cuernos",
        "THUMBS_UP": "Pulgar arriba", "THUMBS_DOWN": "Pulgar abajo",
        "ILY": "Te quiero", "CALL_ME": "Llámame", "UNKNOWN": "",
    },
    "en": {
        "OK": "OK", "FIST": "Closed fist / Approximate letter A",
        "OPEN_HAND": "Hello / Stop", "LETTER_B": "Approximate letter B",
        "LETTER_L": "Approximate letter L", "LETTER_W": "Approximate letter W",
        "LETTER_Y": "Approximate letter Y", "POINT": "Pointing",
        "PEACE": "Peace / Victory", "ROCK": "Rock / Horns",
        "THUMBS_UP": "Thumbs up", "THUMBS_DOWN": "Thumbs down",
        "ILY": "I love you", "CALL_ME": "Call me", "UNKNOWN": "",
    },
    "fr": {
        "OK": "OK", "FIST": "Poing fermé / Lettre A approximative",
        "OPEN_HAND": "Bonjour / Stop", "LETTER_B": "Lettre B approximative",
        "LETTER_L": "Lettre L approximative", "LETTER_W": "Lettre W approximative",
        "LETTER_Y": "Lettre Y approximative", "POINT": "Pointer",
        "PEACE": "Paix / Victoire", "ROCK": "Rock / Cornes",
        "THUMBS_UP": "Pouce levé", "THUMBS_DOWN": "Pouce baissé",
        "ILY": "Je t'aime", "CALL_ME": "Appelle-moi", "UNKNOWN": "",
    },
    "pt": {
        "OK": "OK", "FIST": "Punho fechado / Letra A aproximada",
        "OPEN_HAND": "Olá / Pare", "LETTER_B": "Letra B aproximada",
        "LETTER_L": "Letra L aproximada", "LETTER_W": "Letra W aproximada",
        "LETTER_Y": "Letra Y aproximada", "POINT": "Apontar",
        "PEACE": "Paz / Vitória", "ROCK": "Rock / Chifres",
        "THUMBS_UP": "Polegar para cima", "THUMBS_DOWN": "Polegar para baixo",
        "ILY": "Eu te amo", "CALL_ME": "Ligue para mim", "UNKNOWN": "",
    },
    "it": {
        "OK": "OK", "FIST": "Pugno chiuso / Lettera A approssimata",
        "OPEN_HAND": "Ciao / Stop", "LETTER_B": "Lettera B approssimata",
        "LETTER_L": "Lettera L approssimata", "LETTER_W": "Lettera W approssimata",
        "LETTER_Y": "Lettera Y approssimata", "POINT": "Indicare",
        "PEACE": "Pace / Vittoria", "ROCK": "Rock / Corna",
        "THUMBS_UP": "Pollice su", "THUMBS_DOWN": "Pollice giù",
        "ILY": "Ti voglio bene", "CALL_ME": "Chiamami", "UNKNOWN": "",
    },
    "de": {
        "OK": "OK", "FIST": "Geschlossene Faust / Ungefährer Buchstabe A",
        "OPEN_HAND": "Hallo / Stopp", "LETTER_B": "Ungefährer Buchstabe B",
        "LETTER_L": "Ungefährer Buchstabe L", "LETTER_W": "Ungefährer Buchstabe W",
        "LETTER_Y": "Ungefährer Buchstabe Y", "POINT": "Zeigen",
        "PEACE": "Frieden / Sieg", "ROCK": "Rock / Hörner",
        "THUMBS_UP": "Daumen hoch", "THUMBS_DOWN": "Daumen runter",
        "ILY": "Ich liebe dich", "CALL_ME": "Ruf mich an", "UNKNOWN": "",
    },
    "ja": {
        "OK": "OK", "FIST": "握りこぶし / Aの近似",
        "OPEN_HAND": "こんにちは / 止まれ", "LETTER_B": "Bの近似",
        "LETTER_L": "Lの近似", "LETTER_W": "Wの近似",
        "LETTER_Y": "Yの近似", "POINT": "指さし",
        "PEACE": "平和 / 勝利", "ROCK": "ロック / 角",
        "THUMBS_UP": "親指を上げる", "THUMBS_DOWN": "親指を下げる",
        "ILY": "愛してる", "CALL_ME": "電話して", "UNKNOWN": "",
    },
}


def ascii_safe(s: str) -> str:
    s = s or ""
    return unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode("ascii")


class TranslatorCache:
    def __init__(self, target_language: str):
        self.target_language = (target_language or "es").lower()
        self.cache: Dict[Tuple[str, str, str], str] = {}

    def set_language(self, target_language: str):
        self.target_language = (target_language or "es").lower()

    def translate_gesture(self, gesture: Gesture) -> str:
        translations = GESTURE_TRANSLATIONS.get(self.target_language, GESTURE_TRANSLATIONS["es"])
        return translations.get(gesture.code, gesture.text_es)

    def translate(self, text: str, source_language: str, target_language: str) -> str:
        if not text or source_language == target_language:
            return text
        key = (source_language, target_language, text)
        if key in self.cache:
            return self.cache[key]
        if GoogleTranslator is None:
            return text
        try:
            translated = GoogleTranslator(source=source_language, target=target_language).translate(text)
        except Exception:
            translated = text
        self.cache[key] = translated
        return translated


class ArduinoSender:
    def __init__(self, port: Optional[str], baud: int):
        self.connection = None
        self.last_sent: Optional[str] = None
        self.last_time = 0.0
        if not port:
            return
        if serial is None:
            print("pyserial no esta instalado. Instala con: pip install pyserial")
            return
        try:
            self.connection = serial.Serial(port, baud, timeout=1)
            time.sleep(2)
            try:
                self.connection.reset_input_buffer()
            except Exception:
                pass
            print(f"Arduino conectado en {port} a {baud} baudios.")
        except Exception as exc:
            print(f"No se pudo conectar con Arduino en {port}: {exc}")

    def send(self, value: str, min_interval_s: float = 0.08):
        if self.connection is None:
            return
        now = time.time()
        if value == self.last_sent and now - self.last_time < min_interval_s:
            return
        try:
            self.connection.write((value + "\n").encode("utf-8"))
            self.last_sent = value
            self.last_time = now
        except Exception as exc:
            print(f"Error enviando a Arduino: {exc}")

    def send_tft(self, text_line: str, gesture_value: str, suggestions: Optional[List[str]] = None):
        self.send("TXT:" + ascii_safe(text_line), min_interval_s=0.0)
        self.send("GST:" + ascii_safe(gesture_value), min_interval_s=0.0)
        if suggestions:
            self.send("SUG:" + ascii_safe("|".join(suggestions[:4])), min_interval_s=0.0)

    def close(self):
        if self.connection is not None:
            self.connection.close()


class VoiceTranslator:
    def __init__(self, translator: TranslatorCache):
        self.enabled = False
        self.target_index = 0
        self.last_original = ""
        self.last_translated = ""
        self.last_sign_suggestions: List[str] = []
        self.messages: "queue.Queue[Tuple[str, str, List[str]]]" = queue.Queue()
        self.stop_event = threading.Event()
        self.thread: Optional[threading.Thread] = None
        self.translator = translator
        self.recognizer = sr.Recognizer() if sr is not None else None
        self.tts_queue: "queue.Queue[Optional[str]]" = queue.Queue()
        self.tts_stop_event = threading.Event()
        self.tts_thread: Optional[threading.Thread] = None
        self._need_calibrate = True
        self.auto_speak = True
        self.new_voice_event = False
        self.last_translate_warning_time = 0.0
        if self.recognizer is not None:
            self.recognizer.dynamic_energy_threshold = True
            self.recognizer.pause_threshold = 0.7
            self.recognizer.non_speaking_duration = 0.4

    @property
    def target(self) -> Tuple[str, str]:
        return VOICE_TARGETS[self.target_index]

    @property
    def status_label(self) -> str:
        tgt_code, tgt_name = self.target
        return f"{VOICE_SOURCE_LANG.upper()}->{tgt_code.upper()} ({tgt_name})"

    def toggle_enabled(self):
        if sr is None:
            self.last_original = "Falta SpeechRecognition"
            self.last_translated = "Instala: pip install SpeechRecognition pyaudio"
            return
        self.enabled = not self.enabled
        if self.enabled:
            self._need_calibrate = True
        if self.thread is None:
            self.thread = threading.Thread(target=self._listen_loop, daemon=True)
            self.thread.start()
        if self.tts_thread is None:
            self.tts_thread = threading.Thread(target=self._tts_loop, daemon=True)
            self.tts_thread.start()

    def switch_target(self):
        self.target_index = (self.target_index + 1) % len(VOICE_TARGETS)

    def recalibrate(self):
        self._need_calibrate = True

    def update(self):
        self.new_voice_event = False
        while not self.messages.empty():
            original, translated, suggestions = self.messages.get_nowait()
            self.last_original = original
            self.last_translated = translated
            self.last_sign_suggestions = suggestions
            self.new_voice_event = True

    def speak_last_translation(self):
        if not self.last_translated:
            return
        self._enqueue_tts(self.last_translated)

    def close(self):
        self.stop_event.set()
        self.tts_stop_event.set()
        try:
            self.tts_queue.put_nowait(None)
        except Exception:
            pass

    def _enqueue_tts(self, text: str):
        text = (text or "").strip()
        if not text:
            return
        try:
            if self.tts_queue.qsize() > 3:
                return
        except Exception:
            pass
        self.tts_queue.put(text)

    def _tts_loop(self):
        is_windows = sys.platform.startswith("win")
        use_powershell = is_windows
        use_edge = edge_tts is not None and playsound is not None
        use_pyttsx3 = pyttsx3 is not None
        if not use_powershell and not use_edge and not use_pyttsx3:
            return

        def _ps_speak(text: str, lang_code: str):
            safe = (text or "").replace("'", "''")
            culture = {"es": "es-ES", "en": "en-US", "fr": "fr-FR", "pt": "pt-BR",
                       "it": "it-IT", "de": "de-DE", "ja": "ja-JP"}.get(lang_code, "es-ES")
            ps = (
                "Add-Type -AssemblyName System.Speech; "
                "$s = New-Object System.Speech.Synthesis.SpeechSynthesizer; "
                "try {{ $s.SelectVoiceByHints([System.Speech.Synthesis.VoiceGender]::NotSet,"
                "[System.Speech.Synthesis.VoiceAge]::NotSet,0,'{culture}'); }} catch {{ }}; "
                "$s.Speak('{safe}');"
            ).format(culture=culture, safe=safe)
            kwargs = {}
            if is_windows and hasattr(subprocess, "CREATE_NO_WINDOW"):
                kwargs["creationflags"] = subprocess.CREATE_NO_WINDOW
            subprocess.run(
                ["powershell", "-NoProfile", "-NonInteractive", "-Command", ps],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, **kwargs)
        while not self.tts_stop_event.is_set():
            try:
                text = self.tts_queue.get(timeout=0.2)
            except queue.Empty:
                continue
            if text is None:
                break
            try:
                tgt_code, _ = self.target
                if use_powershell:
                    _ps_speak(text, tgt_code)
                elif use_edge:
                    voice_name = EDGE_TTS_VOICES.get(tgt_code, EDGE_TTS_VOICES.get("es", "es-ES-ElviraNeural"))
                    with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as f:
                        out_path = f.name
                    async def _gen():
                        communicate = edge_tts.Communicate(text=text, voice=voice_name)
                        await communicate.save(out_path)
                    asyncio.run(_gen())
                    playsound(out_path)
                    try:
                        os.remove(out_path)
                    except Exception:
                        pass
                elif use_pyttsx3:
                    engine = pyttsx3.init()
                    engine.say(text)
                    engine.runAndWait()
                    engine.stop()
            except Exception:
                continue

    def _listen_loop(self):
        try:
            microphone = sr.Microphone()
        except Exception:
            self.messages.put(("Microfono no disponible", "Revisa microfono o instala pyaudio", []))
            return
        with microphone as source:
            while not self.stop_event.is_set():
                if not self.enabled:
                    time.sleep(0.1)
                    continue
                if self.recognizer is None:
                    time.sleep(0.2)
                    continue
                if self._need_calibrate:
                    try:
                        self.messages.put(("Calibrando...", "Silencio 1 segundo", []))
                        self.recognizer.adjust_for_ambient_noise(source, duration=1.0)
                    except Exception:
                        pass
                    self._need_calibrate = False
                try:
                    audio = self.recognizer.listen(source, timeout=1, phrase_time_limit=6)
                    text = self.recognizer.recognize_google(audio, language=VOICE_SOURCE_SPEECH)
                    tgt_code, _ = self.target
                    translated = self.translator.translate(text, VOICE_SOURCE_LANG, tgt_code)
                    if tgt_code != VOICE_SOURCE_LANG:
                        if translated.strip().lower() == (text or "").strip().lower():
                            now = time.time()
                            if now - self.last_translate_warning_time > 3.0:
                                if GoogleTranslator is None:
                                    self.messages.put(("Traduccion desactivada", "Instala: pip install deep-translator", []))
                                else:
                                    self.messages.put(("No se pudo traducir", "Revisa Internet o bloqueo de Google", []))
                                self.last_translate_warning_time = now
                    suggestions = suggest_signs(text + " " + translated)
                    self.messages.put((text, translated, suggestions))
                    if self.auto_speak:
                        self._enqueue_tts(translated)
                except sr.WaitTimeoutError:
                    continue
                except sr.UnknownValueError:
                    self.messages.put(("No entendi la voz", "Intenta hablar mas claro", []))
                except Exception as exc:
                    self.messages.put(("Error de voz", str(exc)[:80], []))
                    time.sleep(0.3)


class GestureStabilizer:
    def __init__(self, window_size: int = 12, min_repetitions: int = 8):
        self.history: Deque[str] = deque(maxlen=window_size)
        self.min_repetitions = min_repetitions
        self.stable_code: Optional[str] = None

    def update(self, gesture: Gesture) -> Optional[Gesture]:
        self.history.append(gesture.code)
        code, count = Counter(self.history).most_common(1)[0]
        if count >= self.min_repetitions:
            self.stable_code = None if code == "UNKNOWN" else code
        if self.stable_code is None:
            return None
        return GESTURE_TEXTS[self.stable_code]


def distance(p1, p2) -> float:
    return math.hypot(p1.x - p2.x, p1.y - p2.y)


def suggest_signs(text: str) -> List[str]:
    clean_text = (text or "").lower()
    suggestions: List[str] = []
    for word_or_phrase, gesture_code in SIGN_SUGGESTIONS.items():
        if word_or_phrase in clean_text and gesture_code not in suggestions:
            suggestions.append(gesture_code)
    return suggestions[:4]


def format_sign_suggestions(suggestions: List[str]) -> str:
    if not suggestions:
        return "-"
    names = []
    for code in suggestions:
        gesture = GESTURE_TEXTS.get(code)
        if gesture is not None:
            names.append(f"{code}: {gesture.text_es}")
    return " | ".join(names) if names else "-"


def get_font(size: int):
    if ImageFont is None:
        return None
    font_paths = ["C:/Windows/Fonts/arial.ttf", "C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/meiryo.ttc"]
    for path in font_paths:
        try:
            return ImageFont.truetype(path, size)
        except Exception:
            continue
    return ImageFont.load_default()


def np_array(image):
    import numpy as np
    return np.array(image)


def draw_text(frame, text: str, position: Tuple[int, int], font_size: int, color: Tuple[int, int, int]):
    if not text:
        return
    if Image is None or ImageDraw is None:
        safe = text.encode("ascii", "ignore").decode("ascii")
        cv2.putText(frame, safe, position, cv2.FONT_HERSHEY_SIMPLEX, font_size / 30, color, 2)
        return
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    image = Image.fromarray(rgb_frame)
    draw = ImageDraw.Draw(image)
    font = get_font(font_size)
    rgb_color = (color[2], color[1], color[0])
    draw.text(position, text, font=font, fill=rgb_color)
    frame[:, :] = cv2.cvtColor(np_array(image), cv2.COLOR_RGB2BGR)


def draw_label(frame, text: str, x: int, y: int):
    draw_text(frame, text, (max(10, x - 60), max(35, y - 35)), 24, (0, 255, 255))


def draw_panel(frame, lines: List[str], x: int, y: int):
    line_height = 24
    width = 760
    height = 18 + line_height * len(lines)
    overlay = frame.copy()
    cv2.rectangle(overlay, (x, y), (x + width, y + height), (20, 20, 20), -1)
    cv2.addWeighted(overlay, 0.65, frame, 0.35, 0, frame)
    for idx2, line in enumerate(lines):
        draw_text(frame, line[:95], (x + 12, y + 8 + idx2 * line_height), 16, (245, 245, 245))


def normalized_distance(hand_landmarks, idx1: int, idx2: int) -> float:
    lm = hand_landmarks.landmark
    palm_size = max(distance(lm[0], lm[9]), 0.05)
    return distance(lm[idx1], lm[idx2]) / palm_size


def get_finger_state(hand_landmarks, handedness_label: str) -> List[int]:
    lm = hand_landmarks.landmark
    fingers: List[int] = []
    thumb_tip = lm[4]
    thumb_ip = lm[3]
    thumb_margin = 0.02
    if handedness_label == "Right":
        fingers.append(1 if thumb_tip.x > thumb_ip.x + thumb_margin else 0)
    else:
        fingers.append(1 if thumb_tip.x < thumb_ip.x - thumb_margin else 0)
    finger_margin = 0.02
    for tip in (8, 12, 16, 20):
        fingers.append(1 if lm[tip].y < lm[tip - 2].y - finger_margin else 0)
    return fingers


def detect_gesture(hand_landmarks, handedness_label: str) -> Gesture:
    lm = hand_landmarks.landmark
    fingers = get_finger_state(hand_landmarks, handedness_label)
    total_open = sum(fingers)
    thumb_index_distance = normalized_distance(hand_landmarks, 4, 8)
    thumb_tip_y = lm[4].y
    thumb_mcp_y = lm[2].y
    thumb_vertical = abs(thumb_tip_y - thumb_mcp_y)
    if thumb_index_distance < 0.28 and fingers[2] and fingers[3] and fingers[4]:
        return GESTURE_TEXTS["OK"]
    if total_open == 0:
        return GESTURE_TEXTS["FIST"]
    if fingers == [0, 1, 1, 1, 1]:
        return GESTURE_TEXTS["LETTER_B"]
    if total_open == 5:
        return GESTURE_TEXTS["OPEN_HAND"]
    if fingers == [1, 1, 0, 0, 0]:
        return GESTURE_TEXTS["LETTER_L"]
    if fingers == [0, 1, 1, 1, 0]:
        return GESTURE_TEXTS["LETTER_W"]
    if fingers == [1, 0, 0, 0, 1]:
        return GESTURE_TEXTS["LETTER_Y"]
    if fingers in ([0, 1, 0, 0, 0], [1, 1, 0, 0, 0]):
        return GESTURE_TEXTS["POINT"]
    if fingers in ([0, 1, 1, 0, 0], [1, 1, 1, 0, 0]):
        return GESTURE_TEXTS["PEACE"]
    if fingers in ([0, 1, 0, 0, 1], [1, 1, 0, 0, 1]):
        return GESTURE_TEXTS["ROCK"]
    if fingers == [1, 0, 0, 0, 0] and thumb_vertical > 0.05:
        if thumb_tip_y < thumb_mcp_y:
            return GESTURE_TEXTS["THUMBS_UP"]
        return GESTURE_TEXTS["THUMBS_DOWN"]
    if fingers == [1, 1, 0, 0, 1]:
        return GESTURE_TEXTS["ILY"]
    return GESTURE_TEXTS["UNKNOWN"]


# ============================================================
# FRASE BUILDER - Constructor de frases por gestos
# ============================================================

@dataclass
class GestureEntry:
    gesture: Gesture
    translated_text: str
    timestamp: float


class FraseBuilder:
    def __init__(self, word_timeout: float = 1.5):
        self.word_timeout = word_timeout
        self.current_word: List[GestureEntry] = []
        self.sentence_words: List[str] = []
        self.enabled = True
        self.last_add_time = 0.0
        self.chat_mode = True
        self.word_cycles: Dict[str, int] = {}

    def add_gesture(self, gesture: Gesture, translated_text: str):
        if not self.enabled:
            return
        now = time.time()
        self.last_add_time = now

        if gesture.code == "OPEN_HAND":
            self._commit_word()
            return

        if gesture.code == "FIST":
            if self.current_word:
                self._commit_word()
            self.sentence_words.append("")
            return

        if self.current_word:
            last_ts = self.current_word[-1].timestamp
            if now - last_ts > self.word_timeout:
                self._commit_word()

        if self.chat_mode and self.current_word and self.current_word[-1].gesture.code == gesture.code and (now - self.current_word[-1].timestamp) < 1.0:
            idx = self.word_cycles.get(gesture.code, 0)
            words = GESTURE_WORDS.get(gesture.code, [translated_text])
            idx = (idx + 1) % len(words)
            self.word_cycles[gesture.code] = idx
            new_text = words[idx]
            self.current_word[-1] = GestureEntry(gesture, new_text, now)
            return

        code_same = self.current_word and self.current_word[-1].gesture.code == gesture.code
        if not code_same:
            if self.chat_mode:
                idx = self.word_cycles.get(gesture.code, 0)
                words = GESTURE_WORDS.get(gesture.code, [translated_text])
                display_text = words[idx]
            else:
                display_text = translated_text
            self.current_word.append(GestureEntry(gesture, display_text, now))

    def _commit_word(self):
        if not self.current_word:
            return
        word = self.current_word[-1].translated_text
        if word:
            self.sentence_words.append(word)
        self.current_word.clear()

    def get_current_word(self) -> str:
        if not self.current_word:
            return ""
        return self.current_word[-1].translated_text

    def get_sentence(self) -> str:
        parts = [w for w in self.sentence_words if w]
        return " ".join(parts)

    def clear_sentence(self):
        self.sentence_words.clear()
        self.current_word.clear()
        self.word_cycles.clear()

    def remove_last_word(self):
        if self.sentence_words:
            self.sentence_words.pop()

    def get_gesture_sequence(self) -> List[str]:
        seq = [e.gesture.code for e in self.current_word]
        for w in self.sentence_words:
            if w:
                seq.append(f"[{w}]")
        return seq


# ============================================================
# HOTWORD ACTIVATOR - Activacion por palabra clave
# ============================================================

class HotwordActivator:
    def __init__(
        self,
        voice: "VoiceTranslator",
        keywords: Optional[List[str]] = None,
        listen_window: float = 5.0,
        porcupine_access_key: str = "",
        porcupine_keyword_path: str = "",
    ):
        self.voice = voice
        self.keywords = keywords or ["guante", "hola guante"]
        self.listen_window = listen_window
        self.mode = "off"
        self.last_detection = 0.0
        self._active_until = 0.0
        self.stop_event = threading.Event()
        self.thread: Optional[threading.Thread] = None
        self.porcupine_instance = None
        self.audio_stream = None
        self.py_audio = None
        self.engine_ready = False
        self._init_engine(porcupine_access_key, porcupine_keyword_path)

    def _init_engine(self, access_key: str, keyword_path: str):
        if pvporcupine is not None and pyaudio is not None:
            try:
                if keyword_path and os.path.isfile(keyword_path):
                    self.porcupine_instance = pvporcupine.create(
                        access_key=access_key, keyword_paths=[keyword_path])
                elif access_key:
                    self.porcupine_instance = pvporcupine.create(
                        access_key=access_key, keywords=["computer", "terminator"])
                if self.porcupine_instance is not None:
                    self.py_audio = pyaudio.PyAudio()
                    self.audio_stream = self.py_audio.open(
                        rate=self.porcupine_instance.sample_rate, channels=1,
                        format=pyaudio.paInt16, input=True,
                        frames_per_buffer=self.porcupine_instance.frame_length)
                    self.mode = "porcupine"
                    self.engine_ready = True
                    return
            except Exception:
                pass
        if sr is not None:
            self.mode = "sr"
            self.engine_ready = True

    @property
    def is_active(self) -> bool:
        return time.time() < self._active_until

    @property
    def status_label(self) -> str:
        parts = []
        if self.engine_ready:
            parts.append(self.mode.upper())
            parts.append("ACTIVO" if self.is_active else "INACTIVO")
        else:
            parts.append("NO DISPONIBLE")
        return " | ".join(parts)

    def start(self):
        if not self.engine_ready:
            return
        self.stop_event.clear()
        self.thread = threading.Thread(target=self._loop, daemon=True)
        self.thread.start()
        mode_name = "Porcupine" if self.mode == "porcupine" else "SR"
        print(f"Hotword {mode_name} ON - di 'guante' para activar microfono")

    def stop(self):
        self.stop_event.set()
        if self.audio_stream is not None:
            try: self.audio_stream.close()
            except Exception: pass
        if self.py_audio is not None:
            try: self.py_audio.terminate()
            except Exception: pass
        if self.porcupine_instance is not None:
            try: self.porcupine_instance.delete()
            except Exception: pass

    def _loop(self):
        if self.mode == "porcupine":
            self._loop_porcupine()
        elif self.mode == "sr":
            self._loop_sr()

    def _loop_porcupine(self):
        while not self.stop_event.is_set():
            try:
                pcm = self.audio_stream.read(self.porcupine_instance.frame_length)
                audio_frame = struct.unpack_from("h" * self.porcupine_instance.frame_length, pcm)
                kw_index = self.porcupine_instance.process(audio_frame)
                if kw_index >= 0:
                    self._on_hotword()
            except Exception:
                continue

    def _loop_sr(self):
        import speech_recognition as _sr
        recognizer = _sr.Recognizer()
        recognizer.energy_threshold = 1000
        recognizer.pause_threshold = 0.3
        recognizer.non_speaking_duration = 0.2
        try:
            mic = _sr.Microphone()
            with mic as source:
                recognizer.adjust_for_ambient_noise(source, duration=0.5)
                while not self.stop_event.is_set():
                    try:
                        audio = recognizer.listen(source, timeout=0.5, phrase_time_limit=2)
                        text = recognizer.recognize_google(audio, language="es-ES")
                        for kw in self.keywords:
                            if kw.lower() in (text or "").lower():
                                self._on_hotword()
                                break
                    except _sr.WaitTimeoutError:
                        continue
                    except _sr.UnknownValueError:
                        continue
                    except Exception:
                        continue
        except Exception:
            pass

    def _on_hotword(self):
        self.last_detection = time.time()
        self._active_until = time.time() + self.listen_window
        if self.voice is not None:
            self.voice.enabled = True
            self.voice._need_calibrate = True


def parse_args():
    parser = argparse.ArgumentParser(description="Detector de gestos con MediaPipe y Arduino opcional.")
    parser.add_argument("--camera", type=int, default=0, help="Numero de camara. Por defecto: 0")
    parser.add_argument("--lang", default="es", help="Idioma del texto de senas: es, en, fr, pt, it, de, ja.")
    parser.add_argument("--arduino", default=None, help="Puerto Arduino. Ejemplo Windows: COM3")
    parser.add_argument("--baud", type=int, default=9600, help="Baudios del Arduino. Por defecto: 9600")
    parser.add_argument("--porcupine-key", default="",
                        help="Access key de Picovoice Porcupine (free en picovoice.ai)")
    parser.add_argument("--porcupine-keyword", default="",
                        help="Ruta al archivo .ppn de palabra clave personalizada")
    parser.add_argument("--hotword-window", type=float, default=5.0,
                        help="Segundos que el microfono queda activo tras hotword (default: 5)")
    return parser.parse_args()


def main():
    args = parse_args()
    translator = TranslatorCache(args.lang)
    arduino = ArduinoSender(args.arduino, args.baud)
    voice = VoiceTranslator(translator)
    frase_builder = FraseBuilder(word_timeout=1.5)
    hotword = HotwordActivator(
        voice=voice, listen_window=args.hotword_window,
        porcupine_access_key=args.porcupine_key,
        porcupine_keyword_path=args.porcupine_keyword)

    language_index = next((i for i, item in enumerate(LANGUAGES) if item[0] == args.lang), 0)
    current_language, current_language_name = LANGUAGES[language_index]
    translator.set_language(current_language)

    stabilizers: Dict[int, GestureStabilizer] = {}
    hotword_mode = False

    cap = cv2.VideoCapture(args.camera)
    if not cap.isOpened():
        print("No se pudo abrir la camara.")
        return

    hands = mp_hands.Hands(
        static_image_mode=False, max_num_hands=2, model_complexity=1,
        min_detection_confidence=0.7, min_tracking_confidence=0.7)

    print("Camara iniciada. Presiona 'q' para salir.")
    print("  [i] idioma senas  [v] microfono  [t] voz destino")
    print("  [c] calibrar micro  [s] altavoz ultima traduccion")
    print("  [m] CHARLA/TEXTO  [f] frase ON/OFF  [x] limpiar  [z] borrar palabra")
    print("  [h] hotword mode ON/OFF")

    last_sent_gesture: Optional[str] = None
    last_sent_time = 0.0
    last_voice_sent = ""
    last_voice_sent_time = 0.0
    last_frase_sent = ""
    last_frase_arduino_time = 0.0
    hotword_was_active = False

    try:
        while True:
            success, frame = cap.read()
            if not success:
                print("No se pudo leer la imagen de la camara.")
                break
            frame = cv2.flip(frame, 1)
            height, width, _ = frame.shape
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = hands.process(rgb)
            voice.update()

            if hotword_mode and hotword.engine_ready:
                now_hw = time.time()
                if hotword.is_active:
                    voice.enabled = True
                    hotword_was_active = True
                elif hotword_was_active:
                    voice.enabled = False
                    hotword_was_active = False
                    voice._need_calibrate = True

            if voice.new_voice_event and voice.last_original and voice.last_translated:
                now = time.time()
                combo = f"{voice.last_original} -> {voice.last_translated}"
                if combo != last_voice_sent or (now - last_voice_sent_time) > 1.0:
                    arduino.send_tft(text_line=combo, gesture_value="VOICE", suggestions=voice.last_sign_suggestions)
                    last_voice_sent = combo
                    last_voice_sent_time = now

            current_gesture_for_ui: Optional[Tuple[int, Gesture, str]] = None
            if results.multi_hand_landmarks:
                handedness_list = results.multi_handedness or []
                for idx_hand, hand_landmarks in enumerate(results.multi_hand_landmarks):
                    handedness = "Right"
                    if idx_hand < len(handedness_list):
                        handedness = handedness_list[idx_hand].classification[0].label
                    raw_gesture = detect_gesture(hand_landmarks, handedness)
                    stabilizer = stabilizers.setdefault(idx_hand, GestureStabilizer())
                    gesture = stabilizer.update(raw_gesture)
                    mp_draw.draw_landmarks(frame, hand_landmarks, mp_hands.HAND_CONNECTIONS,
                        mp_draw.DrawingSpec(color=(0, 255, 0), thickness=2, circle_radius=4),
                        mp_draw.DrawingSpec(color=(255, 0, 0), thickness=2, circle_radius=2))
                    if gesture is not None:
                        translated_text = translator.translate_gesture(gesture)
                        if frase_builder.chat_mode:
                            words = GESTURE_WORDS.get(gesture.code, [translated_text])
                            idx = frase_builder.word_cycles.get(gesture.code, 0)
                            label_text = words[idx] if idx < len(words) else translated_text
                        else:
                            label_text = translated_text
                        x = int(hand_landmarks.landmark[0].x * width)
                        y = int(hand_landmarks.landmark[0].y * height)
                        draw_label(frame, f"Mano {idx_hand + 1}: {label_text}", x, y)
                        frase_builder.add_gesture(gesture, translated_text)
                        if current_gesture_for_ui is None:
                            current_gesture_for_ui = (idx_hand, gesture, label_text)

            frase_completa = frase_builder.get_sentence()
            now = time.time()

            if frase_builder.chat_mode and frase_completa and current_gesture_for_ui is not None:
                current_word = frase_builder.get_current_word()
                display_text = f"{frase_completa}"
                if current_word and (not frase_completa.endswith(current_word)):
                    display_text = f"{frase_completa} [{current_word}]"
                if display_text != last_frase_sent or (now - last_frase_arduino_time) > 0.8:
                    arduino.send_tft(text_line=display_text[-80:], gesture_value="DIALOG",
                                     suggestions=[])
                    last_frase_sent = display_text
                    last_frase_arduino_time = now
            elif current_gesture_for_ui is not None:
                _, g, label_text = current_gesture_for_ui
                if g.arduino_value != last_sent_gesture or (now - last_sent_time) > 0.5:
                    arduino.send_tft(text_line=label_text, gesture_value=g.arduino_value,
                                     suggestions=voice.last_sign_suggestions)
                    last_sent_gesture = g.arduino_value
                    last_sent_time = now

            chat_label = "CHARLA" if frase_builder.chat_mode else "TEXTO"
            draw_text(frame, "GUANTE IA - Gestos + Voz + Frases + IA", (10, 12), 22, (255, 255, 255))
            draw_text(frame,
                "i senas | v micro | t voz | c cal | s voz | m modo | f frase | z borrar | x limp | h hotword | q salir",
                (10, 40), 14, (200, 200, 200))

            voice_status = "ON" if voice.enabled else "OFF"
            hw_status = f"HOTWORD:{hotword.status_label}" if hotword_mode else "HOTWORD:OFF"
            frase_en = "ON" if frase_builder.enabled else "OFF"
            current_word = frase_builder.get_current_word()
            panel_lines = [
                f"Micro: {voice_status} | Voz: {voice.status_label} | {hw_status}",
                f"FraseBuilder: {frase_en} | Modo: {chat_label}",
                f"Gesto actual: {current_word or '-'}",
                f"Frase: {frase_completa or '-'}",
                f"Escuchado: {voice.last_original or '-'}",
                f"Traducido: {voice.last_translated or '-'}",
                f"Sugerencias: {format_sign_suggestions(voice.last_sign_suggestions)}",
            ]

            draw_panel(frame, panel_lines, 10, height - 210)
            cv2.imshow("GUANTE IA", frame)
            key = cv2.waitKey(1) & 0xFF
            if key == ord("q"):
                break
            if key == ord("i"):
                language_index = (language_index + 1) % len(LANGUAGES)
                current_language, current_language_name = LANGUAGES[language_index]
                translator.set_language(current_language)
                args.lang = current_language
                print(f"Idioma de senas cambiado a: {current_language_name} ({current_language})")
            if key == ord("v"):
                if hotword_mode and hotword.engine_ready:
                    hotword_mode = False
                    voice.enabled = not voice.enabled
                else:
                    voice.toggle_enabled()
                print(f"Microfono: {'activado' if voice.enabled else 'desactivado'}")
            if key == ord("t"):
                voice.switch_target()
                print(f"Traduccion de voz: {voice.status_label}")
            if key == ord("c"):
                voice.recalibrate()
                print("Recalibrando microfono... (silencio 1 segundo)")
            if key == ord("s"):
                voice.speak_last_translation()
            if key == ord("f"):
                frase_builder.enabled = not frase_builder.enabled
                print(f"FraseBuilder: {'ON' if frase_builder.enabled else 'OFF'}")
            if key == ord("x"):
                frase_builder.clear_sentence()
                print("Frase limpiada")
            if key == ord("z"):
                frase_builder.remove_last_word()
                print(f"Ultima palabra eliminada. Frase: {frase_builder.get_sentence()}")
            if key == ord("m"):
                frase_builder.chat_mode = not frase_builder.chat_mode
                frase_builder.word_cycles.clear()
                mode = "CHARLA" if frase_builder.chat_mode else "TEXTO"
                print(f"Modo: {mode} - CHARLA=palabras cortas, TEXTO=descripciones")
            if key == ord("h"):
                hotword_mode = not hotword_mode
                if hotword_mode:
                    if hotword.engine_ready:
                        hotword.start()
                        voice.enabled = False
                    else:
                        hotword_mode = False
                        print("Hotword no disponible. Instala: pip install pvporcupine pyaudio")
                else:
                    hotword.stop()
                    print("Hotword mode OFF")
    finally:
        hotword.stop()
        voice.close()
        hands.close()
        cap.release()
        arduino.close()
        cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
