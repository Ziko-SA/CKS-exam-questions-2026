#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q03 SOLUTION: Ingress with TLS
# ============================================================================

echo "=================================================================="
echo "  SOLUTION Q03: INGRESS WITH TLS"
echo "=================================================================="
echo ""

echo "STEP 1: Create the Ingress resource with TLS and SSL redirect"
echo "--------"

cat <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: web
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - app.example.com
    secretName: web-tls-secret
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-svc
            port:
              number: 80
EOF

cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: web
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - app.example.com
    secretName: web-tls-secret
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-svc
            port:
              number: 80
EOF

echo ""
echo "STEP 2: Verify the Ingress"
echo "--------"
echo '$ kubectl get ingress -n web'
kubectl get ingress -n web
echo ""
echo '$ kubectl describe ingress web-ingress -n web'
kubectl describe ingress web-ingress -n web
echo ""

echo "=================================================================="
echo "  ✅ SOLUTION COMPLETE"
echo "=================================================================="
echo ""
echo "KEY POINTS:"
echo "  1. Use ingressClassName: nginx (not the old annotation)"
echo "  2. TLS section references the existing secret name"
echo "  3. Annotation nginx.ingress.kubernetes.io/ssl-redirect: 'true'"
echo "     forces HTTP → HTTPS redirect"
echo "  4. Host in tls[].hosts must match rules[].host"
echo "  5. pathType: Prefix with path: / covers all paths"
