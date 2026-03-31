#!/bin/bash
# ============================================================================
# CKS Q12: Network Policies — Verify Solution
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
echo "  VERIFYING Q12: NETWORK POLICIES"
echo "=================================================================="
echo ""

# Check default-deny policy exists in backend namespace
check "Default-deny NetworkPolicy exists in 'backend' namespace" \
  'kubectl get networkpolicy -n backend --no-headers 2>/dev/null | grep -qi "deny"'

# Check the deny-all policy has empty podSelector (applies to all pods)
check "Default-deny policy applies to all pods (empty podSelector)" \
  'kubectl get networkpolicy -n backend -o json 2>/dev/null | python3 -c "
import json,sys
data=json.load(sys.stdin)
for item in data.get(\"items\",[]):
  if item[\"spec\"][\"podSelector\"]=={} or item[\"spec\"][\"podSelector\"].get(\"matchLabels\",None) is None:
    sys.exit(0)
sys.exit(1)
" 2>/dev/null || kubectl get networkpolicy -n backend -o jsonpath="{.items[*].spec.podSelector}" 2>/dev/null | grep -q "{}"'

# Check allow policy for frontend->backend exists
ALLOW_POLICIES=$(kubectl get networkpolicy -n backend -o json 2>/dev/null)
check "Allow NetworkPolicy exists for frontend->backend traffic" \
  'echo "$ALLOW_POLICIES" | grep -q "frontend\|namespaceSelector\|app.*web"'

# Check allow policy specifies port 8080
check "Allow policy specifies port 8080" \
  'echo "$ALLOW_POLICIES" | grep -q "8080"'

# Check policies have correct policy types
check "Policies have Ingress policy type" \
  'kubectl get networkpolicy -n backend -o jsonpath="{.items[*].spec.policyTypes}" 2>/dev/null | grep -q "Ingress"'

# Functional connectivity tests
echo ""
echo "Running connectivity tests..."

WEB_POD=$(kubectl get pods -n frontend -l app=web -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
MAL_POD=$(kubectl get pods -n backend -l app=malicious-app -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
API_SVC_IP=$(kubectl get svc api-server -n backend -o jsonpath="{.spec.clusterIP}" 2>/dev/null)

if [ -n "$WEB_POD" ] && [ -n "$API_SVC_IP" ]; then
  # Test: frontend web pod CAN reach backend api-server on port 8080
  RESULT=$(kubectl exec "$WEB_POD" -n frontend -- wget -qO- --timeout=3 "http://${API_SVC_IP}:8080" 2>&1)
  if [ $? -eq 0 ]; then
    echo "✅ PASS: frontend/web CAN reach backend/api-server:8080"; ((PASS++))
  else
    echo "❌ FAIL: frontend/web CANNOT reach backend/api-server:8080 (should be allowed)"; ((FAIL++))
  fi
else
  echo "  ℹ️  Skipping connectivity test — pods not ready"
fi

if [ -n "$MAL_POD" ] && [ -n "$API_SVC_IP" ]; then
  # Test: malicious pod CANNOT reach api-server
  RESULT=$(kubectl exec "$MAL_POD" -n backend -- wget -qO- --timeout=3 "http://${API_SVC_IP}:8080" 2>&1)
  if [ $? -ne 0 ]; then
    echo "✅ PASS: backend/malicious-app CANNOT reach api-server (correctly blocked)"; ((PASS++))
  else
    echo "❌ FAIL: backend/malicious-app CAN reach api-server (should be blocked)"; ((FAIL++))
  fi
else
  echo "  ℹ️  Skipping malicious pod test — pods not ready"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All checks passed!" || exit 1
