#!/bin/bash
set -e

mkdir task-manager && cd task-manager

# === Коммит 1: структура проекта ===
mkdir -p src tests docs
cat > src/app.py << 'EOF'
from flask import Flask, jsonify

app = Flask(__name__)

tasks = []

@app.route('/health')
def health():
    return jsonify({"status": "ok"})

if __name__ == '__main__':
    app.run(debug=True)
EOF

cat > requirements.txt << 'EOF'
flask==2.3.0
pytest==7.4.0
EOF

cat > README.md << 'EOF'
# Task Manager API
Простой REST API для управления задачами.
EOF

git add -A && git commit -m "init: структура проекта и health-check эндпоинт"

# === Коммит 2: модель задачи ===
cat > src/models.py << 'EOF'
from dataclasses import dataclass, field
from datetime import datetime
from uuid import uuid4

@dataclass
class Task:
    title: str
    description: str = ""
    status: str = "todo"
    priority: int = 0
    id: str = field(default_factory=lambda: str(uuid4()))
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())
EOF

git add -A && git commit -m "feat: модель Task с dataclass"

# === Коммит 3: CRUD эндпоинты ===
cat > src/app.py << 'EOF'
from flask import Flask, jsonify, request
from src.models import Task

app = Flask(__name__)

tasks = {}

@app.route('/health')
def health():
    return jsonify({"status": "ok"})

@app.route('/tasks', methods=['GET'])
def get_tasks():
    return jsonify([t.__dict__ for t in tasks.values()])

@app.route('/tasks', methods=['POST'])
def create_task():
    data = request.json
    task = Task(title=data['title'], description=data.get('description', ''))
    tasks[task.id] = task
    return jsonify(task.__dict__), 201

@app.route('/tasks/<task_id>', methods=['PUT'])
def update_task(task_id):
    if task_id not in tasks:
        return jsonify({"error": "not found"}), 404
    data = request.json
    task = tasks[task_id]
    task.title = data.get('title', task.title)
    task.description = data.get('description', task.description)
    task.status = data.get('status', task.status)
    return jsonify(task.__dict__)

@app.route('/tasks/<task_id>', methods=['DELETE'])
def delete_task(task_id):
    if task_id not in tasks:
        return jsonify({"error": "not found"}), 404
    del tasks[task_id]
    return '', 204

if __name__ == '__main__':
    app.run(debug=True)
EOF

git add -A && git commit -m "feat: CRUD эндпоинты для задач"

# === Коммит 4: тесты ===
cat > tests/test_app.py << 'EOF'
import pytest
from src.app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health(client):
    response = client.get('/health')
    assert response.status_code == 200

def test_create_task(client):
    response = client.post('/tasks', json={"title": "Test task"})
    assert response.status_code == 201
    assert response.json['title'] == "Test task"

def test_get_tasks(client):
    client.post('/tasks', json={"title": "Task 1"})
    response = client.get('/tasks')
    assert response.status_code == 200
EOF

git add -A && git commit -m "test: базовые тесты для API"

# === Коммит 5: ОШИБКА — захардкоженный пароль ===
cat > src/config.py << 'EOF'
DATABASE_URL = "postgresql://admin:SuperSecret123!@localhost:5432/taskdb"
SECRET_KEY = "my-super-secret-key-do-not-share"
DEBUG = True
EOF

git add -A && git commit -m "feat: конфигурация базы данных"

# === Коммит 6: логирование ===
cat > src/logger.py << 'EOF'
import logging

def setup_logger(name):
    logger = logging.getLogger(name)
    logger.setLevel(logging.DEBUG)
    handler = logging.StreamHandler()
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    return logger
EOF

git add -A && git commit -m "feat: модуль логирования"

# === Коммит 7: middleware ===
cat > src/middleware.py << 'EOF'
from functools import wraps
from flask import request, jsonify
from src.logger import setup_logger

logger = setup_logger('middleware')

def request_logger(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        logger.info(f"{request.method} {request.path}")
        return f(*args, **kwargs)
    return decorated

def require_json(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if request.method in ['POST', 'PUT'] and not request.is_json:
            return jsonify({"error": "Content-Type must be application/json"}), 415
        return f(*args, **kwargs)
    return decorated
EOF

git add -A && git commit -m "feat: middleware для логирования и валидации"

# === Коммит 8: WIP коммит с мусором ===
echo "TODO: добавить авторизацию" >> src/app.py
echo "# FIXME: убрать перед релизом" >> src/app.py
echo "TEMP_VAR=debug_mode" >> .env
git add -A && git commit -m "WIP: экспериментальные заметки"

# === Коммит 9: документация ===
cat > docs/API.md << 'EOF'
# API Documentation

## Endpoints

### GET /health
Проверка состояния сервиса.

### GET /tasks
Получение списка всех задач.

### POST /tasks
Создание новой задачи.
Body: {"title": "string", "description": "string"}

### PUT /tasks/:id
Обновление задачи.

### DELETE /tasks/:id
Удаление задачи.
EOF

git add -A && git commit -m "docs: документация API"

# === Коммит 10: пагинация ===
cat > src/pagination.py << 'EOF'
def paginate(items, page=1, per_page=10):
    start = (page - 1) * per_page
    end = start + per_page
    total = len(items)
    return {
        "items": items[start:end],
        "page": page,
        "per_page": per_page,
        "total": total,
        "pages": (total + per_page - 1) // per_page
    }
EOF

git add -A && git commit -m "feat: утилита пагинации"

# === Создание ветки feature/auth ===
git checkout -b feature/auth

cat > src/auth.py << 'EOF'
import hashlib
import os

users = {}

def hash_password(password):
    salt = os.urandom(32)
    key = hashlib.pbkdf2_hmac('sha256', password.encode(), salt, 100000)
    return salt + key

def verify_password(password, stored):
    salt = stored[:32]
    key = stored[32:]
    new_key = hashlib.pbkdf2_hmac('sha256', password.encode(), salt, 100000)
    return key == new_key

def register(username, password):
    if username in users:
        return False
    users[username] = hash_password(password)
    return True

def login(username, password):
    if username not in users:
        return False
    return verify_password(password, users[username])
EOF

git add -A && git commit -m "feat: модуль аутентификации"

# Ещё коммит в feature/auth
cat > src/jwt_utils.py << 'EOF'
import jwt
import datetime

SECRET = "change-me-in-production"

def create_token(username):
    payload = {
        "sub": username,
        "iat": datetime.datetime.utcnow(),
        "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=1)
    }
    return jwt.encode(payload, SECRET, algorithm="HS256")

def decode_token(token):
    try:
        return jwt.decode(token, SECRET, algorithms=["HS256"])
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None
EOF

git add -A && git commit -m "feat: JWT утилиты для токенов"

# Ещё коммит — намеренная ошибка в auth
cat >> src/auth.py << 'EOF'

def delete_all_users():
    """ОПАСНО: удаляет всех пользователей без подтверждения"""
    global users
    users = {}
    return True
EOF

git add -A && git commit -m "feat: функция массового удаления пользователей"

git checkout main

# === Коммит 11 в main: Dockerfile ===
cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src/ ./src/
EXPOSE 5000
CMD ["python", "-m", "flask", "--app", "src.app", "run", "--host", "0.0.0.0"]
EOF

git add -A && git commit -m "ops: Dockerfile для сервиса"

# === Коммит 12 в main: docker-compose ===
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  api:
    build: .
    ports:
      - "5000:5000"
    environment:
      - FLASK_ENV=development
    volumes:
      - ./src:/app/src
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: taskdb
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: SuperSecret123!
    ports:
      - "5432:5432"
EOF

git add -A && git commit -m "ops: docker-compose с API и PostgreSQL"

# === Коммит 13 в main: CI конфиг ===
mkdir -p .github/workflows
cat > .github/workflows/ci.yml << 'EOF'
name: CI Pipeline
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - run: pip install -r requirements.txt
      - run: pytest tests/ -v
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install flake8
      - run: flake8 src/ --max-line-length=120
EOF

git add -A && git commit -m "ci: GitHub Actions для тестов и линтинга"

echo ""
echo "=== Репозиторий готов ==="
echo "Текущая ветка: main (13 коммитов)"
echo "Ветка feature/auth: 3 коммита"
echo ""
git log --oneline --graph --all

