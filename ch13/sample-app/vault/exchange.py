"""Key-agreement helpers.

Both classical key-exchange methods below are QUANTUM-VULNERABLE. This is the
place a post-quantum migration would add ML-KEM (see Lab 4 for the IPsec
equivalent) - but first the CBOM has to reveal that DH and ECDH are here at all.
"""
from cryptography.hazmat.primitives.asymmetric import dh, ec


def new_dh_parameters():
    """Finite-field Diffie-Hellman parameters (quantum-vulnerable)."""
    return dh.generate_parameters(generator=2, key_size=2048)


def ecdh_shared_secret(private_key, peer_public_key) -> bytes:
    """ECDH on P-256 (quantum-vulnerable)."""
    return private_key.exchange(ec.ECDH(), peer_public_key)
