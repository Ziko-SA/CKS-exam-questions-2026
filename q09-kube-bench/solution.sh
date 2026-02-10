#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q09 SOLUTION: Kube-bench — Fix CIS Issues
# ============================================================================

echo "=================================================================="
echo "  SOLUTION Q09: KUBE-BENCH — FIX 3 CIS ISSUES"
echo "=================================================================="
echo ""

echo "STEP 0: (Optional) Run kube-bench to see failures"
echo "--------"
echo '$ kube-bench run --targets master 2>/dev/null | grep -A2 "profiling"'
echo "(kube-bench may or may not be installed — in the exam it will be)"
echo ""

fix_profiling() {
  local component=$1
  local manifest="/etc/kubernetes/manifests/${component}.yaml"

  if [ ! -f "$manifest" ]; then
    echo "  ⚠ $manifest not found — skip (not a control-plane node)"
    return
  fi

  # Check if --profiling already exists
  if grep -q "\-\-profiling=false" "$manifest"; then
    echo "  ✅ $component already has --profiling=false"
    return
  fi

  if grep -q "\-\-profiling" "$manifest"; then
    # Replace existing value
    sed -i 's/--profiling=true/--profiling=false/' "$manifest"
    echo "  ✅ $component: changed --profiling=true to --profiling=false"
  else
    # Add the flag after the first '- --' line in the command section
    # Find the line with the component command and add after it
    sed -i '/- kube-/a\    - --profiling=false' "$manifest" 2>/dev/null || \
    sed -i "/--bind-address\|--authorization-mode\|--leader-elect/a\\    - --profiling=false" "$manifest"
    echo "  ✅ $component: added --profiling=false"
  fi
}

echo "STEP 1: Fix kube-apiserver"
echo "--------"
fix_profiling "kube-apiserver"
echo ""

echo "Waiting for kube-apiserver to restart..."
sleep 10
kubectl wait --for=condition=Ready pod -l component=kube-apiserver -n kube-system --timeout=120s 2>/dev/null || true
echo ""

echo "STEP 2: Fix kube-scheduler"
echo "--------"
fix_profiling "kube-scheduler"
echo ""

echo "Waiting for kube-scheduler to restart..."
sleep 5
kubectl wait --for=condition=Ready pod -l component=kube-scheduler -n kube-system --timeout=60s 2>/dev/null || true
echo ""

echo "STEP 3: Fix kube-controller-manager"
echo "--------"
fix_profiling "kube-controller-manager"
echo ""

echo "Waiting for kube-controller-manager to restart..."
sleep 5
kubectl wait --for=condition=Ready pod -l component=kube-controller-manager -n kube-system --timeout=60s 2>/dev/null || true
echo ""

echo "STEP 4: Verify all components are running"
echo "--------"
echo '$ kubectl get pods -n kube-system'
kubectl get pods -n kube-system
echo ""

echo "STEP 5: Verify the fixes"
echo "--------"
for component in kube-apiserver kube-scheduler kube-controller-manager; do
  if [ -f /etc/kubernetes/manifests/${component}.yaml ]; then
    echo "$component:"
    grep "profiling" /etc/kubernetes/manifests/${component}.yaml || echo "  (not found)"
  fi
done
echo ""

echo "=================================================================="
echo "  ✅ SOLUTION COMPLETE"
echo "=================================================================="
echo ""
echo "KEY POINTS:"
echo "  1. Edit static pod manifests in /etc/kubernetes/manifests/"
echo "  2. Add '--profiling=false' to each component's args"
echo "  3. Static pods restart automatically when manifests change"
echo "  4. Wait for each component to restart before editing the next"
echo "  5. Verify with: kubectl get pods -n kube-system"
echo ""
echo "COMMON KUBE-BENCH FIXES:"
echo "  - --profiling=false (apiserver, scheduler, controller-manager)"
echo "  - --audit-log-path, --audit-log-maxage, etc."
echo "  - --encryption-provider-config"
echo "  - File permissions on /etc/kubernetes/manifests/*.yaml"
