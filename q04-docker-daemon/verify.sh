#!/bin/bash
# ============================================================================
# CKS Q04: Docker Daemon Security — Verify Solution
# ============================================================================

PASS=0; FAIL=0
check() {
  if eval "$2" &>/dev/null; then
    echo "✅ PASS: $1"; ((PASS++))
  else
    echo "❌ FAIL: $1"; ((FAIL++))
  fi
}

echo "=================================================================="
echo "  VERIFYING Q04: DOCKER DAEMON SECURITY"
echo "=================================================================="
echo ""

# Check user removed from docker group
check "'develop' user is NOT in docker group" \
  '! id develop 2>/dev/null | grep -q "(docker)"'

# Check docker.service uses unix socket (not TCP)
DOCKER_SERVICE="/tmp/cks-q04/docker.service"
if [ -f "$DOCKER_SERVICE" ]; then
  check "Docker service does NOT expose TCP port (no tcp://)" \
    '! grep -q "tcp://" "$DOCKER_SERVICE"'

  check "Docker service uses unix socket (fd:// or unix://)" \
    'grep -qE "fd://|unix://" "$DOCKER_SERVICE"'
else
  # Check real Docker service
  DOCKER_SERVICE="/lib/systemd/system/docker.service"
  if [ -f "$DOCKER_SERVICE" ]; then
    check "Docker service does NOT expose TCP port" \
      '! grep -q "tcp://" "$DOCKER_SERVICE"'

    check "Docker service uses unix socket" \
      'grep -qE "fd://|unix://" "$DOCKER_SERVICE"'
  else
    echo "⚠️  INFO: Docker service file not found — skipping checks"
  fi
fi

# Check docker socket ownership
if [ -S /var/run/docker.sock ]; then
  check "Docker socket owned by root:root (not root:docker)" \
    '[ "$(stat -c %G /var/run/docker.sock 2>/dev/null)" = "root" ]'
else
  echo "  ℹ️  Docker socket not found (containerd runtime?)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All checks passed!" || exit 1
