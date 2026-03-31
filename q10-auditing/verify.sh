#!/bin/bash
# ============================================================================
# CKS Q10: Kubernetes Auditing — Verify Solution
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
echo "  VERIFYING Q10: KUBERNETES AUDITING"
echo "=================================================================="
echo ""

POLICY_FILE="/etc/kubernetes/audit/policy.yaml"
APISERVER="/etc/kubernetes/manifests/kube-apiserver.yaml"
LOG_DIR="/var/log/kubernetes/audit"

# Check audit policy file exists
check "Audit policy file exists at $POLICY_FILE" \
  '[ -f "$POLICY_FILE" ]'

# Check policy has rules for Secrets
check "Audit policy has rule for Secrets at Metadata level" \
  'grep -A5 "Secret" "$POLICY_FILE" 2>/dev/null | grep -qi "Metadata"'

# Check policy has rules for Pods
check "Audit policy has rule for Pods" \
  'grep -q "pods\|Pod" "$POLICY_FILE" 2>/dev/null'

# Check apiserver has audit-policy-file flag
check "kube-apiserver has --audit-policy-file flag" \
  'grep -q "\-\-audit-policy-file" "$APISERVER" 2>/dev/null'

# Check apiserver has audit-log-path flag
check "kube-apiserver has --audit-log-path flag" \
  'grep -q "\-\-audit-log-path" "$APISERVER" 2>/dev/null'

# Check apiserver has audit-log-maxage
check "kube-apiserver has --audit-log-maxage flag" \
  'grep -q "\-\-audit-log-maxage" "$APISERVER" 2>/dev/null'

# Check apiserver has audit-log-maxbackup
check "kube-apiserver has --audit-log-maxbackup flag" \
  'grep -q "\-\-audit-log-maxbackup" "$APISERVER" 2>/dev/null'

# Check apiserver has audit-log-maxsize
check "kube-apiserver has --audit-log-maxsize flag" \
  'grep -q "\-\-audit-log-maxsize" "$APISERVER" 2>/dev/null'

# Check volume mounts exist
check "kube-apiserver has volumeMount for audit policy" \
  'grep -A2 "audit" "$APISERVER" 2>/dev/null | grep -qi "mount\|mountPath\|/etc/kubernetes/audit"'

check "kube-apiserver has volumeMount for audit logs" \
  'grep -q "/var/log/kubernetes/audit\|audit-log" "$APISERVER" 2>/dev/null'

# Check apiserver is running
check "kube-apiserver pod is running" \
  'kubectl get pods -n kube-system -l component=kube-apiserver --no-headers 2>/dev/null | grep -q "Running"'

# Check if audit log is being generated
if [ -d "$LOG_DIR" ]; then
  echo ""
  echo "Generating test API request to trigger audit..."
  kubectl get secrets -n default &>/dev/null
  sleep 2
  LOG_FILE=$(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -1)
  if [ -n "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
    echo "✅ PASS: Audit log file is being written ($LOG_FILE)"; ((PASS++))
  else
    echo "❌ FAIL: Audit log file is empty or missing"; ((FAIL++))
  fi
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All checks passed!" || exit 1
