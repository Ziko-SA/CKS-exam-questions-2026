#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q16 SOLUTION: Upgrade Worker Node
# ============================================================================

echo "=================================================================="
echo "  SOLUTION Q16: UPGRADE WORKER NODE (1.33.0 → 1.33.1)"
echo "=================================================================="
echo ""

WORKER_NODE=$(kubectl get nodes --no-headers 2>/dev/null | grep -v "control-plane\|master" | awk '{print $1}' | head -1)
if [ -z "$WORKER_NODE" ]; then
  WORKER_NODE="node01"
fi

echo "Worker node: $WORKER_NODE"
echo ""

echo "STEP 1: Cordon the worker node (on control-plane)"
echo "--------"
echo "$ kubectl cordon $WORKER_NODE"
kubectl cordon $WORKER_NODE 2>/dev/null || echo "(simulated: node cordoned)"
echo ""

echo "STEP 2: Drain the worker node (on control-plane)"
echo "--------"
echo "$ kubectl drain $WORKER_NODE --ignore-daemonsets --delete-emptydir-data --force"
kubectl drain $WORKER_NODE --ignore-daemonsets --delete-emptydir-data --force 2>/dev/null || echo "(simulated: node drained)"
echo ""

echo "STEP 3: SSH to the worker node"
echo "--------"
echo "$ ssh $WORKER_NODE"
echo "(In KillerCoda, use: ssh node01)"
echo ""

echo "STEP 4: Upgrade kubeadm on the worker node"
echo "--------"
echo "Run these commands ON THE WORKER NODE:"
echo ""
cat <<'CMDS'
# Update package repo
apt-get update

# Check available versions
apt-cache madison kubeadm | head -5

# Install kubeadm 1.33.1
apt-mark unhold kubeadm
apt-get install -y kubeadm=1.33.1-1.1
apt-mark hold kubeadm

# Verify kubeadm version
kubeadm version
CMDS
echo ""

echo "STEP 5: Run kubeadm upgrade on the worker"
echo "--------"
echo "Run on the worker node:"
echo ""
cat <<'CMDS'
# For worker nodes, use 'kubeadm upgrade node' (NOT 'kubeadm upgrade apply')
sudo kubeadm upgrade node
CMDS
echo ""

echo "STEP 6: Upgrade kubelet and kubectl on the worker"
echo "--------"
echo "Run on the worker node:"
echo ""
cat <<'CMDS'
# Install kubelet and kubectl 1.33.1
apt-mark unhold kubelet kubectl
apt-get install -y kubelet=1.33.1-1.1 kubectl=1.33.1-1.1
apt-mark hold kubelet kubectl
CMDS
echo ""

echo "STEP 7: Restart kubelet on the worker"
echo "--------"
echo "Run on the worker node:"
echo ""
cat <<'CMDS'
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Verify kubelet is running
sudo systemctl status kubelet
CMDS
echo ""

echo "STEP 8: Exit back to control-plane"
echo "--------"
echo "$ exit"
echo ""

echo "STEP 9: Uncordon the worker node (on control-plane)"
echo "--------"
echo "$ kubectl uncordon $WORKER_NODE"
kubectl uncordon $WORKER_NODE 2>/dev/null || echo "(simulated: node uncordoned)"
echo ""

echo "STEP 10: Verify the upgrade"
echo "--------"
echo "$ kubectl get nodes"
kubectl get nodes 2>/dev/null || echo "(check nodes after upgrade)"
echo ""

echo "=================================================================="
echo "  ✅ SOLUTION COMPLETE"
echo "=================================================================="
echo ""
echo "COMPLETE COMMAND SEQUENCE:"
echo ""
echo "  === On Control Plane ==="
echo "  kubectl cordon $WORKER_NODE"
echo "  kubectl drain $WORKER_NODE --ignore-daemonsets --delete-emptydir-data --force"
echo "  ssh $WORKER_NODE"
echo ""
echo "  === On Worker Node ==="
echo "  apt-get update"
echo "  apt-mark unhold kubeadm"
echo "  apt-get install -y kubeadm=1.33.1-1.1"
echo "  apt-mark hold kubeadm"
echo "  sudo kubeadm upgrade node"
echo "  apt-mark unhold kubelet kubectl"
echo "  apt-get install -y kubelet=1.33.1-1.1 kubectl=1.33.1-1.1"
echo "  apt-mark hold kubelet kubectl"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl restart kubelet"
echo "  exit"
echo ""
echo "  === Back on Control Plane ==="
echo "  kubectl uncordon $WORKER_NODE"
echo "  kubectl get nodes"
echo ""
echo "KEY POINTS:"
echo "  1. Worker nodes use 'kubeadm upgrade node' (NOT 'kubeadm upgrade apply')"
echo "  2. Always cordon + drain BEFORE upgrading"
echo "  3. Always uncordon AFTER upgrading"
echo "  4. apt-mark hold/unhold to manage package versions"
echo "  5. systemctl daemon-reload + restart kubelet after upgrade"
echo "  6. The version format may be 1.33.1-1.1 (check with apt-cache madison)"
