#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q14: Kube-apiserver Anonymous Auth
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS PRACTICE Q14: KUBE-APISERVER — ANONYMOUS AUTH"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  The kube-apiserver currently allows anonymous authentication."
echo "  Additionally, there's a ClusterRoleBinding 'system:anonymous'"
echo "  that grants permissions to anonymous users."
echo ""
echo "TASK:"
echo "  1. Edit the kube-apiserver to set --anonymous-auth=false"
echo "     File: /etc/kubernetes/manifests/kube-apiserver.yaml"
echo ""
echo "  2. Delete the ClusterRoleBinding named 'system:anonymous'"
echo ""
echo "  3. Verify the apiserver restarts successfully"
echo ""
echo "IMPORTANT:"
echo "  - Be careful editing apiserver manifests"
echo "  - Wait for the apiserver to restart"
echo ""
echo "=================================================================="
echo "  Setting up environment..."
echo "=================================================================="

# Create the insecure ClusterRoleBinding
cat <<'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:anonymous
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: system:anonymous
EOF

echo ""
echo "✅ Environment ready!"
echo ""
echo "Verify current state:"
echo '  kubectl get clusterrolebinding system:anonymous'
kubectl get clusterrolebinding system:anonymous 2>/dev/null || true
echo ""

APISERVER="/etc/kubernetes/manifests/kube-apiserver.yaml"
if [ -f "$APISERVER" ]; then
  echo "  Current anonymous-auth setting:"
  grep "anonymous-auth" "$APISERVER" || echo "  --anonymous-auth not explicitly set (defaults to true)"
fi

echo ""
echo "HINTS:"
echo "  - Edit the apiserver manifest to add/change --anonymous-auth=false"
echo "  - kubectl delete clusterrolebinding system:anonymous"
echo ""
echo "Run 'bash solution.sh' when ready to see the answer."
