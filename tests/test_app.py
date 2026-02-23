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
