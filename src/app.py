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
