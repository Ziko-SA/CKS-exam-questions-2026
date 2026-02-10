#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q10 SOLUTION: Auditing
# ============================================================================

echo "=================================================================="
echo "  SOLUTION Q10: KUBERNETES AUDITING"
echo "=================================================================="
echo ""

echo "STEP 1: Create the audit policy file"
echo "--------"

mkdir -p /etc/kubernetes/audit
mkdir -p /var/log/kubernetes/audit

cat <<'EOF' > /etc/kubernetes/audit/policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  # Log Secret access at Metadata level
  - level: Metadata
    resources:
    - group: ""
      resources: ["secrets"]

  # Log Pod operations at RequestResponse level in namespace 'prod'
  - level: RequestResponse
    resources:
    - group: ""
      resources: ["pods"]
    namespaces: ["prod"]

  # Log everything else at Request level
  - level: Request
    resources:
    - group: ""
      resources: ["*"]
EOF

echo "Audit policy created:"
cat /etc/kubernetes/audit/policy.yaml
echo ""

echo "STEP 2: Edit the kube-apiserver manifest"
echo "--------"
echo "Add these flags to the kube-apiserver command:"
echo "  --audit-policy-file=/etc/kubernetes/audit/policy.yaml"
echo "  --audit-log-path=/var/log/kubernetes/audit/audit.log"
echo "  --audit-log-maxage=30"
echo "  --audit-log-maxbackup=10"
echo "  --audit-log-maxsize=100"
echo ""

APISERVER="/etc/kubernetes/manifests/kube-apiserver.yaml"

if [ -f "$APISERVER" ]; then
  # Check if audit is already configured
  if ! grep -q "audit-policy-file" "$APISERVER"; then
    # Add audit flags
    sed -i '/- --tls-private-key-file/a\    - --audit-policy-file=/etc/kubernetes/audit/policy.yaml\n    - --audit-log-path=/var/log/kubernetes/audit/audit.log\n    - --audit-log-maxage=30\n    - --audit-log-maxbackup=10\n    - --audit-log-maxsize=100' "$APISERVER"

    # Add volume mounts (inside containers[0].volumeMounts)
    # Find the last volumeMount and add after it
    if ! grep -q "name: audit-policy" "$APISERVER"; then
      sed -i '/volumeMounts:/a\    - mountPath: /etc/kubernetes/audit\n      name: audit-policy\n      readOnly: true\n    - mountPath: /var/log/kubernetes/audit\n      name: audit-log' "$APISERVER"
    fi

    # Add volumes (inside spec.volumes)
    if ! grep -q "name: audit-policy" "$APISERVER" || true; then
      sed -i '/volumes:/a\  - hostPath:\n      path: /etc/kubernetes/audit\n      type: DirectoryOrCreate\n    name: audit-policy\n  - hostPath:\n      path: /var/log/kubernetes/audit\n      type: DirectoryOrCreate\n    name: audit-log' "$APISERVER"
    fi

    echo "✅ kube-apiserver manifest updated"
  else
    echo "Audit already configured in apiserver"
  fi

  echo ""
  echo "Waiting for kube-apiserver to restart..."
  sleep 15
  kubectl wait --for=condition=Ready pod -l component=kube-apiserver -n kube-system --timeout=120s 2>/dev/null || true
else
  echo "⚠ kube-apiserver manifest not found. Showing the manual steps:"
  echo ""
  echo "Add to spec.containers[0].command:"
  cat <<'YAML'
    - --audit-policy-file=/etc/kubernetes/audit/policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit/audit.log
    - --audit-log-maxage=30
    - --audit-log-maxbackup=10
    - --audit-log-maxsize=100
YAML
  echo ""
  echo "Add to spec.containers[0].volumeMounts:"
  cat <<'YAML'
    - mountPath: /etc/kubernetes/audit
      name: audit-policy
      readOnly: true
    - mountPath: /var/log/kubernetes/audit
      name: audit-log
YAML
  echo ""
  echo "Add to spec.volumes:"
  cat <<'YAML'
  - hostPath:
      path: /etc/kubernetes/audit
      type: DirectoryOrCreate
    name: audit-policy
  - hostPath:
      path: /var/log/kubernetes/audit
      type: DirectoryOrCreate
    name: audit-log
YAML
fi
echo ""

echo "STEP 3: Verify audit logs"
echo "--------"
echo '$ ls -la /var/log/kubernetes/audit/'
ls -la /var/log/kubernetes/audit/ 2>/dev/null || echo "(logs will appear after apiserver restarts)"
echo ""
echo '$ tail -5 /var/log/kubernetes/audit/audit.log'
tail -5 /var/log/kubernetes/audit/audit.log 2>/dev/null || echo "(no logs yet)"
echo ""

echo "=================================================================="
echo "  ✅ SOLUTION COMPLETE"
echo "=================================================================="
echo ""
echo "KEY POINTS:"
echo "  1. Create audit policy YAML (rules evaluated in order, first match wins)"
echo "  2. Add 5 flags to kube-apiserver: audit-policy-file, audit-log-path,"
echo "     audit-log-maxage, audit-log-maxbackup, audit-log-maxsize"
echo "  3. Mount TWO hostPath volumes:"
echo "     - /etc/kubernetes/audit (policy, readOnly)"
echo "     - /var/log/kubernetes/audit (logs, writable)"
echo "  4. Wait for apiserver to restart and verify"
echo "  5. Audit levels: None < Metadata < Request < RequestResponse"
