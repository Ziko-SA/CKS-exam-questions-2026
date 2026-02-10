#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q09: Kube-bench — Fix CIS Issues
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS PRACTICE Q09: KUBE-BENCH — FIX 3 CIS ISSUES"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  Run kube-bench to check CIS Kubernetes benchmarks on the"
echo "  control plane node. Fix the 3 issues identified below."
echo ""
echo "TASK:"
echo "  Fix the following 3 CIS benchmark failures:"
echo ""
echo "  Issue 1: Ensure that the --profiling argument is set to false"
echo "     on the kube-apiserver"
echo "     File: /etc/kubernetes/manifests/kube-apiserver.yaml"
echo ""
echo "  Issue 2: Ensure that the --profiling argument is set to false"
echo "     on the kube-scheduler"
echo "     File: /etc/kubernetes/manifests/kube-scheduler.yaml"
echo ""
echo "  Issue 3: Ensure that the --profiling argument is set to false"
echo "     on the kube-controller-manager"
echo "     File: /etc/kubernetes/manifests/kube-controller-manager.yaml"
echo ""
echo "IMPORTANT:"
echo "  - After each change, the static pod will restart automatically"
echo "  - Wait for the component to come back before making the next change"
echo "  - Verify the fix with kube-bench after all changes"
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
echo "Run 'bash solution.sh' when ready to see the answer."
