"""At-rest encryption for stored blobs.

Symmetric cryptography is not affected by Shor's algorithm, but the key size,
mode, nonce discipline, authentication, and lifecycle still matter. The legacy
AES-CBC path and the Fernet helper show why an inventory needs constructions and
usage context rather than algorithm names alone.
"""
import os
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.fernet import Fernet


def encrypt_blob(key: bytes, plaintext: bytes):
    """AES-GCM; the caller, not this function, determines the AES key length."""
    iv = os.urandom(12)
    enc = Cipher(algorithms.AES(key), modes.GCM(iv)).encryptor()
    ct = enc.update(plaintext) + enc.finalize()
    return iv, ct, enc.tag


def legacy_encrypt(key: bytes, iv: bytes, plaintext: bytes) -> bytes:
    """Legacy AES-CBC; key length depends on the caller-provided key."""
    enc = Cipher(algorithms.AES(key), modes.CBC(iv)).encryptor()
    return enc.update(plaintext) + enc.finalize()


def fernet_token(plaintext: bytes) -> bytes:
    """Fernet = AES-128-CBC + HMAC-SHA256 under the hood."""
    return Fernet(Fernet.generate_key()).encrypt(plaintext)
