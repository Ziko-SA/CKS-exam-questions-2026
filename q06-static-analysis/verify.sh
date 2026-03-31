#!/bin/bash
# ============================================================================
# CKS Q06: Static File Analysis — Verify Solution
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
echo "  VERIFYING Q06: STATIC FILE ANALYSIS"
echo "=================================================================="
echo ""

# Check Dockerfile fix
check "Dockerfile uses 'USER couchdb' (not 'USER root')" \
  'grep -q "^USER couchdb" /root/Dockerfile 2>/dev/null'

check "Dockerfile does NOT have 'USER root'" \
  '! grep -q "^USER root" /root/Dockerfile 2>/dev/null'

# Check deploy.yaml fix
check "deploy.yaml has 'readOnlyRootFilesystem: true'" \
  'grep -q "readOnlyRootFilesystem: true" /root/deploy.yaml 2>/dev/null'

check "deploy.yaml does NOT have 'readOnlyRootFilesystem: false'" \
  '! grep -q "readOnlyRootFilesystem: false" /root/deploy.yaml 2>/dev/null'

# Verify no lines were added or removed (same line count)
DOCKERFILE_LINES=$(wc -l < /root/Dockerfile 2>/dev/null)
DEPLOY_LINES=$(wc -l < /root/deploy.yaml 2>/dev/null)

check "Dockerfile has same number of lines (no lines added/removed)" \
  '[ "$DOCKERFILE_LINES" -eq 18 ] || [ "$DOCKERFILE_LINES" -eq 19 ] || [ "$DOCKERFILE_LINES" -eq 20 ]'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All checks passed!" || exit 1
