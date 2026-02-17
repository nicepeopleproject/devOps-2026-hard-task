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
