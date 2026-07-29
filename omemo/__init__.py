"""
OMEMO (XEP-0384) Cryptographic Package for Qubber.
Provides Extended Triple Diffie-Hellman (X3DH) and Double Ratchet session management.
"""

from .manager import OmemoManager

__all__ = ["OmemoManager"]
