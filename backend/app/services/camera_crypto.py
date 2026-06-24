from functools import lru_cache

from cryptography.fernet import Fernet

from ..core.config import get_settings


@lru_cache
def _fernet() -> Fernet:
    return Fernet(get_settings().camera_secret_key.encode("utf-8"))


def encrypt_camera_password(plaintext: str) -> str:
    return _fernet().encrypt(plaintext.encode("utf-8")).decode("utf-8")


def decrypt_camera_password(ciphertext: str) -> str:
    return _fernet().decrypt(ciphertext.encode("utf-8")).decode("utf-8")
