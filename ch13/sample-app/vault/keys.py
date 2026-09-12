"""Asymmetric key generation for acme-vault.

Both algorithms here are classically strong but QUANTUM-VULNERABLE: a
cryptographically relevant quantum computer running Shor's algorithm would
recover the private key from the public key. These are exactly the assets a
CBOM should surface first.
"""
from cryptography.hazmat.primitives.asymmetric import rsa, ec
from cryptography.hazmat.primitives import serialization


def generate_signing_key():
    """RSA-2048 signing key (quantum-vulnerable)."""
    return rsa.generate_private_key(public_exponent=65537, key_size=2048)


def generate_device_key():
    """Elliptic-curve P-256 key for device identity (quantum-vulnerable)."""
    return ec.generate_private_key(ec.SECP256R1())


def export_public(key) -> bytes:
    return key.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )
