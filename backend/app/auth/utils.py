import hashlib
import secrets
from jose import JWTError, jwt
from datetime import datetime, timedelta
from typing import Optional
from ..config import settings


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against a hash using PBKDF2"""
    try:
        # Hash format: algorithm$iterations$salt$hash
        parts = hashed_password.split('$')
        if len(parts) != 4:
            return False
        
        algorithm, iterations, salt, stored_hash = parts
        iterations = int(iterations)
        
        # Hash the plain password with the same salt
        password_hash = hashlib.pbkdf2_hmac(
            'sha256',
            plain_password.encode('utf-8'),
            salt.encode('utf-8'),
            iterations
        )
        computed_hash = password_hash.hex()
        
        # Constant-time comparison
        return secrets.compare_digest(computed_hash, stored_hash)
    except Exception:
        return False


def get_password_hash(password: str) -> str:
    """Hash a password using PBKDF2 with SHA256"""
    # Generate a random salt
    salt = secrets.token_hex(32)
    iterations = 100000
    
    # Hash the password
    password_hash = hashlib.pbkdf2_hmac(
        'sha256',
        password.encode('utf-8'),
        salt.encode('utf-8'),
        iterations
    )
    
    # Return in format: algorithm$iterations$salt$hash
    return f"pbkdf2_sha256${iterations}${salt}${password_hash.hex()}"


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire, "type": "access"})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt


def create_refresh_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt


def decode_token(token: str) -> Optional[dict]:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except JWTError:
        return None


def get_current_user_id(token: str) -> Optional[str]:
    """Extract user ID from JWT token"""
    payload = decode_token(token)
    if payload and payload.get("type") == "access":
        return payload.get("sub")
    return None
