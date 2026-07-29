<div align="center">

# 🔬 PSIOP Analyzer

**Система анализа музыкальных предпочтений пользователя из нескольких стриминговых платформ на предмет психологических индикаторов риска инсайдерских угроз.**

[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python&logoColor=white)](https://python.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Code style: black](https://img.shields.io/badge/Code%20Style-black-000000.svg)](https://github.com/psf/black)
[![Ruff](https://img.shields.io/badge/Linter-ruff-FCC624?logo=ruff)](https://github.com/astral-sh/ruff)
[![Poetry](https://img.shields.io/badge/Package%20Manager-Poetry-60A5FA?logo=poetry)](https://python-poetry.org)
[![FastAPI](https://img.shields.io/badge/API-FastAPI-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![CI](https://github.com/USERNAME/psiopyzer/actions/workflows/ci.yml/badge.svg)](https://github.com/USERNAME/psiopyzer/actions)

</div>

## 📋 Содержание

- [Описание](#описание)
- [Архитектура](#архитектура)
- [Быстрый старт](#быстрый-старт)
- [Установка](#установка)
- [Настройка API-ключей](#настройка-api-ключей)
- [Использование](#использование)
- [Метрики анализа](#метрики-анализа)
- [Модули проекта](#модули-проекта)
- [Тестирование](#тестирование)
- [CI/CD и качество кода](#cicd-и-качество-кода)
- [Docker](#docker)
- [Публикация на GitHub](#публикация-на-github)
- [Лицензия](#лицензия)
- [Предупреждение](#предупреждение)

## 🧠 Описание

PSIOP Analyzer анализирует музыкальные предпочтения пользователя из стриминговых платформ (Yandex Music, Spotify, Last.fm) и вычисляет психологические индикаторы риска инсайдерских угроз на основе:

- **Эмоционального профиля** — валентность, ароусал, энергия музыки (маппинг 75+ жанров)
- **Поведенческих паттернов** — ночная активность, волатильность жанров, зацикленность
- **Социальных индикаторов** — Shannon entropy разнообразия, индекс изоляции
- **ML-модели** — RandomForest / IsolationForest для классификации риска

## 🏗 Архитектура

```
psiopyzer/
├── psiopyzer/
│   ├── core/          # Базовые модели, конфигурация, исключения, перечисления
│   ├── adapters/      # Адаптеры для Yandex Music, Spotify, Last.fm
│   ├── analyzers/     # Анализаторы: эмоциональный, поведенческий, социальный, композитный
│   ├── ml/            # Feature engineering, ML-модели (RandomForest, IsolationForest), обучение
│   ├── reporters/     # Репортеры: JSON, HTML (Plotly), CLI (Rich)
│   ├── cli.py         # Typer CLI: analyze, train, report, list-platforms
│   └── main.py        # FastAPI entrypoint
├── data/              # genres_mapping.json, risk_thresholds.yaml
├── tests/             # pytest тесты
├── Dockerfile
├── docker-compose.yml
└── pyproject.toml
```

## 🚀 Быстрый старт

```bash
# 1. Клонировать
git clone https://github.com/USERNAME/psiopyzer.git
cd psiopyzer

# 2. Установить зависимости
poetry install

# 3. Скопировать и настроить .env
cp .env.example .env
# Отредактируйте .env, вставьте свои API-ключи

# 4. Запустить анализ
poetry run psiopyzer list-platforms
poetry run psiopyzer analyze --platform lastfm --user-id YOUR_USER --format cli

# 5. Или запустить API
poetry run uvicorn psiopyzer.main:app --reload
# → http://localhost:8000/docs
```

## 📦 Установка

### Локально (Poetry)

```bash
# Требования: Python 3.11+, Poetry 1.8+
poetry install
poetry shell
```

### Docker

```bash
docker compose up -d
docker compose run --rm psiopyzer-cli analyze --help
```

### Без Poetry (pip)

```bash
pip install -e .
```

## Настройка API-ключей

Создайте файл `.env` в корне проекта:

```env
# Yandex Music — токен из cookies (yandex_music_token)
YANDEX_MUSIC_TOKEN=ваш_токен

# Spotify — Client ID и Secret (https://developer.spotify.com/dashboard)
SPOTIFY_CLIENT_ID=ваш_client_id
SPOTIFY_CLIENT_SECRET=ваш_client_secret
SPOTIFY_REDIRECT_URI=http://localhost:8888/callback

# Last.fm — API ключ (https://www.last.fm/api/account/create)
LASTFM_API_KEY=ваш_api_key
LASTFM_API_SECRET=ваш_api_secret
```

### Где взять API-ключи:

- **Yandex Music**: получите токен из кук при входе в music.yandex.ru (через DevTools → Application → Cookies → `yandex_music_token`)
- **Spotify**: создайте приложение на https://developer.spotify.com/dashboard, получите Client ID и Client Secret
- **Last.fm**: создайте аккаунт на https://www.last.fm/api/account/create

## Использование

### CLI

```bash
# Анализ пользователя
psiopyzer analyze --platform spotify --user-id 31l4n5x --format cli
psiopyzer analyze --platform yandex --user-id myuserid --format html --output report.html
psiopyzer analyze --platform lastfm --user-id myuser --format json --output result.json --limit 200

# Обучение модели
psiopyzer train --dataset data/labeled.csv --model-out models/risk_model_v1.joblib

# Обучение без разметки (Isolation Forest)
psiopyzer train --dataset data/samples.csv --isolation-forest

# Генерация отчёта из JSON
psiopyzer report --input risk_report_user_123.json --format html

# Список доступных платформ
psiopyzer list-platforms
```

### Python API

```python
from psiopyzer.analyzers.composite import CompositeAnalyzer
from psiopyzer.core.models import Track

# Создаём анализатор
analyzer = CompositeAnalyzer()

# Анализируем треки
tracks = [...]  # список Track
metrics, flags, raw = analyzer.analyze_with_details(tracks)
risk_level = analyzer.get_risk_level(metrics.risk_score)

print(f"Risk: {risk_level.value} ({metrics.risk_score:.1f}/100)")
```

### FastAPI

```bash
# Запуск (локально)
uvicorn psiopyzer.main:app --reload

# API документация
open http://localhost:8000/docs

# Анализ через API
curl -X POST "http://localhost:8000/analyze?user_id=testuser&platform=spotify&limit=100"

# HTML-дашборд
curl "http://localhost:8000/analyze/html?user_id=testuser&platform=lastfm&limit=50"
```

## Метрики анализа

| Метрика | Диапазон | Описание |
|---------|----------|----------|
| `valence` | 0..1 | Средняя валентность (позитивность) музыки |
| `arousal` | 0..1 | Средний ароусал (энергичность/возбуждение) |
| `energy` | 0..1 | Физическая энергия треков |
| `night_activity` | 0..1 | Доля прослушиваний в 00:00-06:00 |
| `genre_volatility` | 0..1 | Частота смены жанров между треками |
| `loop_factor` | 0..1 | Склонность к повторению одних треков/исполнителей |
| `diversity_score` | 0..1 | Shannon entropy по жанрам и артистам |
| `isolation_index` | 0..1 | Индикатор социальной изоляции через музыку |
| `risk_score` | 0..100 | Итоговый композитный скор риска |

### Уровни риска

| Уровень | Скор | Описание |
|---------|------|----------|
| LOW | 0-25 | В пределах нормы |
| MEDIUM | 25-50 | Отдельные индикаторы, требующие внимания |
| HIGH | 50-75 | Множественные индикаторы нестабильности |
| CRITICAL | 75-100 | Требуется немедленное внимание |

## Тестирование

```bash
# Запуск тестов
pytest

# С coverage
pytest --cov=psiopyzer --cov-report=html

# Конкретный тест
pytest tests/test_emotional.py -v
```

## 📦 Модули проекта

### `core/` — Ядро
| Файл | Назначение |
|------|-----------|
| `config.py` | Pydantic Settings, загрузка из `.env` |
| `models.py` | Pydantic v2 модели: `Track`, `Playlist`, `AnalysisMetrics`, `RiskReport` |
| `enums.py` | `Platform`, `RiskLevel`, `MetricType`, `OutputFormat` |
| `exceptions.py` | `PsiopError`, `AdapterAuthError`, `AdapterAPIError`, `ModelError` и др. |

### `adapters/` — Адаптеры стриминговых платформ
| Адаптер | Библиотека | Аутентификация |
|---------|-----------|----------------|
| `YandexMusicAdapter` | `yandex-music` | Токен из cookies |
| `SpotifyAdapter` | `spotipy` | OAuth2 PKCE |
| `LastFmAdapter` | `pylast` | API key + secret |
| `StreamingAdapterFactory` | — | Фабрика с проверкой credentials |

### `analyzers/` — Анализаторы
| Анализатор | Метрики |
|-----------|---------|
| `EmotionalAnalyzer` | valence, arousal, energy (маппинг 75+ жанров) |
| `BehavioralAnalyzer` | night_activity, genre_volatility, loop_factor |
| `SocialAnalyzer` | diversity_score (Shannon entropy), isolation_index |
| `CompositeAnalyzer` | risk_score 0–100, RiskLevel, флаги |

### `ml/` — Машинное обучение
| Модуль | Описание |
|--------|----------|
| `FeatureEngineer` | 9 базовых + 7 engineered признаков + one-hot платформ |
| `RiskModel` | sklearn Pipeline: StandardScaler + RandomForest / IsolationForest |
| `ModelTrainer` | Обучение из CSV, fine-tune, evaluate (precision, recall, F1) |

### `reporters/` — Репортеры
| Репортер | Формат | Особенности |
|----------|--------|-------------|
| `JSONReporter` | JSON | Структурированный отчёт с meta и summary |
| `HTMLReporter` | HTML | Plotly radar chart, gauge, bar chart, тёмная тема |
| `CLIReporter` | Terminal (Rich) | Цветные таблицы, progress bar, индикаторы |

## 🤖 CI/CD и качество кода

### GitHub Actions (`.github/workflows/ci.yml`)

При каждом push/PR автоматически:

1. **ruff** — линтинг (E, F, W, I, N, UP, S, B, A, RUF)
2. **black** — проверка форматирования
3. **mypy** — статическая типизация
4. **pytest** — тесты с coverage
5. **Codecov** — загрузка отчёта о покрытии

Матрица Python: 3.11, 3.12

### Pre-commit хуки (`.pre-commit-config.yaml`)

```bash
poetry run pre-commit install
poetry run pre-commit run --all-files
```

Хуки: ruff (линтер + форматтер), black, mypy, trailing-whitespace, end-of-file-fixer, check-yaml, check-json, check-toml, detect-private-key

## 🐳 Docker

### Dockerfile

Multi-stage сборка:
1. **builder** — устанавливает зависимости через Poetry
2. **production** — минимальный образ с приложением

```bash
# Сборка образа
docker build -t psiopyzer:latest .

# Запуск контейнера с API
docker run -p 8000:8000 \
  -e YANDEX_MUSIC_TOKEN=... \
  -e SPOTIFY_CLIENT_ID=... \
  -e SPOTIFY_CLIENT_SECRET=... \
  -e LASTFM_API_KEY=... \
  -e LASTFM_API_SECRET=... \
  psiopyzer:latest
```

### docker-compose.yml

```bash
# Полный запуск с API + CLI
docker compose up -d

# Только API
docker compose up -d psiopyzer-api

# CLI (разовый запуск)
docker compose run --rm psiopyzer-cli analyze --platform lastfm --user-id myuser --format cli

# Остановка
docker compose down
```

Сервисы:
- `psiopyzer-api` — FastAPI на порту 8000, healthcheck, рестарт
- `psiopyzer-cli` — Тот же образ, entrypoint в CLI
- Volumes: кэш API, модели, данные (read-only)

## 📤 Публикация на GitHub

### 1. Создать репозиторий на GitHub

```bash
# Через веб-интерфейс GitHub:
# New repository → psiopyzer → Public/Private → Create

# Или через GitHub CLI:
gh repo create psiopyzer --public --description "PSIOP Analyzer"
```

### 2. Инициализировать git и запушить

```bash
cd psiopyzer

# Инициализация git
git init

# Добавить все файлы
git add .

# Первый коммит
git commit -m "feat: initial release v0.1.0 — PSIOP Analyzer"

# Связать с удалённым репозиторием
git remote add origin https://github.com/YOUR_USERNAME/psiopyzer.git

# Отправить в main
git branch -M main
git push -u origin main
```

### 3. Обновить badge CI в README

После первого пуша откройте `README.md` и замените `USERNAME` на ваш GitHub username в ссылке badge:

```markdown
[![CI](https://github.com/ВАШ_USERNAME/psiopyzer/actions/workflows/ci.yml/badge.svg)](https://github.com/ВАШ_USERNAME/psiopyzer/actions)
```

### 4. Настроить Secrets в GitHub repo

**Settings → Secrets and variables → Actions → New repository secret:**

| Secret | Значение |
|--------|----------|
| `YANDEX_MUSIC_TOKEN` | Ваш Yandex Music токен (опционально для тестов) |
| `SPOTIFY_CLIENT_ID` | Ваш Spotify Client ID (опционально) |
| `SPOTIFY_CLIENT_SECRET` | Ваш Spotify Client Secret (опционально) |
| `LASTFM_API_KEY` | Ваш Last.fm API key (опционально) |
| `LASTFM_API_SECRET` | Ваш Last.fm API secret (опционально) |

### 5. Настроить теги и релизы

```bash
# Создать тег
git tag -a v0.1.0 -m "PSIOP Analyzer v0.1.0"
git push origin v0.1.0

# Создать релиз через GitHub UI или CLI
gh release create v0.1.0 --title "v0.1.0" --notes "Initial release"
```

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. Подробнее — в файле [LICENSE](LICENSE).

## ⚠️ Предупреждение

Данная система предназначена **исключительно для исследовательских целей**. Результаты анализа не являются клиническим диагнозом. Не используйте для принятия кадровых решений без консультации с профессиональным психологом.
