#!/bin/bash

# ============================================================================
# CKS EXAM REAL QUESTION — Q08: ServiceAccount Token Projection
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS REAL Q08: SERVICEACCOUNT TOKEN PROJECTION"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  A ServiceAccount 'app-sa' and a deployment exist in namespace 'tokens'."
echo "  The ServiceAccount currently auto-mounts its token."
echo ""
echo "TASK:"
echo "  - Edit the ServiceAccount 'app-sa' to disable automountServiceAccountToken."
echo "  - Edit the deployment 'token-app' to use a projected volume to mount the ServiceAccount token at /var/run/secrets/kubernetes.io/serviceaccount/token with an expirationSeconds of 3600."
echo "  - Apply both changes."
echo ""
echo "=================================================================="
echo "  Setting up environment..."
echo "=================================================================="

kubectl create namespace tokens --dry-run=client -o yaml | kubectl apply -f -

# Create ServiceAccount (with auto-mount enabled)
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: tokens
automountServiceAccountToken: true
EOF

# Create deployment using the SA
cat <<'EOF' > /root/token-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: token-app
  namespace: tokens
spec:
  replicas: 1
  selector:
    matchLabels:
      app: token-app
  template:
    metadata:
      labels:
        app: token-app
    spec:
      serviceAccountName: app-sa
      containers:
      - name: app
        image: busybox:1.36
        command: ["sh", "-c", "sleep 3600"]
EOF

kubectl apply -f /root/token-deploy.yaml

echo ""
echo "✅ Environment ready!"
echo ""
echo "Files:"
echo "  ServiceAccount: app-sa (namespace: tokens)"
echo "  Deployment file: /root/token-deploy.yaml"
echo ""
echo "HINTS:"
echo "  - Disable auto-mount on SA: automountServiceAccountToken: false"
echo "  - Use projected volume with serviceAccountToken source"
echo "  - expirationSeconds: 3600"
echo "  - Mount path: /var/run/secrets/kubernetes.io/serviceaccount/token"
echo ""
echo "Run 'bash solution.sh' when ready to see the answer."
