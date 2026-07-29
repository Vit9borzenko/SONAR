# PSIOP Analyzer Dockerfile
# Multi-stage build: зависимости + приложение

# ---- Build stage ----
FROM python:3.11-slim AS builder

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    POETRY_VERSION=1.8.0 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl && \
    rm -rf /var/lib/apt/lists/*

# Установка Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="$POETRY_HOME/bin:$PATH"

WORKDIR /app

# Копируем зависимости
COPY pyproject.toml ./
RUN poetry install --no-root --only main

# ---- Production stage ----
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Копируем виртуальное окружение из builder
COPY --from=builder /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# Копируем код приложения
COPY psiopyzer/ /app/psiopyzer/
COPY data/ /app/data/
COPY pyproject.toml /app/

# Директории для кэша и моделей
RUN mkdir -p /root/.psiopyzer/cache /root/.psiopyzer/models

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/healthcheck || exit 1

# Порт API
EXPOSE 8000

# Команда по умолчанию — FastAPI
CMD ["uvicorn", "psiopyzer.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]