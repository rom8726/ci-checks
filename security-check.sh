#!/bin/bash

# Minimal security check script for scratch-based Docker images
# Usage: ./test-security.sh <image_name> [binary_path] [--check-curl]

set -e

IMAGE_NAME="$1"
APP_BINARY="$2"
CHECK_CURL=0
FAILURES=0

if [[ "$3" == "--check-curl" || "$2" == "--check-curl" || "$3" == "--check-curl" ]]; then
    CHECK_CURL=1
fi

if [ -z "$IMAGE_NAME" ]; then
    echo "Usage: $0 <image_name> [binary_path] [--check-curl]"
    echo "Example: $0 my-server:latest /bin/app --check-curl"
    exit 1
fi

echo "🔒 Testing security of image: $IMAGE_NAME"
echo "=========================================="

# Helper
fail() {
    echo "❌ FAIL: $1"
    FAILURES=1
}

pass() {
    echo "✅ PASS: $1"
}

# 1. Shell access
echo "1. Checking shell access..."
docker run --rm "$IMAGE_NAME" /bin/sh 2>/dev/null && fail "Shell access is possible" || pass "Shell access blocked"

# 2. Bash access
echo "2. Checking bash access..."
docker run --rm "$IMAGE_NAME" /bin/bash 2>/dev/null && fail "Bash access is possible" || pass "Bash access blocked"

# 3. Env var leak
echo "3. Checking environment variable exposure..."
docker run --rm -e TEST_VAR=secret "$IMAGE_NAME" env 2>/dev/null | grep -q TEST_VAR && fail "Environment variables are exposed" || pass "Environment variables not exposed"

# 4. Arbitrary command execution
echo "4. Checking arbitrary command execution..."
docker run --rm "$IMAGE_NAME" whoami 2>/dev/null && fail "Arbitrary command executed" || pass "Arbitrary commands blocked"

# 5. Run as root
echo "5. Checking if container runs as root..."
UID=$(docker run --rm "$IMAGE_NAME" id -u 2>/dev/null || echo "no-access")
[ "$UID" = "0" ] && fail "Container runs as root" || pass "Container runs as non-root (UID=$UID)"

# 6. Sensitive files
echo "6. Checking for sensitive system files..."
for FILE in /etc/passwd /etc/shadow; do
    docker run --rm "$IMAGE_NAME" test -f "$FILE" && fail "$FILE found" || pass "$FILE not found"
done

# 7. Application binary
if [[ -n "$APP_BINARY" && "$APP_BINARY" != "--check-curl" ]]; then
    echo "7. Checking application binary at $APP_BINARY..."
    docker run --rm "$IMAGE_NAME" "$APP_BINARY" --help 2>/dev/null && pass "Application binary is accessible" || fail "$APP_BINARY is not accessible or not executable"
else
    echo "7. Skipping application binary check (no path provided)"
fi

# 8. Image size
echo "8. Checking image size..."
SIZE=$(docker images --format "{{.Size}}" "$IMAGE_NAME")
echo "📦 Image size: $SIZE"

# 9. CA certificates
echo "9. Checking for CA certificates..."
CA_PATHS=(
    /etc/ssl/certs/ca-certificates.crt
    /etc/ssl/certs/ca-bundle.crt
    /etc/pki/tls/certs/ca-bundle.crt
)
FOUND_CA=0
for CA_PATH in "${CA_PATHS[@]}"; do
    if docker run --rm "$IMAGE_NAME" test -f "$CA_PATH"; then
        pass "CA certificates found at $CA_PATH"
        FOUND_CA=1
        break
    fi
done
[ "$FOUND_CA" -eq 0 ] && fail "CA certificates not found in common paths"

# 10. Optional: Check for curl
if [ "$CHECK_CURL" -eq 1 ]; then
    echo "10. Checking curl availability..."
    docker run --rm "$IMAGE_NAME" curl --version 2>/dev/null && pass "curl is available" || fail "curl not found"
else
    echo "10. Skipping curl check (--check-curl not passed)"
fi

# Final summary
echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo "🎉 All security checks passed!"
    exit 0
else
    echo "⚠️  Some checks failed"
    exit 1
fi
