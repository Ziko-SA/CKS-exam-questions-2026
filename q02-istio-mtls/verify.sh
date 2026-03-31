#!/bin/bash
# ============================================================================
# CKS Q02: Istio mTLS — Verify Solution
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
echo "  VERIFYING Q02: ISTIO — mTLS & SIDECAR INJECTION"
echo "=================================================================="
echo ""

# Check namespace label for sidecar injection
check "webapp namespace has istio-injection=enabled label" \
  'kubectl get ns webapp -o jsonpath="{.metadata.labels.istio-injection}" 2>/dev/null | grep -q "enabled"'

# Check PeerAuthentication exists
check "PeerAuthentication exists in webapp namespace" \
  'kubectl get peerauthentication -n webapp 2>/dev/null | grep -q "."'

# Check PeerAuthentication has STRICT mode
check "PeerAuthentication mode is STRICT" \
  'kubectl get peerauthentication -n webapp -o jsonpath="{.items[*].spec.mtls.mode}" 2>/dev/null | grep -qi "STRICT"'

# Check deployment was restarted (pods should have recent start time or 2 containers with Istio)
if command -v istioctl &>/dev/null; then
  check "web-frontend pods have Istio sidecar (2/2 containers)" \
    'kubectl get pods -n webapp -l app=web-frontend -o jsonpath="{.items[0].spec.containers[*].name}" 2>/dev/null | grep -q "istio-proxy"'
else
  check "web-frontend deployment has been rolled out (restart annotation present)" \
    'kubectl get deploy web-frontend -n webapp -o jsonpath="{.spec.template.metadata.annotations}" 2>/dev/null | grep -q "restartedAt\|kubectl.kubernetes.io"'
  echo "  ℹ️  Istio not installed — sidecar injection cannot be fully verified"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All checks passed!" || exit 1
