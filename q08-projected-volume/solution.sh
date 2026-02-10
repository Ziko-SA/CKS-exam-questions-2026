#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q08 SOLUTION: Projected Volume & ServiceAccount
# ============================================================================

echo "=================================================================="
echo "  SOLUTION Q08: PROJECTED VOLUME & SERVICEACCOUNT"
echo "=================================================================="
echo ""

echo "STEP 1: Disable automount on ServiceAccount"
echo "--------"
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: tokens
automountServiceAccountToken: false
EOF
echo ""
echo "Verify SA:"
kubectl get sa app-sa -n tokens -o yaml | grep -A1 automount
echo ""

echo "STEP 2: Update deployment with projected volume"
echo "--------"

cat <<'EOF' > /root/token-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: token-app
  namespace: tokens
spec:
  replicas: 1
  selector:
    matchLabels:
      app: token-app
  template:
    metadata:
      labels:
        app: token-app
    spec:
      serviceAccountName: app-sa
      automountServiceAccountToken: false
      containers:
      - name: app
        image: busybox:1.36
        command: ["sh", "-c", "sleep 3600"]
        volumeMounts:
        - name: sa-token
          mountPath: /var/run/secrets/kubernetes.io/serviceaccount
          readOnly: true
      volumes:
      - name: sa-token
        projected:
          sources:
          - serviceAccountToken:
              path: token
              expirationSeconds: 3600
EOF

echo "Updated deployment YAML:"
cat /root/token-deploy.yaml
echo ""

echo '$ kubectl apply -f /root/token-deploy.yaml'
kubectl apply -f /root/token-deploy.yaml
echo ""

echo "STEP 3: Verify the projected volume is mounted"
echo "--------"
sleep 8
POD=$(kubectl get pod -n tokens -l app=token-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD" ]; then
  echo '$ kubectl exec '$POD' -n tokens -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/'
  kubectl exec $POD -n tokens -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/ 2>/dev/null || echo "(waiting for new pod...)"
fi
echo ""

echo "=================================================================="
echo "  ✅ SOLUTION COMPLETE"
echo "=================================================================="
echo ""
echo "KEY POINTS:"
echo "  1. Disable auto-mount on BOTH the SA AND the pod spec"
echo "  2. Projected volume with serviceAccountToken source:"
echo "       volumes:"
echo "       - name: sa-token"
echo "         projected:"
echo "           sources:"
echo "           - serviceAccountToken:"
echo "               path: token"
echo "               expirationSeconds: 3600"
echo "  3. Mount at /var/run/secrets/kubernetes.io/serviceaccount"
echo "  4. The 'path: token' means the file will be at .../serviceaccount/token"
echo "  5. expirationSeconds limits the token lifetime (bound token)"
echo ""
echo "WHY:"
echo "  - Auto-mounted tokens are long-lived and stored as secrets"
echo "  - Projected tokens are short-lived (bound) and more secure"
echo "  - This is a CIS benchmark recommendation for K8s security"
