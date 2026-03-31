#!/bin/bash

# ============================================================================
# CKS EXAM REAL QUESTION — Q13: Pod Security Standards (PSS) Remediation
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS REAL Q13: POD SECURITY STANDARDS (PSS) REMEDIATION"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  The namespace 'restricted' has Pod Security Standards (PSS) enforcement enabled at the 'restricted' level."
echo "  A deployment in this namespace is failing to start due to PSS violations."
echo ""
echo "TASK:"
echo "  - Identify the PSS violations preventing pod startup."
echo "  - Edit the deployment YAML at /root/pss-deploy.yaml to comply with the 'restricted' PSS profile."
echo "  - Apply the fixed deployment and verify pods are running."
echo ""
echo "=================================================================="
echo "  Setting up environment..."
echo "=================================================================="

# Create namespace with PSS enforcement
kubectl create namespace restricted --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace restricted \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=latest \
  pod-security.kubernetes.io/warn=restricted \
  pod-security.kubernetes.io/warn-version=latest \
  --overwrite

# Create a deployment that violates PSS restricted profile
cat <<'EOF' > /root/pss-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-web
  namespace: restricted
spec:
  replicas: 2
  selector:
    matchLabels:
      app: secure-web
  template:
    metadata:
      labels:
        app: secure-web
    spec:
      containers:
      - name: web
        image: nginx:1.25
        ports:
        - containerPort: 80
        securityContext:
          privileged: true
          runAsUser: 0
          allowPrivilegeEscalation: true
          capabilities:
            add:
            - NET_ADMIN
            - SYS_ADMIN
EOF

echo ""
echo "Applying the broken deployment..."
kubectl apply -f /root/pss-deploy.yaml 2>&1 || true
echo ""

sleep 3

echo "✅ Environment ready!"
echo ""
echo "Check the issue:"
echo "  kubectl get deploy,rs,pods -n restricted"
echo "  kubectl describe rs -n restricted"
echo ""
echo "The deployment is created but pods won't start due to PSS violations."
echo "Fix /root/pss-deploy.yaml and re-apply."
echo ""
echo "Run 'bash verify.sh' after solving to check your answer."
