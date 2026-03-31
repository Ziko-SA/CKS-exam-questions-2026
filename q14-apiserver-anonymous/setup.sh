#!/bin/bash

# ============================================================================
# CKS EXAM REAL QUESTION — Q14: Kube-apiserver Anonymous Authentication
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS REAL Q14: KUBE-APISERVER ANONYMOUS AUTHENTICATION"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  The kube-apiserver is currently configured to allow anonymous authentication."
echo "  There is also a ClusterRoleBinding named 'system:anonymous' granting permissions to anonymous users."
echo ""
echo "TASK:"
echo "  - Edit the kube-apiserver manifest to set --anonymous-auth=false."
echo "  - Delete the ClusterRoleBinding named 'system:anonymous'."
echo "  - Verify the apiserver restarts successfully."
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
echo "Run 'bash verify.sh' after solving to check your answer."
