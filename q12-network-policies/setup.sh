#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q12: Network Policies
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS PRACTICE Q12: NETWORK POLICIES"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  There are several applications running in namespaces 'frontend',"
echo "  'backend', and 'database'. You need to restrict network traffic."
echo ""
echo "TASK:"
echo "  Create 2 NetworkPolicy resources (standard Kubernetes, NOT"
echo "  CiliumNetworkPolicy):"
echo ""
echo "  Policy 1 — 'deny-all-backend' in namespace 'backend':"
echo "    - Default deny ALL ingress traffic to all pods in namespace 'backend'"
echo ""
echo "  Policy 2 — 'allow-backend-from-frontend' in namespace 'backend':"
echo "    - Allow ingress traffic to pods labeled 'app=api-server'"
echo "      ONLY from pods labeled 'app=web' in namespace 'frontend'"
echo "    - Allow only port 8080/TCP"
echo ""
echo "IMPORTANT:"
echo "  - Use standard Kubernetes NetworkPolicy (apiVersion: networking.k8s.io/v1)"
echo "  - Do NOT use CiliumNetworkPolicy"
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
        image: nginx:1.25
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
echo "✅ Environment ready!"
echo ""
echo "Verify deployments:"
kubectl get pods -n frontend
kubectl get pods -n backend
echo ""
echo "HINTS:"
echo "  - Policy 1: Default deny uses an empty podSelector and ingress: []"
echo "  - Policy 2: Use namespaceSelector + podSelector in ingress.from"
echo "  - Use kubectl label ns to add labels for namespace selection"
echo ""
echo "Run 'bash solution.sh' when ready to see the answer."
