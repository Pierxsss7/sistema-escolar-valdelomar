@echo off
cd /d "C:\Users\ALEXANDER\Documents\OpenCode\ngrok"
cloudflared.exe tunnel --url http://localhost:8000 > tunnel_log.txt 2>&1
