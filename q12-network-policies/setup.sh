#!/bin/bash

# ============================================================================
# CKS EXAM REAL QUESTION — Q12: Network Policies
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS REAL Q12: NETWORK POLICIES"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  Applications are running in namespaces 'frontend', 'backend', and 'database'."
echo "  Network access is currently unrestricted."
echo ""
echo "TASK:"
echo "  - Create a NetworkPolicy in namespace 'backend' to deny all ingress traffic by default."
echo "  - Create a second NetworkPolicy in namespace 'backend' to allow ingress to pods labeled 'app=api-server' only from pods labeled 'app=web' in namespace 'frontend' on port 8080/TCP."
echo "  - Use standard Kubernetes NetworkPolicy (apiVersion: networking.k8s.io/v1), not CiliumNetworkPolicy."
echo ""
echo "=================================================================="
echo "  Setting up environment..."
echo "=================================================================="

# Create namespaces with labels
kubectl create namespace frontend --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace backend --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace database --dry-run=client -o yaml | kubectl apply -f -

# Label namespaces
kubectl label namespace frontend purpose=frontend --overwrite
kubectl label namespace backend purpose=backend --overwrite

# Deploy applications
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-server
  template:
    metadata:
      labels:
        app: api-server
    spec:
      containers:
      - name: api
        image: hashicorp/http-echo:0.2.3
        args: ["-listen=:8080", "-text=api-server-response"]
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: api-server
  namespace: backend
spec:
  selector:
    app: api-server
  ports:
  - port: 8080
    targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: malicious-app
  namespace: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: malicious
  template:
    metadata:
      labels:
        app: malicious
    spec:
      containers:
      - name: hacker
        image: busybox:1.36
        command: ["sh", "-c", "sleep 3600"]
EOF

echo ""
echo "Waiting for deployments..."
kubectl wait --for=condition=available deployment/web -n frontend --timeout=60s 2>/dev/null || true
kubectl wait --for=condition=available deployment/api-server -n backend --timeout=60s 2>/dev/null || true

echo ""
echo "✅ Environment ready!"
echo ""
echo "Verify deployments:"
kubectl get pods -n frontend
kubectl get pods -n backend
echo ""

# Test pre-solution connectivity (everything should work before policies)
echo "Pre-solution connectivity (no policies yet — everything is open):"
WEB_POD=$(kubectl get pods -n frontend -l app=web -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
API_SVC=$(kubectl get svc api-server -n backend -o jsonpath="{.spec.clusterIP}" 2>/dev/null)
if [ -n "$WEB_POD" ] && [ -n "$API_SVC" ]; then
  kubectl exec "$WEB_POD" -n frontend -- wget -qO- --timeout=3 "http://${API_SVC}:8080" 2>/dev/null \
    && echo "  ✅ frontend/web → backend/api-server:8080 = OPEN (expected)" \
    || echo "  ⚠️  frontend/web → backend/api-server:8080 = BLOCKED (unexpected)"
fi

echo ""
echo "HINTS:"
echo "  - Policy 1: Default deny uses an empty podSelector and ingress: []"
echo "  - Policy 2: Use namespaceSelector + podSelector in ingress.from"
echo "  - Namespaces are already labeled: purpose=frontend, purpose=backend"
echo ""
echo "Run 'bash verify.sh' after solving to check your answer."
