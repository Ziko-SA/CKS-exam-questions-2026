#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q10: Auditing
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS PRACTICE Q10: KUBERNETES AUDITING"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  You need to configure audit logging on the kube-apiserver."
echo ""
echo "TASK:"
echo "  1. Create an audit policy file at /etc/kubernetes/audit/policy.yaml"
echo "     with the following rules:"
echo ""
echo "     a. Log Secret resources at the Metadata level in all namespaces"
echo "     b. Log Pod resources at the RequestResponse level in namespace 'prod'"
echo "     c. Log everything else at the Request level"
echo ""
echo "  2. Configure the kube-apiserver to use this audit policy:"
echo "     - --audit-policy-file=/etc/kubernetes/audit/policy.yaml"
echo "     - --audit-log-path=/var/log/kubernetes/audit/audit.log"
echo "     - --audit-log-maxage=30"
echo "     - --audit-log-maxbackup=10"
echo "     - --audit-log-maxsize=100"
echo ""
echo "  3. Mount the necessary volumes in the apiserver static pod"
echo ""
echo "IMPORTANT:"
echo "  - Ensure the apiserver restarts successfully"
echo "  - The audit log directory must exist"
echo ""
echo "=================================================================="
echo "  Setting up environment..."
echo "=================================================================="

# Create directories
mkdir -p /etc/kubernetes/audit
mkdir -p /var/log/kubernetes/audit

# Backup apiserver manifest
if [ -f /etc/kubernetes/manifests/kube-apiserver.yaml ]; then
  cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kube-apiserver.yaml.bak.q10
fi

echo ""
echo "✅ Environment ready!"
echo ""
echo "Directories created:"
echo "  /etc/kubernetes/audit/        — for the audit policy"
echo "  /var/log/kubernetes/audit/    — for the audit logs"
echo ""
echo "HINTS:"
echo "  - Create the policy file first, then edit the apiserver"
echo "  - Policy rules are evaluated in order; first match wins"
echo "  - Need both hostPath volumes AND volumeMounts"
echo "  - Don't forget: the audit log directory must be mounted too"
echo ""
echo "Run 'bash solution.sh' when ready to see the answer."
