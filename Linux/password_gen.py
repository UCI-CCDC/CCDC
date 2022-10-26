#!/bin/env python3

# python 3.5+
# pip 8.1+

import os.path
import random
import sys

if __name__ == "__main__":
    try:
        import Cryptodome
    except ModuleNotFoundError:
        print("Could not find module pycryptodomex")
        print("pip install pycryptodomex")
        print(
            "offline install: pip install pycryptodomex-3.11.0-cp35-abi3-manylinux1_x86_64.whl"
        )
        sys.exit(1)

import Cryptodome.Cipher.ChaCha20
import Cryptodome.Hash.SHA512
import Cryptodome.Protocol.KDF
import Cryptodome.Util.RFC1751

# excluding look-alike characters
UPPERCASE = "ACDEFHJKLMNPQRSTUVWXYZ"  # no B, G, I, O
LOWERCASE = "abcdefghijkmnopqrstuvwxyz"  # no l
DIGITS = "234579"  # no 0, 1, 6, 8
SPECIAL = "!@#$%^&*()-=?"

ALPHABETS = (UPPERCASE, LOWERCASE, DIGITS, SPECIAL)
# ALPHABET = "".join(ALPHABETS)
ALPHABET = UPPERCASE * 3 + LOWERCASE * 3 + DIGITS * 2 + SPECIAL

HKDF_SALT_NONCE = b"UCI Anteaters Passwords"
HKDF_SALT_KEY = b"UCI Anteaters Key"
CHACHA_LENGTH_NONCE = 24
CHACHA_LENGTH_KEY = 32

# every rng is seeded from this
# arguably it should be as big as the chacha key, but then the generated passphrase is 24 words which is very long
# SEED_LENGTH = 32
SEED_LENGTH = 16
PASSPHRASE_LENGTH = SEED_LENGTH // 4 * 3

# hkdf can generate a total of (hash digest length) * 255 bytes across all keys, (512/8) * 255 / 24
# so 680 is the absolute maximum for sha512
MAX_PASSWORDS = 680

PASSWORD_LENGTH = 16

# returns size MAX_PASSWORDS list of CHACHA_LENGTH_NONCE-byte nonces
def hkdf_nonces(seed):
    return Cryptodome.Protocol.KDF.HKDF(
        seed,
        CHACHA_LENGTH_NONCE,
        HKDF_SALT_NONCE,
        Cryptodome.Hash.SHA512,
        MAX_PASSWORDS,
    )


def hkdf_key(seed):
    return Cryptodome.Protocol.KDF.HKDF(
        seed, CHACHA_LENGTH_KEY, HKDF_SALT_KEY, Cryptodome.Hash.SHA512, 1
    )


def chacha(key, nonce):
    assert len(key) == CHACHA_LENGTH_KEY
    assert len(nonce) == CHACHA_LENGTH_NONCE

    return Cryptodome.Cipher.ChaCha20.new(key=key, nonce=nonce)


def chacha_numbytes(chacha, numbytes):
    # internally it generates n random bytes, then xors it with plaintext
    # so it is safe to "encrypt" with null byte to just extract the random bytes

    # this does update internal state
    return chacha.encrypt(b"\x00" * numbytes)


class ChaChaRandom(random.Random):
    # https://github.com/python/cpython/blob/e9594f6/Lib/random.py#L109-L113

    def seed(self, x):
        if x is None:
            raise ValueError("must pass in (key, nonce)")
        key, nonce = x

        self.chacha = chacha(key, nonce)

    def getrandbits(self, k):
        # https://github.com/python/cpython/blob/e9594f6/Lib/random.py#L768-L774
        if k < 0:
            raise ValueError
        numbytes = (k + 7) // 8
        x = int.from_bytes(chacha_numbytes(self.chacha, numbytes), "little")
        return x >> (numbytes * 8 - k)

    def random(self):
        raise NotImplementedError

    def getstate(self):
        raise NotImplementedError

    def setstate(self, _state):
        raise NotImplementedError


def generate_seed():
    try:
        import secrets
    except ModuleNotFoundError:
        raise RuntimeError("Must run on python 3.6+")

    seed = secrets.token_bytes(SEED_LENGTH)
    passphrase = Cryptodome.Util.RFC1751.key_to_english(seed)
    seed2 = Cryptodome.Util.RFC1751.english_to_key(passphrase)
    assert seed == seed2

    print("Generated key: %s" % passphrase)

    return passphrase


def check_password(password):
    for alphabet in ALPHABETS:
        for char in password:
            if char in alphabet:
                break
        else:
            # did not include at least one character from each alphabet in password
            return False

    return True


def generate_password(key, nonces, i):
    nonce = nonces[i]
    rng = ChaChaRandom((key, nonce))

    while True:
        password = "".join(rng.choice(ALPHABET) for _ in range(PASSWORD_LENGTH))

        if check_password(password):
            break

    return password


def main():
    args = sys.argv[1:]
    prog = os.path.basename(sys.argv[0])

    if "--help" in args:
        print("python3 %s [--generate]" % prog)
        return

    if "--generate" in args:
        passphrase = generate_seed()
    else:
        print("Enter passphrase: ", end="")
        passphrase = input()

    num_words = len(passphrase.split())
    if num_words != PASSPHRASE_LENGTH:
        raise ValueError("Expected %s words, got %s" % (PASSPHRASE_LENGTH, num_words))

    seed = Cryptodome.Util.RFC1751.english_to_key(passphrase)

    key = hkdf_key(seed)
    nonces = hkdf_nonces(seed)

    for i in range(10):
        print(generate_password(key, nonces, i))


if __name__ == "__main__":
    main()
