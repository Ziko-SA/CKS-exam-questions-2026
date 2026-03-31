#!/bin/bash
# ============================================================================
# CKS Q01: Falco — Verify Solution
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
echo "  VERIFYING Q01: FALCO — RUNTIME SECURITY"
echo "=================================================================="
echo ""

# Check that offending deployments are scaled to 0
check "nvidia-app scaled to 0 replicas" \
  '[ "$(kubectl get deploy nvidia-app -n monitoring -o jsonpath="{.spec.replicas}" 2>/dev/null)" = "0" ]'

check "cpu-app scaled to 0 replicas" \
  '[ "$(kubectl get deploy cpu-app -n monitoring -o jsonpath="{.spec.replicas}" 2>/dev/null)" = "0" ]'

check "ollama-app scaled to 0 replicas" \
  '[ "$(kubectl get deploy ollama-app -n monitoring -o jsonpath="{.spec.replicas}" 2>/dev/null)" = "0" ]'

# Check that safe-app is still running
check "safe-app is NOT scaled down (still running)" \
  '[ "$(kubectl get deploy safe-app -n monitoring -o jsonpath="{.spec.replicas}" 2>/dev/null)" -ge 1 ]'

# Check no pods from offending deployments remain
check "No nvidia-app pods running" \
  '[ "$(kubectl get pods -n monitoring -l app=nvidia-app --no-headers 2>/dev/null | wc -l)" -eq 0 ]'

check "No cpu-app pods running" \
  '[ "$(kubectl get pods -n monitoring -l app=cpu-app --no-headers 2>/dev/null | wc -l)" -eq 0 ]'

check "No ollama-app pods running" \
  '[ "$(kubectl get pods -n monitoring -l app=ollama-app --no-headers 2>/dev/null | wc -l)" -eq 0 ]'

# Check deployments still exist (not deleted)
check "nvidia-app deployment still exists (not deleted)" \
  'kubectl get deploy nvidia-app -n monitoring &>/dev/null'

check "cpu-app deployment still exists (not deleted)" \
  'kubectl get deploy cpu-app -n monitoring &>/dev/null'

check "ollama-app deployment still exists (not deleted)" \
  'kubectl get deploy ollama-app -n monitoring &>/dev/null'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All checks passed!" || exit 1
