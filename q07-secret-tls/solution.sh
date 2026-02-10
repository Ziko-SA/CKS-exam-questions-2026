#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q07 SOLUTION: Secret TLS
# ============================================================================

echo "=================================================================="
echo "  SOLUTION Q07: SECRET TLS"
echo "=================================================================="
echo ""

echo "STEP 1: Create TLS secret from cert and key files"
echo "--------"
echo '$ kubectl create secret tls app-tls --cert=/root/certs/tls.crt --key=/root/certs/tls.key -n secure'
kubectl create secret tls app-tls \
  --cert=/root/certs/tls.crt \
  --key=/root/certs/tls.key \
  -n secure --dry-run=client -o yaml | kubectl apply -f -
echo ""

echo "STEP 2: Verify the secret"
echo "--------"
kubectl get secret app-tls -n secure
echo ""

echo "STEP 3: Update the deployment to mount the TLS secret"
echo "--------"

cat <<'EOF' > /root/secure-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: secure
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 443
        volumeMounts:
        - name: tls-certs
          mountPath: /etc/tls
          readOnly: true
      volumes:
      - name: tls-certs
        secret:
          secretName: app-tls
EOF

echo "Updated deployment YAML:"
cat /root/secure-deploy.yaml
echo ""

echo "STEP 4: Apply the deployment"
echo "--------"
echo '$ kubectl apply -f /root/secure-deploy.yaml'
kubectl apply -f /root/secure-deploy.yaml
echo ""

echo "STEP 5: Verify the pod has TLS mounted"
echo "--------"
sleep 5
POD=$(kubectl get pod -n secure -l app=secure-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD" ]; then
  echo '$ kubectl exec '$POD' -n secure -- ls /etc/tls'
  kubectl exec $POD -n secure -- ls /etc/tls 2>/dev/null || echo "(waiting for pod...)"
fi
echo ""

echo "=================================================================="
echo "  ✅ SOLUTION COMPLETE"
echo "=================================================================="
echo ""
echo "KEY POINTS:"
echo "  1. Create secret: kubectl create secret tls <name> --cert=<cert> --key=<key>"
echo "  2. Mount as volume with readOnly: true"
echo "  3. secretName in volume must match the created secret name"
echo "  4. Files inside /etc/tls will be: tls.crt and tls.key"
echo "  5. Always verify the mount works after applying"
