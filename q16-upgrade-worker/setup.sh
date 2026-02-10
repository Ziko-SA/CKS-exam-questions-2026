#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q16: Upgrade Worker Node
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS PRACTICE Q16: UPGRADE WORKER NODE"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  The cluster control plane has already been upgraded to v1.33.1."
echo "  The worker node is still on v1.33.0 and needs to be upgraded."
echo ""
echo "TASK:"
echo "  Upgrade the worker node from Kubernetes v1.33.0 to v1.33.1:"
echo ""
echo "  1. Cordon the worker node (prevent new pods from being scheduled)"
echo "  2. Drain the worker node (evict existing pods safely)"
echo "  3. SSH to the worker node"
echo "  4. Upgrade kubeadm to v1.33.1"
echo "  5. Run 'kubeadm upgrade node'"
echo "  6. Upgrade kubelet and kubectl to v1.33.1"
echo "  7. Restart kubelet"
echo "  8. Exit back to control-plane node"
echo "  9. Uncordon the worker node"
echo ""
echo "IMPORTANT:"
echo "  - Do NOT upgrade the control plane (already done)"
echo "  - Only upgrade the worker node"
echo "  - Ensure pods are rescheduled after uncordoning"
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
echo "Run 'bash solution.sh' when ready to see the answer."
