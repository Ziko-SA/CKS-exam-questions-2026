#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q02 SOLUTION: Istio mTLS & Sidecar Injection
# ============================================================================

echo "=================================================================="
echo "  SOLUTION Q02: ISTIO — mTLS & SIDECAR INJECTION"
echo "=================================================================="
echo ""

echo "STEP 1: Label the namespace for automatic sidecar injection"
echo "--------"
echo '$ kubectl label namespace webapp istio-injection=enabled'
kubectl label namespace webapp istio-injection=enabled --overwrite
echo ""

echo "STEP 2: Apply PeerAuthentication for STRICT mTLS"
echo "--------"
cat <<'EOF'
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: webapp
spec:
  mtls:
    mode: STRICT
EOF

cat <<'EOF' > /tmp/cks-q02/peer-authentication.yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: webapp
spec:
  mtls:
    mode: STRICT
EOF

echo ""
echo "$ kubectl apply -f /tmp/cks-q02/peer-authentication.yaml"
# In a real Istio environment, uncomment:
# kubectl apply -f /tmp/cks-q02/peer-authentication.yaml
echo "(Skipped — Istio CRDs not installed in this environment)"
echo ""

echo "STEP 3: Restart the deployment to inject sidecar"
echo "--------"
echo '$ kubectl rollout restart deployment web-frontend -n webapp'
kubectl rollout restart deployment web-frontend -n webapp
echo ""

echo "STEP 4: Verify the label and deployment"
echo "--------"
echo '$ kubectl get ns webapp --show-labels'
kubectl get ns webapp --show-labels
echo ""
echo '$ kubectl get pods -n webapp'
kubectl get pods -n webapp
echo ""

echo "=================================================================="
echo "  ✅ SOLUTION COMPLETE"
echo "=================================================================="
echo ""
echo "KEY POINTS:"
echo "  1. Label namespace: kubectl label namespace <ns> istio-injection=enabled"
echo "  2. Create PeerAuthentication with mode: STRICT for the namespace"
echo "  3. Restart deployment: kubectl rollout restart deployment <name> -n <ns>"
echo "  4. Verify pods have 2/2 containers (app + istio-proxy sidecar)"
echo "  5. Reference: istio.io docs for PeerAuthentication and sidecar injection"
