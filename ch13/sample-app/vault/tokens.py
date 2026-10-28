"""Token signing and a couple of hashes that hide in plain sight.

HMAC-SHA256 is included as a modern symmetric construction, subject to key and
protocol handling. The MD5 and SHA-1 below demonstrate why an algorithm finding
must be interpreted in context: a collision-prone hash can be a security defect,
an identity defect, or non-security technical debt. The pinned scanner flags the
pyca forms but misses the standard-library forms.
"""
import hashlib
from cryptography.hazmat.primitives import hashes, hmac


def sign_token(key: bytes, message: bytes) -> bytes:
    """HMAC-SHA256 authentication tag."""
    h = hmac.HMAC(key, hashes.SHA256())
    h.update(message)
    return h.finalize()


def legacy_fingerprint(blob: bytes) -> bytes:
    """'Just a fingerprint' - MD5 via pyca (broken; the CBOM catches this one)."""
    h = hashes.Hash(hashes.MD5())
    h.update(blob)
    return h.finalize()


def content_tag(blob: bytes) -> bytes:
    """'Just a content tag' - SHA-1 via pyca (deprecated; caught by the CBOM)."""
    h = hashes.Hash(hashes.SHA1())
    h.update(blob)
    return h.finalize()


def cache_key(blob: bytes) -> str:
    """'Just a cache key' - MD5 via the stdlib hashlib.

    NOTE: a source-only scanner focused on pyca/cryptography does NOT flag this
    one - a real, honest coverage gap. Same broken primitive, invisible to the
    tool, because it came in through a different door (hashlib, not pyca).
    """
    return hashlib.md5(blob).hexdigest()


def dedup_id(blob: bytes) -> str:
    """'Just a dedup id' - SHA-1 via stdlib hashlib (also missed by the scanner)."""
    return hashlib.sha1(blob).hexdigest()
