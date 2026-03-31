#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q02: Istio mTLS & Sidecar Injection
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS PRACTICE Q02: ISTIO — mTLS & SIDECAR INJECTION"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  Istio is installed on the cluster. You need to enforce mutual TLS"
echo "  (mTLS) and enable sidecar injection for a specific namespace."
echo ""
echo "TASK:"
echo "  1. Enable Istio sidecar injection for the namespace 'webapp'"
echo "  2. Apply a PeerAuthentication policy to enforce STRICT mTLS"
echo "     for the namespace 'webapp'"
echo "  3. Restart the existing deployment 'web-frontend' so it gets"
echo "     the sidecar injected"
echo ""
echo "REFERENCES (available in exam):"
echo "  - https://istio.io/latest/docs/tasks/security/authentication/mtls-migration/"
echo "  - https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/"
echo ""
echo "=================================================================="
echo "  Setting up environment..."
echo "=================================================================="

# Create namespace
kubectl create namespace webapp --dry-run=client -o yaml | kubectl apply -f -

# Create the deployment
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-frontend
  namespace: webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-frontend
  template:
    metadata:
      labels:
        app: web-frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-frontend
  namespace: webapp
spec:
  selector:
    app: web-frontend
  ports:
  - port: 80
    targetPort: 80
EOF

# Verify Istio is installed (install-prereqs.sh handles this)
echo ""
if command -v istioctl &>/dev/null; then
  echo "✅ Istio is installed: $(istioctl version --remote=false 2>/dev/null)"
  # Verify Istio is running in the cluster
  if kubectl get ns istio-system &>/dev/null; then
    echo "✅ Istio control plane is running"
    kubectl get pods -n istio-system --no-headers 2>/dev/null | head -5
  else
    echo "⚠️  Istio namespace not found — running 'istioctl install --set profile=demo -y'"
    istioctl install --set profile=demo -y 2>/dev/null
  fi
else
  echo "⚠️  Istio is NOT installed."
  echo "   Run 'bash install-prereqs.sh' from the project root first."
  echo "   Without Istio, you can still practice the YAML/commands"
  echo "   but sidecar injection won't actually work."
fi

# Wait for deployment to be ready
echo ""
echo "Waiting for deployment..."
kubectl wait --for=condition=available deployment/web-frontend -n webapp --timeout=60s 2>/dev/null || true

echo ""
echo "✅ Environment ready!"
echo ""
echo "HINTS:"
echo "  - Namespace label for sidecar injection: istio-injection=enabled"
echo "  - PeerAuthentication CRD for mTLS enforcement"
echo "  - After labeling, restart the deployment to inject sidecars"
echo ""
echo "Run 'bash verify.sh' after solving to check your answer."
