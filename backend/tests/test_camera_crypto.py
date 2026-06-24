from app.services.camera_crypto import decrypt_camera_password, encrypt_camera_password


def test_encrypt_then_decrypt_roundtrips():
    ciphertext = encrypt_camera_password("super-secret-123")
    assert ciphertext != "super-secret-123"
    assert decrypt_camera_password(ciphertext) == "super-secret-123"
