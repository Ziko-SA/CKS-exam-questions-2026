#!/bin/bash
# ============================================================================
# CKS Q16: Worker Node Upgrade — Verify Solution
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
echo "  VERIFYING Q16: WORKER NODE UPGRADE"
echo "=================================================================="
echo ""

TARGET_VERSION="1.33.1"

# Detect worker node
WORKER=$(kubectl get nodes --no-headers 2>/dev/null | grep -v "control-plane\|master" | awk '{print $1}' | head -1)

if [ -z "$WORKER" ]; then
  echo "⚠️  No worker node found — this question requires a multi-node cluster"
  exit 1
fi

echo "Worker node: $WORKER"
echo ""

# Check worker node version
WORKER_VERSION=$(kubectl get node "$WORKER" -o jsonpath="{.status.nodeInfo.kubeletVersion}" 2>/dev/null)
check "Worker node kubelet is at v${TARGET_VERSION}" \
  'echo "$WORKER_VERSION" | grep -q "$TARGET_VERSION"'

# Check worker node is Ready
check "Worker node is in Ready state" \
  'kubectl get node "$WORKER" --no-headers 2>/dev/null | grep -q " Ready"'

# Check worker node is NOT cordoned
check "Worker node is NOT cordoned (SchedulingDisabled)" \
  '! kubectl get node "$WORKER" --no-headers 2>/dev/null | grep -q "SchedulingDisabled"'

# Check worker node can schedule pods
check "Worker node can accept pod scheduling" \
  '! kubectl get node "$WORKER" -o jsonpath="{.spec.unschedulable}" 2>/dev/null | grep -q "true"'

# Check kube-proxy version on the worker
PROXY_VERSION=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy -o jsonpath="{.items[*].status.containerStatuses[0].image}" 2>/dev/null)
if [ -n "$PROXY_VERSION" ]; then
  check "kube-proxy image includes target version" \
    'echo "$PROXY_VERSION" | grep -q "$TARGET_VERSION"'
fi

echo ""
echo "Current node versions:"
kubectl get nodes -o wide 2>/dev/null
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All checks passed!" || exit 1
