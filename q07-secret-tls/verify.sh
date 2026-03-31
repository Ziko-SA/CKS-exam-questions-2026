#!/bin/bash
# ============================================================================
# CKS Q07: Secret TLS — Verify Solution
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
echo "  VERIFYING Q07: SECRET TLS"
echo "=================================================================="
echo ""

# Check TLS secret exists
check "TLS secret exists in 'secure' namespace" \
  'kubectl get secret -n secure --field-selector type=kubernetes.io/tls --no-headers 2>/dev/null | grep -q "."'

# Check secret has tls.crt and tls.key
SECRET_NAME=$(kubectl get secret -n secure --field-selector type=kubernetes.io/tls -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
check "TLS secret contains tls.crt key" \
  'kubectl get secret "$SECRET_NAME" -n secure -o jsonpath="{.data}" 2>/dev/null | grep -q "tls.crt"'

check "TLS secret contains tls.key key" \
  'kubectl get secret "$SECRET_NAME" -n secure -o jsonpath="{.data}" 2>/dev/null | grep -q "tls.key"'

# Check deployment has volume mount
check "secure-app deployment has volume mount at /etc/tls" \
  'kubectl get deploy secure-app -n secure -o jsonpath="{.spec.template.spec.containers[*].volumeMounts}" 2>/dev/null | grep -q "/etc/tls"'

# Check deployment has volume referencing the secret
check "secure-app deployment has a volume referencing the TLS secret" \
  'kubectl get deploy secure-app -n secure -o jsonpath="{.spec.template.spec.volumes}" 2>/dev/null | grep -q "secret\|Secret"'

# Check pod is running
check "secure-app pod is running" \
  'kubectl get pods -n secure -l app=secure-app --no-headers 2>/dev/null | grep -q "Running"'

# Check the TLS files exist inside the pod
POD=$(kubectl get pods -n secure -l app=secure-app -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
if [ -n "$POD" ]; then
  check "tls.crt is mounted inside pod at /etc/tls" \
    'kubectl exec "$POD" -n secure -- ls /etc/tls/tls.crt 2>/dev/null'

  check "tls.key is mounted inside pod at /etc/tls" \
    'kubectl exec "$POD" -n secure -- ls /etc/tls/tls.key 2>/dev/null'
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All checks passed!" || exit 1
