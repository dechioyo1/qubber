import os
import base64
import hashlib
from cryptography.hazmat.primitives.asymmetric import ed25519, x25519
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat, PrivateFormat, NoEncryption
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.primitives import hashes

# --- Ed25519 Identity Key Primitives ---

def generate_ed25519_keypair():
    priv = ed25519.Ed25519PrivateKey.generate()
    pub = priv.public_key()
    priv_bytes = priv.private_bytes(Encoding.Raw, PrivateFormat.Raw, NoEncryption())
    pub_bytes = pub.public_bytes(Encoding.Raw, PublicFormat.Raw)
    return priv_bytes, pub_bytes

def sign_ed25519(priv_bytes: bytes, message: bytes) -> bytes:
    priv = ed25519.Ed25519PrivateKey.from_private_bytes(priv_bytes)
    return priv.sign(message)

def verify_ed25519(pub_bytes: bytes, signature: bytes, message: bytes) -> bool:
    try:
        pub = ed25519.Ed25519PublicKey.from_public_bytes(pub_bytes)
        pub.verify(signature, message)
        return True
    except Exception:
        return False


# --- X25519 Diffie-Hellman Primitives ---

def generate_x25519_keypair():
    priv = x25519.X25519PrivateKey.generate()
    pub = priv.public_key()
    priv_bytes = priv.private_bytes(Encoding.Raw, PrivateFormat.Raw, NoEncryption())
    pub_bytes = pub.public_bytes_raw()
    return priv_bytes, pub_bytes

def dh_exchange(priv_bytes: bytes, remote_pub_bytes: bytes) -> bytes:
    clean_priv = strip_type_byte(priv_bytes)[:32]
    clean_pub = strip_type_byte(remote_pub_bytes)[:32]
    priv = x25519.X25519PrivateKey.from_private_bytes(clean_priv)
    pub = x25519.X25519PublicKey.from_public_bytes(clean_pub)
    return priv.exchange(pub)


# --- HKDF Key Derivation ---

def hkdf_derive(secret: bytes, salt: bytes = None, info: bytes = b"OMEMO", length: int = 32) -> bytes:
    hkdf = HKDF(
        algorithm=hashes.SHA256(),
        length=length,
        salt=salt if salt else b"\x00" * 32,
        info=info
    )
    return hkdf.derive(secret)


# --- AES-GCM Encryption / Decryption ---

def aes_gcm_encrypt(key: bytes, plaintext: bytes, associated_data: bytes = None) -> tuple[bytes, bytes]:
    iv = os.urandom(12)
    aesgcm = AESGCM(key)
    ciphertext = aesgcm.encrypt(iv, plaintext, associated_data)
    return iv, ciphertext

def aes_gcm_decrypt(key: bytes, iv: bytes, ciphertext: bytes, associated_data: bytes = None) -> bytes:
    aesgcm = AESGCM(key)
    return aesgcm.decrypt(iv, ciphertext, associated_data)


# --- Dual Identity Key Primitives (Ed25519 for signing, X25519 for DH) ---

def strip_type_byte(data: bytes) -> bytes:
    if not data:
        return b""
    if len(data) in (33, 65) and data[0] == 0x05:
        return data[1:]
    return data

def generate_identity_keypair():
    ed_priv, ed_pub = generate_ed25519_keypair()
    x_priv, x_pub = generate_x25519_keypair()
    return (ed_priv + x_priv), (ed_pub + x_pub)

def split_identity_key(ik_bytes: bytes) -> tuple[bytes, bytes]:
    if not ik_bytes:
        raise ValueError("Identity key bytes cannot be empty")
    clean = strip_type_byte(ik_bytes)
    if len(clean) >= 64:
        return clean[:32], clean[32:64]
    # Fallback for 32-byte key: use for both Ed25519 and X25519
    return clean[:32], clean[:32]


# --- Helpers ---

def format_fingerprint(pub_bytes: bytes) -> str:
    ed_pub, _ = split_identity_key(pub_bytes) if len(pub_bytes) >= 64 else (pub_bytes, pub_bytes)
    sha256_hex = hashlib.sha256(ed_pub).hexdigest().upper()
    return " ".join([sha256_hex[i:i+4] for i in range(0, 32, 4)])

def b64_encode(data: bytes) -> str:
    if data is None:
        return ""
    return base64.b64encode(data).decode('utf-8')

def b64_decode(s: str) -> bytes:
    if not s:
        return b""
    return base64.b64decode(s.strip())

