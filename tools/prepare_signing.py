"""Normalize accidental copy/paste formatting without disclosing signing secrets."""
import base64
import binascii
import os
from pathlib import Path
import re
import shlex
import sys

FIELDS = {
    "KS_B64": "ANDROID_KEYSTORE_BASE64",
    "KS_PASS": "ANDROID_KEYSTORE_PASSWORD",
    "KEY_ALIAS": "ANDROID_KEY_ALIAS",
    "KEY_PASS": "ANDROID_KEY_PASSWORD",
}

def extract(var, label):
    value = os.environ.get(var, "").strip().lstrip("\ufeff").strip()
    # Accept the value alone, a labelled field, or the original credentials
    # document if it was mistakenly pasted into the secret field.
    marker = re.search(r"(?m)^\s*" + re.escape(label) + r"\s*(?:[:=]\s*|\n)", value)
    if marker:
        value = value[marker.end():]
        value = re.split(r"(?m)^\s*ANDROID_(?:KEYSTORE_BASE64|KEYSTORE_PASSWORD|KEY_ALIAS|KEY_PASSWORD)\b", value, maxsplit=1)[0]
    value = value.strip()
    if value.startswith("```") and value.endswith("```"):
        value = value.split("\n", 1)[-1][:-3].strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
        value = value[1:-1].strip()
    if not value:
        raise ValueError(label + " is empty")
    return value

def main():
    values = {v: extract(v, k) for v, k in FIELDS.items()}
    encoded = re.sub(r"\s+", "", values.pop("KS_B64"))
    try:
        key = base64.b64decode(encoded, validate=True)
    except (ValueError, binascii.Error):
        raise ValueError("ANDROID_KEYSTORE_BASE64 contains invalid or incomplete data. Replace it with the exact Base64-only file.")
    if len(key) < 256:
        raise ValueError("ANDROID_KEYSTORE_BASE64 is too short to contain the signing keystore")
    os.umask(0o077)
    Path(sys.argv[1]).write_bytes(key)
    Path(sys.argv[2]).write_text("".join("export " + k + "=" + shlex.quote(v) + "\n" for k, v in values.items()))
    print("Signing data decoded; certificate verification remains mandatory.")

if __name__ == "__main__":
    try:
        main()
    except ValueError as exc:
        print("::error::" + str(exc), file=sys.stderr)
        sys.exit(1)
