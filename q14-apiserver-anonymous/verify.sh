#!/bin/bash
# ============================================================================
# CKS Q14: API Server Anonymous Auth — Verify Solution
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
echo "  VERIFYING Q14: KUBE-APISERVER ANONYMOUS AUTHENTICATION"
echo "=================================================================="
echo ""

APISERVER="/etc/kubernetes/manifests/kube-apiserver.yaml"

# Check --anonymous-auth=false
check "kube-apiserver has --anonymous-auth=false" \
  'grep -q "\-\-anonymous-auth=false" "$APISERVER" 2>/dev/null'

# Check insecure ClusterRoleBinding is deleted
check "system:anonymous ClusterRoleBinding is deleted" \
  '! kubectl get clusterrolebinding system:anonymous &>/dev/null'

# Check apiserver is running
check "kube-apiserver pod is running after changes" \
  'kubectl get pods -n kube-system -l component=kube-apiserver --no-headers 2>/dev/null | grep -q "Running"'

# Check cluster is functional
check "kubectl can still communicate with the API server" \
  'kubectl get nodes &>/dev/null'

# Functional test: anonymous request should be denied
APISERVER_IP=$(kubectl get pods -n kube-system -l component=kube-apiserver -o jsonpath="{.items[0].status.podIP}" 2>/dev/null)
if [ -n "$APISERVER_IP" ]; then
  ANON_RESULT=$(curl -sk "https://${APISERVER_IP}:6443/api/v1/namespaces" 2>&1)
  if echo "$ANON_RESULT" | grep -qi "forbidden\|unauthorized\|Unauthorized"; then
    echo "✅ PASS: Anonymous API request correctly returns Forbidden/Unauthorized"; ((PASS++))
  else
    echo "❌ FAIL: Anonymous API request was not denied"; ((FAIL++))
  fi
else
  echo "  ℹ️  Could not determine apiserver IP for anonymous request test"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All checks passed!" || exit 1
