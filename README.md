# devOps-2026-hard-task

# Лабораторная работа: Git — revert, reset, rebase

## Сценарий

Вы — DevOps-инженер в команде, разрабатывающей REST API сервис управления задачами (Task Manager). Вам предстоит работать с историей коммитов: исправлять ошибки, реорганизовывать историю, откатывать изменения и разрешать конфликты при rebase. Каждый пункт явно указывает, какую команду использовать.

> **Важно:** после каждого пункта проверяйте состояние репозитория командами `git log --oneline --graph --all` и `git status`. Записывайте хеши ключевых коммитов — они понадобятся.

---

## Подготовка: инициализация репозитория

Выполните следующий скрипт для создания учебного репозитория с готовой историей:

```bash
#!/bin/bash
set -e

mkdir task-manager && cd task-manager
git init
git config user.name "Student"
git config user.email "student@devops.lab"

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
```

---

## Задания

### Пункт 1. Разведка (без специальных команд)

Изучите историю репозитория. Выполните:

```bash
git log --oneline --graph --all
git log --oneline main
git log --oneline feature/auth
git diff main..feature/auth --stat
```

**Задание:** запишите в файл `answers.md`:
- сколько коммитов в `main`, сколько в `feature/auth` (от точки ответвления);
- какие файлы изменены в `feature/auth` и отсутствуют в `main`;
- хеш коммита с конфигурацией базы данных (где захардкожен пароль).

---

### Пункт 2. Используйте `git reset --soft` 

WIP-коммит (`"WIP: экспериментальные заметки"`) содержит мусор, но вы хотите сохранить его изменения в staging area, чтобы разобрать их позже.

**Задание:** Откатите **только WIP-коммит** так, чтобы его изменения остались в индексе (staging area), но коммит исчез из истории. **Подсказка:** WIP — не последний коммит в main, поэтому простой `reset` не подойдёт. Подумайте, как изолировать именно этот коммит (возможно, через `rebase -i`).

**Проверка:**
```bash
git log --oneline  # WIP-коммита нет
git status         # изменения в staging
```

---

### Пункт 3. Используйте `git reset --mixed` (по умолчанию)

Вы передумали и хотите просмотреть WIP-изменения из предыдущего пункта как неотслеживаемые, прежде чем решать их судьбу.

**Задание:** Сбросьте индекс, чтобы WIP-изменения переместились из staging area в рабочую директорию (unstaged). Затем **откатите все эти изменения** — удалите мусорные строки из `src/app.py` и удалите файл `.env`.

**Проверка:**
```bash
git status         # clean working tree
git diff           # пусто
```

---

### Пункт 4. Используйте `git revert`

Коммит `"feat: конфигурация базы данных"` (с захардкоженным паролем `SuperSecret123!`) — это грубая ошибка безопасности. Он уже был запушен (считаем, что работаем с публичной историей), поэтому переписывать историю нельзя.

**Задание:** Создайте revert-коммит, отменяющий коммит с паролем. Убедитесь, что файл `src/config.py` полностью удалён.

**Проверка:**
```bash
git log --oneline  # появился Revert-коммит
ls src/config.py   # файл отсутствует
```

---

### Пункт 5. Используйте `git revert` с конфликтом

Теперь попробуйте откатить коммит `"feat: CRUD эндпоинты для задач"`. Этот коммит изменил `src/app.py`, но файл затем менялся ещё несколько раз — revert вызовет **конфликт**.

**Задание:** 
1. Выполните `git revert <хеш>`.
2. Разрешите конфликт вручную: оставьте health-check эндпоинт, но удалите все CRUD-маршруты.
3. Завершите revert (`git add` + `git revert --continue`).

**Проверка:**
```bash
git log --oneline       # revert-коммит есть
grep -c "def " src/app.py  # только health() и __main__
```

---

### Пункт 6. Используйте `git reset --hard`

Предыдущий revert CRUD-эндпоинтов был преждевременным — без них API бесполезен. Нужно полностью отменить последний revert-коммит.

**Задание:** Используйте `git reset --hard HEAD~1`, чтобы полностью уничтожить revert-коммит (и все его изменения в рабочей директории).

**Проверка:**
```bash
git log --oneline       # revert CRUD больше нет
grep "def create_task" src/app.py  # CRUD на месте
```

---

### Пункт 7. Используйте `git rebase -i` (squash)

В ветке `feature/auth` три коммита. Первые два (`"модуль аутентификации"` и `"JWT утилиты"`) логически связаны и должны быть объединены в один.

**Задание:**
1. Переключитесь на `feature/auth`.
2. Выполните `git rebase -i HEAD~3`.
3. Оставьте первый коммит (`pick`), второй отметьте как `squash`.
4. Третий коммит (`delete_all_users`) пока оставьте (`pick`).
5. Напишите объединённое сообщение: `"feat: аутентификация и JWT"`.

**Проверка:**
```bash
git log --oneline  # 2 коммита вместо 3 в feature/auth
```

---

### Пункт 8. Используйте `git rebase -i` (drop)

Коммит `"feat: функция массового удаления пользователей"` — опасная функция, которую не должно быть в коде.

**Задание:** Используйте `git rebase -i` и **drop** этот коммит полностью. Убедитесь, что функция `delete_all_users` исчезла из `src/auth.py`.

**Проверка:**
```bash
git log --oneline                    # коммит удалён
grep "delete_all_users" src/auth.py  # ничего не найдено
```

---

### Пункт 9. Используйте `git rebase -i` (reword)

Единственный оставшийся коммит `"feat: аутентификация и JWT"` имеет слишком общее сообщение. Переименуйте его.

**Задание:** Используйте `git rebase -i` с действием `reword`. Новое сообщение: `"feat(auth): реализация аутентификации (pbkdf2) и JWT-токенов"`.

**Проверка:**
```bash
git log --oneline  # новое сообщение коммита
```

---

### Пункт 10. Используйте `git rebase` (перенос ветки на актуальный main)

Ветка `feature/auth` отстала от `main` — в main появились Dockerfile, docker-compose и CI.

**Задание:**
1. Находясь в `feature/auth`, выполните `git rebase main`.
2. Если возникнут конфликты — разрешите их.
3. Убедитесь, что коммит auth теперь стоит **поверх** всех коммитов main.

**Проверка:**
```bash
git log --oneline --graph --all  # линейная история, auth поверх main
```

---

### Пункт 11. Используйте `git reset --soft` для объединения нескольких коммитов

Вернитесь на `main`. Три ops/ci-коммита (`Dockerfile`, `docker-compose`, `CI`) логически связаны и должны быть одним.

**Задание:**
1. `git checkout main`
2. Определите хеш коммита **перед** Dockerfile.
3. Используйте `git reset --soft <хеш>`, чтобы «свернуть» три коммита, оставив все изменения в staging.
4. Создайте один новый коммит: `"ops: контейнеризация и CI/CD пайплайн"`.

**Проверка:**
```bash
git log --oneline        # один ops-коммит вместо трёх
ls Dockerfile docker-compose.yml .github/workflows/ci.yml  # все файлы на месте
```

---

### Пункт 12. Используйте `git revert` (revert нескольких коммитов диапазоном)

Допустим, вы решили, что пагинация и документация — преждевременные фичи. Нужно откатить оба коммита одной операцией.

**Задание:** Используйте `git revert --no-commit <хеш-старшего>..<хеш-младшего>`, чтобы отменить два коммита (документацию и пагинацию) одним revert-коммитом. После подготовки изменений выполните `git commit`.

**Проверка:**
```bash
git log --oneline         # один Revert-коммит
ls docs/API.md            # файл отсутствует
ls src/pagination.py      # файл отсутствует
```

---

### Пункт 13. Используйте `git revert` (отмена revert — «re-revert»)

Заказчик передумал: пагинация и документация всё-таки нужны!

**Задание:** Выполните `git revert` на revert-коммит из пункта 12, чтобы вернуть удалённые файлы.

**Проверка:**
```bash
ls docs/API.md src/pagination.py  # оба файла вернулись
git log --oneline                  # два revert-коммита подряд
```

---

### Пункт 14. Используйте `git rebase -i` (edit)

Нужно внести дополнительные изменения в коммит с моделью Task — добавить поле `assignee`.

**Задание:**
1. Выполните `git rebase -i` и отметьте коммит `"feat: модель Task с dataclass"` как `edit`.
2. Когда rebase остановится, отредактируйте `src/models.py` — добавьте поле `assignee: str = ""` в класс Task.
3. Выполните `git add src/models.py` и `git rebase --continue`.
4. Разрешите все конфликты, которые возникнут в последующих коммитах.

**Проверка:**
```bash
grep "assignee" src/models.py  # поле присутствует
git log --oneline              # история линейная, без лишних коммитов
```

---

### Пункт 15. Используйте `git reset --mixed` + ручная пересборка

Ops-коммит из пункта 11 получился слишком большим. Разделите его на два: отдельно Docker, отдельно CI.

**Задание:**
1. Найдите хеш ops-коммита.
2. `git reset --mixed <хеш_предыдущего_коммита>` — сбросьте ops-коммит, оставив файлы в рабочей директории.
3. `git add Dockerfile docker-compose.yml` → `git commit -m "ops: Docker и docker-compose"`
4. `git add .github/` → `git commit -m "ci: GitHub Actions pipeline"`

**Проверка:**
```bash
git log --oneline  # два отдельных коммита вместо одного
```

---

### Пункт 16. Используйте `git rebase -i` (переупорядочивание коммитов)

Коммит с логированием (`"feat: модуль логирования"`) должен стоять **сразу после** инициализационного коммита — он базовый и нужен с самого начала.

**Задание:**
1. Выполните `git rebase -i --root`.
2. Переместите строку с коммитом логирования на вторую позицию (сразу после `init`).
3. Сохраните и разрешите все конфликты.

> ⚠️ Это сложная операция — конфликты почти гарантированы. Будьте внимательны.

**Проверка:**
```bash
git log --oneline  # логирование — второй коммит
```

---

### Пункт 17. Используйте `git reflog` + `git reset --hard` (восстановление после ошибки)

Сымитируйте катастрофу: выполните `git reset --hard HEAD~5` — вы «потеряли» последние 5 коммитов.

**Задание:**
1. Выполните `git reset --hard HEAD~5`.
2. Убедитесь, что коммиты «пропали» из `git log`.
3. Используя `git reflog`, найдите хеш состояния **до** сброса.
4. Выполните `git reset --hard <хеш_из_reflog>` для восстановления.

**Проверка:**
```bash
git log --oneline  # все коммиты восстановлены
```

---

### Пункт 18. Используйте `git revert` с `--no-edit` (пакетный откат)

Нужно подготовить «облегчённую» версию для демонстрации: откатить middleware и логирование, оставив базовый API.

**Задание:**
1. Найдите хеши коммитов middleware и логирования.
2. Откатите каждый отдельным `git revert --no-edit <хеш>`.
3. Убедитесь, что оба revert-коммита созданы автоматически (без открытия редактора).

**Проверка:**
```bash
git log --oneline          # два revert-коммита
ls src/middleware.py       # файл отсутствует (или пуст)
ls src/logger.py           # файл отсутствует (или пуст)
```

---

### Пункт 19. Используйте `git rebase --onto` (пересадка ветки)

Создайте новую ветку `feature/notifications` от текущего `main`, сделайте в ней 2 коммита:

```bash
git checkout -b feature/notifications
echo 'def notify(user, message): pass' > src/notifications.py
git add -A && git commit -m "feat: заглушка для нотификаций"
echo 'SMTP_HOST=localhost' > src/email_config.py
git add -A && git commit -m "feat: конфигурация email"
```

Теперь представьте, что ветку нужно пересадить — она должна начинаться не от текущего main (с revert-коммитами из п.18), а от коммита **до** этих revert'ов.

**Задание:** Используйте `git rebase --onto <новый-базовый> <старый-базовый> feature/notifications`, чтобы пересадить ветку.

**Проверка:**
```bash
git log --oneline feature/notifications  # нотификации идут после нужного коммита
git log --oneline feature/notifications | grep -c "Revert"  # 0 — revert'ов нет в предках
```

---

### Пункт 20. Финальное задание: используйте `git reset --soft` + `git rebase -i` + `git revert`

Вернитесь на `main`. Приведите историю в идеальное состояние:

1. **`git revert`** — откатите все revert-коммиты из п.18 (верните middleware и логирование обратно).
2. **`git rebase -i`** — выполните интерактивный rebase, чтобы:
   - **squash** все пары revert/re-revert (из п.12–13 и п.18–20) в один коммит или удалите их через **drop**, если они взаимно уничтожаются;
   - убедитесь, что итоговая история чистая и линейная.
3. **`git reset --soft HEAD~2`** — объедините два последних ops-коммита (Docker + CI) обратно в один: `"ops: инфраструктура и CI/CD"`.
4. Создайте финальный коммит.

**Итоговая проверка:**
```bash
git log --oneline --graph          # чистая линейная история
git log --oneline | grep "Revert"  # ноль revert'ов (всё вычищено)
ls src/                            # все модули на месте
ls Dockerfile docker-compose.yml   # Docker-файлы на месте
ls .github/workflows/ci.yml       # CI на месте
```

---

## Критерии оценки

| Блок | Баллы |
|------|-------|
| Пункты 1–3 (reset soft/mixed, разведка) | 10 |
| Пункты 4–6 (revert, revert с конфликтом, reset hard) | 15 |
| Пункты 7–9 (rebase -i: squash, drop, reword) | 15 |
| Пункт 10 (rebase на актуальный main) | 10 |
| Пункты 11–13 (reset soft для squash, revert диапазона, re-revert) | 15 |
| Пункты 14–16 (rebase edit, reset mixed + пересборка, переупорядочивание) | 15 |
| Пункт 17 (reflog + восстановление) | 5 |
| Пункты 18–19 (пакетный revert, rebase --onto) | 10 |
| Пункт 20 (финальная очистка истории) | 5 |
| **Итого** | **100** |

---

## Шпаргалка по командам

| Команда | Что делает | Когда использовать |
|---------|-----------|-------------------|
| `git reset --soft <ref>` | Перемещает HEAD, изменения остаются в staging | Объединение коммитов, повторный коммит |
| `git reset --mixed <ref>` | Перемещает HEAD, изменения — в рабочей директории | Разделение коммита на несколько |
| `git reset --hard <ref>` | Перемещает HEAD, **уничтожает** все изменения | Полный откат, восстановление через reflog |
| `git revert <ref>` | Создаёт **новый коммит**, отменяющий указанный | Безопасный откат в публичной истории |
| `git revert --no-commit` | Подготавливает revert без коммита | Объединение нескольких revert'ов |
| `git revert --no-edit` | Создаёт revert с автоматическим сообщением | Пакетные откаты |
| `git rebase -i` | Интерактивное редактирование истории | squash, drop, reword, edit, reorder |
| `git rebase <branch>` | Перенос коммитов на вершину указанной ветки | Обновление feature-ветки |
| `git rebase --onto` | Пересадка ветки на другую базу | Изменение точки ответвления |
