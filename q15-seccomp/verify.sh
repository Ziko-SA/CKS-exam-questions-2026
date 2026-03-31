#!/bin/bash
# ============================================================================
# CKS Q15: Seccomp Profiles — Verify Solution
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
echo "  VERIFYING Q15: SECCOMP PROFILE APPLICATION"
echo "=================================================================="
echo ""

# Check seccomp profile files exist on the node
check "audit.json profile exists at /var/lib/kubelet/seccomp/profiles/" \
  '[ -f /var/lib/kubelet/seccomp/profiles/audit.json ]'

check "restricted.json profile exists at /var/lib/kubelet/seccomp/profiles/" \
  '[ -f /var/lib/kubelet/seccomp/profiles/restricted.json ]'

# Check seccomp-pod exists with Localhost profile
check "seccomp-pod exists in secure-ns namespace" \
  'kubectl get pod seccomp-pod -n secure-ns &>/dev/null'

SECCOMP_POD_JSON=$(kubectl get pod seccomp-pod -n secure-ns -o json 2>/dev/null)
check "seccomp-pod has Localhost seccomp profile type" \
  'echo "$SECCOMP_POD_JSON" | grep -q "Localhost"'

check "seccomp-pod references profiles/audit.json" \
  'echo "$SECCOMP_POD_JSON" | grep -q "audit.json\|profiles/audit.json"'

check "seccomp-pod is running" \
  'kubectl get pod seccomp-pod -n secure-ns --no-headers 2>/dev/null | grep -q "Running"'

# Check default-seccomp-pod exists with RuntimeDefault profile
check "default-seccomp-pod exists in secure-ns namespace" \
  'kubectl get pod default-seccomp-pod -n secure-ns &>/dev/null'

DEFAULT_POD_JSON=$(kubectl get pod default-seccomp-pod -n secure-ns -o json 2>/dev/null)
check "default-seccomp-pod has RuntimeDefault seccomp profile" \
  'echo "$DEFAULT_POD_JSON" | grep -q "RuntimeDefault"'

check "default-seccomp-pod is running" \
  'kubectl get pod default-seccomp-pod -n secure-ns --no-headers 2>/dev/null | grep -q "Running"'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All checks passed!" || exit 1
