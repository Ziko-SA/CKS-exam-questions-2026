#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q13 SOLUTION: PSS Fix Deployment
# ============================================================================

echo "=================================================================="
echo "  SOLUTION Q13: POD SECURITY STANDARDS — FIX DEPLOYMENT"
echo "=================================================================="
echo ""

echo "STEP 1: Diagnose — Check ReplicaSet events"
echo "--------"
echo '$ kubectl get rs -n restricted'
kubectl get rs -n restricted 2>/dev/null || true
echo ""
echo '$ kubectl describe rs -n restricted | grep -A5 "Warning"'
kubectl describe rs -n restricted 2>/dev/null | grep -A5 "Warning" || true
echo ""
echo "The events will show PSS violations like:"
echo "  - privileged: true is not allowed"
echo "  - runAsUser: 0 is not allowed"
echo "  - allowPrivilegeEscalation: true is not allowed"
echo "  - capabilities must be dropped (ALL) and only NET_BIND_SERVICE allowed"
echo ""

echo "STEP 2: Fix the deployment YAML"
echo "--------"
echo "Changes needed for 'restricted' PSS profile:"
echo "  - Remove privileged: true"
echo "  - Set runAsNonRoot: true"
echo "  - Remove runAsUser: 0"
echo "  - Set allowPrivilegeEscalation: false"
echo "  - Drop ALL capabilities"
echo "  - Set seccompProfile type: RuntimeDefault"
echo ""

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
      securityContext:
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: web
        image: nginx:1.25
        ports:
        - containerPort: 8080
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsUser: 1000
          capabilities:
            drop:
            - ALL
EOF

echo "Fixed deployment YAML:"
cat /root/pss-deploy.yaml
echo ""

echo "STEP 3: Apply the fixed deployment"
echo "--------"
echo '$ kubectl apply -f /root/pss-deploy.yaml'
kubectl apply -f /root/pss-deploy.yaml
echo ""

echo "STEP 4: Verify pods are running"
echo "--------"
sleep 8
echo '$ kubectl get deploy,rs,pods -n restricted'
kubectl get deploy,rs,pods -n restricted
echo ""

echo "=================================================================="
echo "  ✅ SOLUTION COMPLETE"
echo "=================================================================="
echo ""
echo "KEY POINTS for PSS 'restricted' profile:"
echo "  1. No privileged containers"
echo "  2. No privilege escalation (allowPrivilegeEscalation: false)"
echo "  3. Must run as non-root (runAsNonRoot: true)"
echo "  4. Must drop ALL capabilities"
echo "  5. Must have seccompProfile: RuntimeDefault or Localhost"
echo "  6. Must NOT use hostNetwork, hostPID, hostIPC"
echo "  7. Must NOT use hostPath volumes"
echo ""
echo "DEBUGGING TIP:"
echo "  When pods don't start, check ReplicaSet events:"
echo "  kubectl describe rs <rs-name> -n <ns> | grep -A10 Events"
echo "  This shows the PSS admission error messages"
