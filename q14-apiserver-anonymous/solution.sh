#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q14 SOLUTION: Kube-apiserver Anonymous Auth
# ============================================================================

echo "=================================================================="
echo "  SOLUTION Q14: KUBE-APISERVER — ANONYMOUS AUTH"
echo "=================================================================="
echo ""

echo "STEP 1: Delete the ClusterRoleBinding system:anonymous"
echo "--------"
echo '$ kubectl delete clusterrolebinding system:anonymous'
kubectl delete clusterrolebinding system:anonymous 2>/dev/null || echo "(already deleted or doesn't exist)"
echo ""

echo "STEP 2: Disable anonymous auth in kube-apiserver"
echo "--------"

APISERVER="/etc/kubernetes/manifests/kube-apiserver.yaml"

if [ -f "$APISERVER" ]; then
  if grep -q "\-\-anonymous-auth=true" "$APISERVER"; then
    sed -i 's/--anonymous-auth=true/--anonymous-auth=false/' "$APISERVER"
    echo "✅ Changed --anonymous-auth=true to --anonymous-auth=false"
  elif grep -q "\-\-anonymous-auth" "$APISERVER"; then
    echo "anonymous-auth already configured:"
    grep "anonymous-auth" "$APISERVER"
  else
    # Add the flag
    sed -i '/- --tls-private-key-file/a\    - --anonymous-auth=false' "$APISERVER"
    echo "✅ Added --anonymous-auth=false to kube-apiserver"
  fi

  echo ""
  echo "Verify the flag:"
  grep "anonymous-auth" "$APISERVER"
  echo ""

  echo "Waiting for kube-apiserver to restart..."
  sleep 15
  kubectl wait --for=condition=Ready pod -l component=kube-apiserver -n kube-system --timeout=120s 2>/dev/null || echo "(waiting for restart...)"
else
  echo "⚠ kube-apiserver manifest not found"
  echo ""
  echo "Manual step: Edit /etc/kubernetes/manifests/kube-apiserver.yaml"
  echo "Add or change: --anonymous-auth=false"
fi
echo ""

echo "STEP 3: Verify"
echo "--------"
echo '$ kubectl get clusterrolebinding system:anonymous 2>&1'
kubectl get clusterrolebinding system:anonymous 2>&1 || true
echo ""
echo '$ kubectl get pods -n kube-system | grep apiserver'
kubectl get pods -n kube-system 2>/dev/null | grep apiserver || true
echo ""

echo "Test anonymous access (should be denied):"
echo '$ curl -sk https://localhost:6443/api/v1/namespaces'
echo "(Should return 401 Unauthorized)"
echo ""

echo "=================================================================="
echo "  ✅ SOLUTION COMPLETE"
echo "=================================================================="
echo ""
echo "KEY POINTS:"
echo "  1. Set --anonymous-auth=false in kube-apiserver manifest"
echo "  2. Delete ClusterRoleBinding: kubectl delete clusterrolebinding system:anonymous"
echo "  3. anonymous-auth=false means ALL requests must be authenticated"
echo "  4. The ClusterRoleBinding was giving cluster-admin to anonymous users!"
echo "  5. Wait for apiserver to restart after manifest change"
echo ""
echo "⚠ WARNING in real clusters:"
echo "  Some health checks may need anonymous access (liveness probes)."
echo "  In the CKS exam, follow the question instructions exactly."
