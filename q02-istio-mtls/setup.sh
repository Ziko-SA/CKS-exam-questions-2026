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

# Simulate Istio CRDs (for practice without real Istio)
echo ""
echo "NOTE: On KillerCoda, Istio may not be installed. This practice"
echo "focuses on knowing the YAML definitions and kubectl commands."
echo "The CRD files are provided for reference."
echo ""

# Create CRD simulation files
mkdir -p /tmp/cks-q02

cat <<'EOF' > /tmp/cks-q02/peer-authentication-reference.yaml
# Reference: PeerAuthentication for STRICT mTLS
# https://istio.io/latest/docs/tasks/security/authentication/mtls-migration/
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: <NAMESPACE>
spec:
  mtls:
    mode: STRICT
EOF

cat <<'EOF' > /tmp/cks-q02/sidecar-reference.yaml
# Reference: Sidecar injection
# Label the namespace with: istio-injection=enabled
# Then restart deployments to get sidecars injected
EOF

echo "✅ Environment ready!"
echo ""
echo "Reference files at: /tmp/cks-q02/"
echo ""
echo "HINTS:"
echo "  - Namespace label for sidecar injection: istio-injection=enabled"
echo "  - PeerAuthentication CRD for mTLS enforcement"
echo "  - After labeling, restart the deployment to inject sidecars"
echo ""
echo "Run 'bash solution.sh' when ready to see the answer."
