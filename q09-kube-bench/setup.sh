#!/bin/bash

# ============================================================================
# CKS EXAM REAL QUESTION — Q09: kube-bench & CIS Remediation
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS REAL Q09: KUBE-BENCH & CIS REMEDIATION"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  kube-bench has been run on the control plane node."
echo "  Several CIS Kubernetes benchmark failures were found."
echo ""
echo "TASK:"
echo "  - Remediate the CIS benchmark failures as reported by kube-bench."
echo "  - Make the necessary changes to the static pod manifests for kube-apiserver, kube-scheduler, and kube-controller-manager."
echo "  - Verify the fixes with kube-bench after remediation."
echo ""
echo "=================================================================="
echo "  Setting up environment..."
echo "=================================================================="

# Backup current manifests
mkdir -p /tmp/cks-q09/backups
for component in kube-apiserver kube-scheduler kube-controller-manager; do
  if [ -f /etc/kubernetes/manifests/${component}.yaml ]; then
    cp /etc/kubernetes/manifests/${component}.yaml /tmp/cks-q09/backups/${component}.yaml.bak
  fi
done

# Check if --profiling is already set and show current state
echo ""
echo "Current state of --profiling flag:"
for component in kube-apiserver kube-scheduler kube-controller-manager; do
  if [ -f /etc/kubernetes/manifests/${component}.yaml ]; then
    PROFILING=$(grep -c "\-\-profiling" /etc/kubernetes/manifests/${component}.yaml 2>/dev/null || echo "0")
    if [ "$PROFILING" = "0" ]; then
      echo "  ${component}: --profiling NOT SET (needs to be added)"
    else
      echo "  ${component}: $(grep "\-\-profiling" /etc/kubernetes/manifests/${component}.yaml | xargs)"
    fi
  else
    echo "  ${component}: manifest not found (not a control-plane node?)"
  fi
done

# Ensure kube-bench is installed
echo ""
if command -v kube-bench &>/dev/null; then
  echo "✅ kube-bench is available"
  echo ""
  echo "Running kube-bench to show current failures..."
  echo "──────────────────────────────────────────────────"
  kube-bench run --targets master --check 1.3.2,1.4.1 2>/dev/null | grep -E "\[PASS\]|\[FAIL\]|\[WARN\]" || echo "  (run manually: kube-bench run --targets master)"
  echo "──────────────────────────────────────────────────"
else
  echo "⚠️  kube-bench is NOT installed."
  echo "   Run 'bash install-prereqs.sh' from the project root to install it."
  echo "   You can still fix the manifests manually, but won't be able to"
  echo "   verify with kube-bench."
fi

echo ""
echo "✅ Environment ready!"
echo ""
echo "HINTS:"
echo "  - Edit the static pod manifests in /etc/kubernetes/manifests/"
echo "  - Add '--profiling=false' to the command args"
echo "  - Pods restart automatically when manifests change"
echo "  - Use: kubectl get pods -n kube-system to monitor restart"
echo ""
echo "Backups saved at: /tmp/cks-q09/backups/"
echo ""
echo "Run 'bash verify.sh' after solving to check your answer."
