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
