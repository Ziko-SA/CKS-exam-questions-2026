#!/bin/bash
# ============================================================================
# CKS Q09: Kube-bench — Verify Solution
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
echo "  VERIFYING Q09: KUBE-BENCH — CIS BENCHMARKS"
echo "=================================================================="
echo ""

MANIFESTS_DIR="/etc/kubernetes/manifests"

# Check --profiling=false in kube-apiserver
check "kube-apiserver has --profiling=false" \
  'grep -q "\-\-profiling=false" "$MANIFESTS_DIR/kube-apiserver.yaml" 2>/dev/null'

# Check --profiling=false in kube-scheduler
check "kube-scheduler has --profiling=false" \
  'grep -q "\-\-profiling=false" "$MANIFESTS_DIR/kube-scheduler.yaml" 2>/dev/null'

# Check --profiling=false in kube-controller-manager
check "kube-controller-manager has --profiling=false" \
  'grep -q "\-\-profiling=false" "$MANIFESTS_DIR/kube-controller-manager.yaml" 2>/dev/null'

# Check components are still running after modification
check "kube-apiserver pod is running" \
  'kubectl get pods -n kube-system -l component=kube-apiserver --no-headers 2>/dev/null | grep -q "Running"'

check "kube-scheduler pod is running" \
  'kubectl get pods -n kube-system -l component=kube-scheduler --no-headers 2>/dev/null | grep -q "Running"'

check "kube-controller-manager pod is running" \
  'kubectl get pods -n kube-system -l component=kube-controller-manager --no-headers 2>/dev/null | grep -q "Running"'

# Run kube-bench to verify fixes if available
if command -v kube-bench &>/dev/null; then
  echo ""
  echo "Running kube-bench to verify profiling fix..."
  BENCH_OUTPUT=$(kube-bench run --targets master --check 1.3.2,1.4.1 2>/dev/null)
  BENCH_PASS=$(echo "$BENCH_OUTPUT" | grep -c "\[PASS\]")
  BENCH_FAIL=$(echo "$BENCH_OUTPUT" | grep -c "\[FAIL\]")
  echo "  kube-bench results: $BENCH_PASS passed, $BENCH_FAIL failed"
  if [ "$BENCH_FAIL" -eq 0 ] && [ "$BENCH_PASS" -gt 0 ]; then
    echo "✅ PASS: kube-bench profiling checks pass"; ((PASS++))
  else
    echo "❌ FAIL: kube-bench still reports profiling failures"; ((FAIL++))
  fi
else
  echo "  ℹ️  kube-bench not installed — run 'bash install-prereqs.sh' to install"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All checks passed!" || exit 1
