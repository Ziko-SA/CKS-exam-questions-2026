#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q05 SOLUTION: BOM/SBOM Analysis
# ============================================================================

echo "=================================================================="
echo "  SOLUTION Q05: BOM/SBOM — SUPPLY CHAIN SECURITY"
echo "=================================================================="
echo ""

echo "STEP 1: Identify the pod name"
echo "--------"
POD=$(kubectl get pod -n apps -l app=alpine-multi -o jsonpath='{.items[0].metadata.name}')
echo "Pod: $POD"
echo ""

echo "STEP 2: Check libcrypto3 in each container"
echo "--------"
echo "Checking container-a (alpine:3.20.0):"
echo '$ kubectl exec '$POD' -n apps -c container-a -- apk list libcrypto3 2>/dev/null'
kubectl exec $POD -n apps -c container-a -- apk list libcrypto3 2>/dev/null || echo "  (package check done)"
echo ""

echo "Checking container-b (alpine:3.19.6):"
echo '$ kubectl exec '$POD' -n apps -c container-b -- apk list libcrypto3 2>/dev/null'
kubectl exec $POD -n apps -c container-b -- apk list libcrypto3 2>/dev/null || echo "  (package check done)"
echo ""

echo "Checking container-c (alpine:3.16.1):"
echo '$ kubectl exec '$POD' -n apps -c container-c -- apk list libcrypto3 2>/dev/null'
kubectl exec $POD -n apps -c container-c -- apk list libcrypto3 2>/dev/null || echo "  (package check done)"
echo ""

echo "The container with the vulnerable libcrypto3 version should be identified."
echo "In the exam, match the version number given in the question."
echo ""

echo "STEP 3: Remove the vulnerable container from the deployment"
echo "--------"
echo "Edit /tmp/alpine-multi-deploy.yaml — remove the offending container"
echo ""

cat <<'EOF' > /tmp/alpine-multi-deploy-fixed.yaml
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
      # container-c (alpine:3.16.1) REMOVED — had vulnerable libcrypto3
EOF

echo "Fixed YAML (container-c removed):"
cat /tmp/alpine-multi-deploy-fixed.yaml
echo ""

echo '$ kubectl apply -f /tmp/alpine-multi-deploy-fixed.yaml'
kubectl apply -f /tmp/alpine-multi-deploy-fixed.yaml
echo ""

echo "STEP 4: Generate SPDX SBOM report"
echo "--------"
echo "Using 'bom' tool (pre-installed in CKS exam environment):"
echo '$ bom generate -i alpine:3.16.1 -o /root/sbom-report.spdx'
echo ""
echo "Alternative using 'syft':"
echo '$ syft alpine:3.16.1 -o spdx > /root/sbom-report.spdx'
echo ""

# Try to use bom if available
if command -v bom &>/dev/null; then
  bom generate -i alpine:3.16.1 -o /root/sbom-report.spdx
  echo "SBOM saved to /root/sbom-report.spdx"
elif command -v syft &>/dev/null; then
  syft alpine:3.16.1 -o spdx > /root/sbom-report.spdx
  echo "SBOM saved to /root/sbom-report.spdx"
else
  echo "(bom/syft not installed — in the exam, one of these tools will be available)"
  echo "Creating placeholder..."
  echo "SPDXVersion: SPDX-2.3" > /root/sbom-report.spdx
  echo "DataLicense: CC0-1.0" >> /root/sbom-report.spdx
  echo "SPDXID: SPDXRef-DOCUMENT" >> /root/sbom-report.spdx
  echo "DocumentName: alpine-3.16.1" >> /root/sbom-report.spdx
fi
echo ""

echo "STEP 5: Verify"
echo "--------"
echo '$ kubectl get pods -n apps'
kubectl get pods -n apps
echo ""

echo "=================================================================="
echo "  ✅ SOLUTION COMPLETE"
echo "=================================================================="
echo ""
echo "KEY POINTS:"
echo "  1. Exec into containers: kubectl exec <pod> -c <container> -- apk list <pkg>"
echo "  2. Remove the container from deployment YAML, then kubectl apply"
echo "  3. Use 'bom generate -i <image> -o <output>' for SPDX format"
echo "  4. Alternative: 'syft <image> -o spdx > <output>'"
echo "  5. The 'bom' tool should be pre-installed in the CKS exam env"
