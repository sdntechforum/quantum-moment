"""At-rest encryption for stored blobs.

Symmetric crypto: with a 256-bit key, AES is considered QUANTUM-SAFE (Grover only
halves the effective key strength). The legacy AES-CBC path and the Fernet helper
are here to show the CBOM distinguishing modes and constructions, not just
algorithm names.
"""
import os
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.fernet import Fernet


def encrypt_blob(key: bytes, plaintext: bytes):
    """AES-256-GCM (AEAD, quantum-safe at 256-bit)."""
    iv = os.urandom(12)
    enc = Cipher(algorithms.AES(key), modes.GCM(iv)).encryptor()
    ct = enc.update(plaintext) + enc.finalize()
    return iv, ct, enc.tag


def legacy_encrypt(key: bytes, iv: bytes, plaintext: bytes) -> bytes:
    """Legacy AES-256-CBC (kept for backward compatibility)."""
    enc = Cipher(algorithms.AES(key), modes.CBC(iv)).encryptor()
    return enc.update(plaintext) + enc.finalize()


def fernet_token(plaintext: bytes) -> bytes:
    """Fernet = AES-128-CBC + HMAC-SHA256 under the hood."""
    return Fernet(Fernet.generate_key()).encrypt(plaintext)
