FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN groupadd --system siia && useradd --system --gid siia --home /app siia && \
    apt-get update && apt-get install -y --no-install-recommends \
      libpq5 curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# requirements.txt debe generarse desde el código real modernizado.
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY . .
RUN chown -R siia:siia /app
USER siia

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --retries=5 \
  CMD curl -fsS http://127.0.0.1:8000/healthz || exit 1

CMD ["gunicorn", "--config", "gunicorn.conf.py", "wsgi:app"]
