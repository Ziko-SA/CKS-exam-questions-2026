#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q12 SOLUTION: Network Policies
# ============================================================================

echo "=================================================================="
echo "  SOLUTION Q12: NETWORK POLICIES"
echo "=================================================================="
echo ""

echo "STEP 1: Create Policy 1 — Default deny all ingress in 'backend'"
echo "--------"

cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-backend
  namespace: backend
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF

echo ""
echo "Policy 1 YAML:"
cat <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-backend
  namespace: backend
spec:
  podSelector: {}        # Applies to ALL pods in the namespace
  policyTypes:
  - Ingress              # No ingress rules = deny all ingress
EOF
echo ""

echo "STEP 2: Create Policy 2 — Allow backend from frontend only"
echo "--------"

cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-from-frontend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: api-server
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          purpose: frontend
      podSelector:
        matchLabels:
          app: web
    ports:
    - protocol: TCP
      port: 8080
EOF

echo ""
echo "Policy 2 YAML:"
cat <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-from-frontend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: api-server         # Target: pods with app=api-server
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:       # From namespace labeled purpose=frontend
        matchLabels:
          purpose: frontend
      podSelector:             # AND pods labeled app=web
        matchLabels:
          app: web
    ports:
    - protocol: TCP
      port: 8080               # Only port 8080
EOF
echo ""

echo "STEP 3: Verify the policies"
echo "--------"
echo '$ kubectl get networkpolicy -n backend'
kubectl get networkpolicy -n backend
echo ""
echo '$ kubectl describe networkpolicy -n backend'
kubectl describe networkpolicy -n backend
echo ""

echo "STEP 4: Test connectivity (optional)"
echo "--------"
echo "From frontend (should work):"
echo '$ kubectl exec -n frontend <web-pod> -- curl -s --max-time 3 api-server.backend:8080'
echo ""
echo "From malicious pod in backend (should be blocked):"
echo '$ kubectl exec -n backend <malicious-pod> -- wget -qO- --timeout=3 api-server.backend:8080'
echo ""

echo "=================================================================="
echo "  ✅ SOLUTION COMPLETE"
echo "=================================================================="
echo ""
echo "KEY POINTS:"
echo "  1. Default deny: podSelector: {} with policyTypes: [Ingress] and NO ingress rules"
echo "  2. Allow specific traffic: use from[] with namespaceSelector AND podSelector"
echo "  3. ⚠ IMPORTANT: namespaceSelector + podSelector under the SAME '-' means AND"
echo "     Two separate '-' entries means OR"
echo "  4. Always label namespaces for namespaceSelector to work"
echo "  5. Standard NetworkPolicy, NOT CiliumNetworkPolicy"
echo ""
echo "COMMON MISTAKE:"
echo "  - from:"
echo "    - namespaceSelector: ...   # ← This is OR"
echo "    - podSelector: ...         # ← (two separate list items)"
echo ""
echo "  vs"
echo ""
echo "  - from:"
echo "    - namespaceSelector: ...   # ← This is AND"
echo "      podSelector: ...         # ← (same list item)"
