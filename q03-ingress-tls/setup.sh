#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q03: Ingress with TLS
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS PRACTICE Q03: INGRESS WITH TLS"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  You have a running web application in the 'web' namespace."
echo "  A TLS secret already exists."
echo ""
echo "TASK:"
echo "  1. Create an Ingress resource named 'web-ingress' in namespace 'web'"
echo "  2. The Ingress must use the existing TLS secret 'web-tls-secret'"
echo "  3. The Ingress must use ingressClassName: nginx"
echo "  4. The Ingress must redirect HTTP requests to HTTPS using the"
echo "     annotation: nginx.ingress.kubernetes.io/ssl-redirect: \"true\""
echo "  5. Route host 'app.example.com' to service 'web-svc' on port 80"
echo ""
echo "REFERENCES (available in exam):"
echo "  - https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/"
echo "  - https://kubernetes.io/docs/concepts/services-networking/ingress/#tls"
echo ""
echo "=================================================================="
echo "  Setting up environment..."
echo "=================================================================="

# Create namespace
kubectl create namespace web --dry-run=client -o yaml | kubectl apply -f -

# Generate self-signed TLS cert
mkdir -p /tmp/cks-q03
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/cks-q03/tls.key \
  -out /tmp/cks-q03/tls.crt \
  -subj "/CN=app.example.com/O=CKS Practice" 2>/dev/null

# Create TLS secret
kubectl create secret tls web-tls-secret \
  --cert=/tmp/cks-q03/tls.crt \
  --key=/tmp/cks-q03/tls.key \
  -n web --dry-run=client -o yaml | kubectl apply -f -

# Create the web application
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
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
  name: web-svc
  namespace: web
spec:
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
EOF

echo ""
echo "✅ Environment ready!"
echo ""
echo "Verify:"
echo "  kubectl get deploy,svc,secret -n web"
echo ""
echo "HINTS:"
echo "  - Use ingressClassName: nginx (NOT the annotation)"
echo "  - TLS secret is 'web-tls-secret' in namespace 'web'"
echo "  - Annotation for SSL redirect: nginx.ingress.kubernetes.io/ssl-redirect"
echo ""
echo "Run 'bash solution.sh' when ready to see the answer."
