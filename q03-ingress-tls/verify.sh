#!/bin/bash
# ============================================================================
# CKS Q03: Ingress TLS — Verify Solution
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
echo "  VERIFYING Q03: INGRESS WITH TLS & SSL REDIRECT"
echo "=================================================================="
echo ""

# Check Ingress resource exists
check "Ingress resource exists in 'web' namespace" \
  'kubectl get ingress -n web --no-headers 2>/dev/null | grep -q "."'

# Check TLS is configured on the Ingress
check "Ingress has TLS configuration" \
  'kubectl get ingress -n web -o jsonpath="{.items[*].spec.tls}" 2>/dev/null | grep -q "web-tls-secret"'

# Check TLS secret reference
check "Ingress references secret 'web-tls-secret'" \
  'kubectl get ingress -n web -o jsonpath="{.items[*].spec.tls[*].secretName}" 2>/dev/null | grep -q "web-tls-secret"'

# Check ssl-redirect annotation
check "Ingress has ssl-redirect annotation set to true" \
  'kubectl get ingress -n web -o jsonpath="{.items[*].metadata.annotations}" 2>/dev/null | grep -q "ssl-redirect.*true\|ssl-redirect.*\"true\""'

# Check Ingress has rules pointing to the service
check "Ingress has rules with backend service 'web-svc'" \
  'kubectl get ingress -n web -o jsonpath="{.items[*].spec.rules[*].http.paths[*].backend.service.name}" 2>/dev/null | grep -q "web-svc"'

# Check Ingress has a host or TLS host defined
check "Ingress has host defined in TLS or rules" \
  'kubectl get ingress -n web -o json 2>/dev/null | grep -q "host"'

# Check Ingress Controller is running
check "NGINX Ingress Controller is running" \
  'kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller --no-headers 2>/dev/null | grep -q "Running"'

# Check Ingress gets an address assigned
INGRESS_ADDR=$(kubectl get ingress -n web -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}" 2>/dev/null)
if [ -n "$INGRESS_ADDR" ]; then
  echo "✅ PASS: Ingress has address assigned ($INGRESS_ADDR)"; ((PASS++))
else
  echo "⚠️  INFO: Ingress has no address yet (may need NodePort on baremetal — check ingress-nginx service)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All checks passed!" || exit 1
