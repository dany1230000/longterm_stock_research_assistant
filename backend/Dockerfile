FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV 00631L_DATA_DIR=/data
ENV 00631L_DATA_PERSISTENCE_MODE=persistent
ENV 00631L_HOLDINGS_HISTORY_PATH=/data/00631l_holdings_history.jsonl
ENV 00631L_INTRADAY_NAV_HISTORY_PATH=/data/00631l_intraday_nav_history.jsonl
ENV 00631L_DAILY_CYCLE_STATUS_PATH=/data/00631l_daily_cycle_status.json
ENV 00631L_INTEGRITY_STATUS_PATH=/data/00631l_integrity_status.json
ENV 00631L_RESTORE_DRY_RUN_STATUS_PATH=/data/00631l_restore_dry_run_status.json
ENV 00631L_HISTORY_EXPORT_DIR=/data/exports
ENV 00631L_BACKUP_DIR=/data/backups
ENV 00631L_REPORT_DIR=/data/reports

WORKDIR /app

COPY backend/requirements.txt /app/backend/requirements.txt
RUN pip install --no-cache-dir -r /app/backend/requirements.txt

COPY backend /app/backend

RUN mkdir -p /data

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=5).read()"

CMD ["python", "-m", "uvicorn", "backend.app.main:app", "--host", "0.0.0.0", "--port", "8000"]
