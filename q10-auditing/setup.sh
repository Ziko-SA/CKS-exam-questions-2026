#!/bin/bash

# ============================================================================
# CKS EXAM REAL QUESTION — Q10: Kubernetes Auditing
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS REAL Q10: KUBERNETES AUDITING"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  Audit logging is not currently enabled on the kube-apiserver."
echo ""
echo "TASK:"
echo "  - Create an audit policy file at /etc/kubernetes/audit/policy.yaml with rules to:"
echo "    * Log Secret resources at Metadata level in all namespaces."
echo "    * Log Pod resources at RequestResponse level in namespace 'prod'."
echo "    * Log all other requests at Request level."
echo "  - Configure the kube-apiserver to use this audit policy and log to /var/log/kubernetes/audit/audit.log."
echo "  - Mount the necessary volumes in the apiserver static pod manifest."
echo "  - Ensure the apiserver restarts successfully and the audit log directory exists."
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
echo "Run 'bash verify.sh' after solving to check your answer."
