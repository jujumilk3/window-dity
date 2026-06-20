#!/usr/bin/env bash
# Create a stable self-signed code-signing identity for WindowDity (run once).
#
# Why: an ad-hoc signature ties the app's identity to the binary hash, so the
# Accessibility permission breaks on every rebuild. Signing with a fixed
# self-signed certificate makes the identity (bundle id + certificate) stable,
# so you grant Accessibility once and it sticks across rebuilds.
#
# The certificate is self-signed and NOT added to the system trust store — it is
# only used to give the app a stable code-signing identity. It does not affect
# whether the app is allowed to run.
set -euo pipefail

CERT_CN="WindowDity Self-Signed"
KEYCHAIN="$(security default-keychain -d user | sed -e 's/^[[:space:]]*//' -e 's/"//g')"

if security find-identity -p codesigning 2>/dev/null | grep -q "$CERT_CN"; then
  echo "Identity already exists: \"$CERT_CN\" — nothing to do."
  exit 0
fi

echo "==> Creating self-signed code-signing identity: \"$CERT_CN\""
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/openssl.cnf" <<EOF
[req]
distinguished_name = dn
x509_extensions = v3
prompt = no
[dn]
CN = $CERT_CN
[v3]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
EOF

openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout "$TMP/key_pkcs8.pem" -out "$TMP/cert.pem" \
  -config "$TMP/openssl.cnf" >/dev/null 2>&1

# Convert PKCS#8 (what OpenSSL emits) to traditional RSA PEM, which
# `security import -f openssl` understands.
openssl rsa -in "$TMP/key_pkcs8.pem" -out "$TMP/key.pem" >/dev/null 2>&1

# Import the private key and certificate separately. The keychain pairs them into
# a usable code-signing identity, sidestepping PKCS#12 MAC incompatibilities
# between LibreSSL and Apple's Security framework. -A lets command-line tools
# (incl. codesign) use the key without a keychain prompt.
security import "$TMP/key.pem"  -k "$KEYCHAIN" -A -f openssl -t priv >/dev/null
security import "$TMP/cert.pem" -k "$KEYCHAIN" -A >/dev/null

if security find-identity -p codesigning 2>/dev/null | grep -q "$CERT_CN"; then
  echo "==> Done. build-app.sh will now sign with \"$CERT_CN\"."
else
  echo "!! Import did not register the identity; build-app.sh will use ad-hoc instead." >&2
  exit 1
fi
