#!/bin/bash
# ============================================================================
# CKS Q13: Pod Security Standards — Verify Solution
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
echo "  VERIFYING Q13: POD SECURITY STANDARDS (PSS)"
echo "=================================================================="
echo ""

# Check namespace has PSS restricted enforcement
check "'restricted' namespace has PSS enforce=restricted label" \
  'kubectl get ns restricted -o jsonpath="{.metadata.labels}" 2>/dev/null | grep -q "pod-security.kubernetes.io/enforce.*restricted"'

# Check deployment exists and pods are running
check "Deployment exists in 'restricted' namespace" \
  'kubectl get deploy -n restricted --no-headers 2>/dev/null | grep -q "."'

check "Pods are running in 'restricted' namespace" \
  'kubectl get pods -n restricted --no-headers 2>/dev/null | grep -q "Running"'

# Check security context fixes
DEPLOY_JSON=$(kubectl get deploy -n restricted -o json 2>/dev/null)

check "Container has allowPrivilegeEscalation: false" \
  'echo "$DEPLOY_JSON" | grep -q "\"allowPrivilegeEscalation\":false\|allowPrivilegeEscalation: false"'

check "Container has runAsNonRoot: true" \
  'echo "$DEPLOY_JSON" | grep -q "\"runAsNonRoot\":true\|runAsNonRoot: true"'

check "Container drops ALL capabilities" \
  'echo "$DEPLOY_JSON" | grep -q "ALL"'

check "Container does NOT have privileged: true" \
  '! echo "$DEPLOY_JSON" | grep -q "\"privileged\":true\|privileged: true"'

check "Container does NOT run as user 0 (root)" \
  '! echo "$DEPLOY_JSON" | grep -q "\"runAsUser\":0\|runAsUser: 0"'

check "Container has seccompProfile set" \
  'echo "$DEPLOY_JSON" | grep -q "seccompProfile"'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All checks passed!" || exit 1
