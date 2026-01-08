#!/bin/bash
echo "Starting Recc Engine on 0.0.0.0:8000..."
echo "Access from other devices at: http://192.168.0.37:8000"
.venv/bin/uvicorn app:app --host 0.0.0.0 --port 8000 --reload
