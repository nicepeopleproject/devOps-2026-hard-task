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
