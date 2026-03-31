#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q07: Secret TLS
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS PRACTICE Q07: SECRET TLS"
echo "=================================================================="
echo ""
echo "     using the provided cert and key files"
echo "  2. Edit the deployment at /root/secure-deploy.yaml to mount"
echo "     the TLS secret as a volume at /etc/tls"
echo "  3. Apply the deployment"
echo ""
echo "=================================================================="
echo "  Setting up environment..."
echo "=================================================================="

kubectl create namespace secure --dry-run=client -o yaml | kubectl apply -f -

# Generate cert and key files
mkdir -p /root/certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /root/certs/tls.key \
  -out /root/certs/tls.crt \
  -subj "/CN=secure-app.example.com/O=CKS Practice" 2>/dev/null

# Create deployment WITHOUT tls volume (student must add it)
cat <<'EOF' > /root/secure-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: secure
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 443
EOF

echo ""
echo "✅ Environment ready!"
echo ""
echo "Files:"
echo "  /root/certs/tls.crt — TLS certificate"
echo "  /root/certs/tls.key — TLS private key"
echo "  /root/secure-deploy.yaml — Deployment to modify"
echo ""
echo "HINTS:"
echo "  - kubectl create secret tls <name> --cert=<cert> --key=<key> -n <ns>"
echo "  - Add volumes and volumeMounts to the deployment"
echo "  - Mount path: /etc/tls"
echo ""
echo "Run 'bash verify.sh' after solving to check your answer."
