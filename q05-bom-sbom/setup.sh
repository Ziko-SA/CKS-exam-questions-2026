#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q05: BOM/SBOM Analysis
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS PRACTICE Q05: BOM/SBOM — SUPPLY CHAIN SECURITY"
echo "=================================================================="
echo ""
echo "  2. Edit the deployment YAML to REMOVE the container that has"
echo "     the vulnerable libcrypto3 version, then redeploy."
echo "  3. Generate an SPDX SBOM report for the image alpine:3.16.1"
echo "     and save it to /root/sbom-report.spdx"
echo ""
echo "=================================================================="
echo "  Setting up environment..."
echo "=================================================================="

kubectl create namespace apps --dry-run=client -o yaml | kubectl apply -f -

cat <<'EOF' > /tmp/alpine-multi-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: alpine-multi
  namespace: apps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: alpine-multi
  template:
    metadata:
      labels:
        app: alpine-multi
    spec:
      containers:
      - name: container-a
        image: alpine:3.20.0
        command: ["sh", "-c", "sleep 3600"]
      - name: container-b
        image: alpine:3.19.6
        command: ["sh", "-c", "sleep 3600"]
      - name: container-c
        image: alpine:3.16.1
        command: ["sh", "-c", "sleep 3600"]
EOF

kubectl apply -f /tmp/alpine-multi-deploy.yaml

echo ""
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=available deployment/alpine-multi -n apps --timeout=120s 2>/dev/null || true
echo ""

# Check if syft is installed for SBOM generation
if command -v syft &>/dev/null; then
  echo "✅ syft is installed for SBOM generation"
else
  echo "⚠️  syft not installed. Installing..."
  curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin 2>/dev/null \
    && echo "✅ syft installed" \
    || echo "⚠️  syft install failed — run 'bash install-prereqs.sh' from project root"
fi

echo ""
echo "✅ Environment ready!"
echo ""
echo "Deployment file: /tmp/alpine-multi-deploy.yaml"
echo ""
echo "HINTS:"
echo "  - To check package versions: kubectl exec <pod> -n apps -c <container> -- apk list libcrypto3"
echo "  - To generate SBOM: syft <image> -o spdx > /root/sbom-report.spdx"
echo "  - Save SPDX output to /root/sbom-report.spdx"
echo ""
echo "Run 'bash verify.sh' after solving to check your answer."
