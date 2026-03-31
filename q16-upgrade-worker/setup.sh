#!/bin/bash

# ============================================================================
# CKS EXAM REAL QUESTION — Q16: Upgrade Worker Node
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS REAL Q16: UPGRADE WORKER NODE"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  The control plane has already been upgraded to Kubernetes v1.33.1."
echo "  The worker node is still running v1.33.0 and must be upgraded."
echo ""
echo "TASK:"
echo "  - Upgrade the worker node from Kubernetes v1.33.0 to v1.33.1."
echo "  - Do NOT upgrade the control plane."
echo "  - Ensure pods are rescheduled after the upgrade."
echo ""
echo "=================================================================="
echo "  Setting up environment (simulated)..."
echo "=================================================================="

# Check node status
echo ""
echo "Current cluster nodes:"
kubectl get nodes -o wide 2>/dev/null || echo "(Could not connect to cluster)"
echo ""

WORKER_NODE=$(kubectl get nodes --no-headers 2>/dev/null | grep -v "control-plane\|master" | awk '{print $1}' | head -1)
if [ -n "$WORKER_NODE" ]; then
  echo "Worker node detected: $WORKER_NODE"
  echo "Current version: $(kubectl get node $WORKER_NODE -o jsonpath='{.status.nodeInfo.kubeletVersion}' 2>/dev/null)"
else
  echo "No worker node detected. In the CKS exam, you will have a worker node."
  echo "Setting WORKER_NODE=node01 for practice reference."
  WORKER_NODE="node01"
fi

echo ""
echo "✅ Environment ready!"
echo ""
echo "Worker node to upgrade: $WORKER_NODE"
echo ""
echo "HINTS:"
echo "  - Step order: cordon → drain → ssh → upgrade kubeadm → kubeadm upgrade"
echo "    → upgrade kubelet/kubectl → restart kubelet → exit → uncordon"
echo "  - Use: apt-get update && apt-get install -y kubeadm=1.33.1-*"
echo "  - Use: apt-get install -y kubelet=1.33.1-* kubectl=1.33.1-*"
echo ""
echo "Run 'bash verify.sh' after solving to check your answer."
