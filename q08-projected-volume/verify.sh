#!/bin/bash
# ============================================================================
# CKS Q08: Projected Volume — Verify Solution
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
echo "  VERIFYING Q08: PROJECTED VOLUME — SERVICE ACCOUNT TOKEN"
echo "=================================================================="
echo ""

# Check ServiceAccount has automountServiceAccountToken disabled
check "app-sa ServiceAccount has automountServiceAccountToken: false" \
  '[ "$(kubectl get sa app-sa -n tokens -o jsonpath="{.automountServiceAccountToken}" 2>/dev/null)" = "false" ]'

# Check deployment has projected volume with serviceAccountToken
check "Deployment has projected volume with serviceAccountToken source" \
  'kubectl get deploy token-app -n tokens -o json 2>/dev/null | grep -q "serviceAccountToken"'

# Check expirationSeconds is set
check "Projected token has expirationSeconds set (3600)" \
  'kubectl get deploy token-app -n tokens -o json 2>/dev/null | grep -q "expirationSeconds"'

# Check volumeMount exists
check "Deployment has volumeMount for the projected token" \
  'kubectl get deploy token-app -n tokens -o jsonpath="{.spec.template.spec.containers[*].volumeMounts}" 2>/dev/null | grep -q "."'

# Check pod is running
check "token-app pod is running" \
  'kubectl get pods -n tokens -l app=token-app --no-headers 2>/dev/null | grep -q "Running"'

# Check token file exists inside the pod
POD=$(kubectl get pods -n tokens -l app=token-app -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
if [ -n "$POD" ]; then
  check "Token file exists inside the pod" \
    'kubectl exec "$POD" -n tokens -- find /var/run/secrets -name "token" 2>/dev/null | grep -q "token"'
fi

# Check automountServiceAccountToken is false on the pod spec too
check "Pod spec has automountServiceAccountToken: false" \
  '[ "$(kubectl get deploy token-app -n tokens -o jsonpath="{.spec.template.spec.automountServiceAccountToken}" 2>/dev/null)" = "false" ]'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All checks passed!" || exit 1
