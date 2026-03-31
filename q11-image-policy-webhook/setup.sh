#!/bin/bash

# ============================================================================
# CKS EXAM REAL QUESTION — Q11: ImagePolicyWebhook Admission Controller
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS REAL Q11: IMAGEPOLICYWEBHOOK ADMISSION CONTROLLER"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  The ImagePolicyWebhook admission controller is not currently enabled."
echo ""
echo "TASK:"
echo "  - Complete the configuration for the ImagePolicyWebhook admission controller to validate container images before pods are created."
echo "  - Ensure the admission config and webhook kubeconfig are present and correct."
echo "  - Set defaultAllow to false to deny images not explicitly approved."
echo "  - Enable ImagePolicyWebhook in the kube-apiserver and mount the admission config directory."
echo ""
echo "=================================================================="
echo "  Setting up environment..."
echo "=================================================================="

# Ensure webhook server is deployed (install-prereqs.sh handles this)
if kubectl get deploy image-bouncer-webhook -n default &>/dev/null 2>&1; then
  echo "✅ Image Bouncer Webhook server is running"
else
  echo "Deploying Image Bouncer Webhook server..."
  # Generate TLS certs for the webhook server
  mkdir -p /etc/kubernetes/webhook-certs
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/kubernetes/webhook-certs/webhook.key \
    -out /etc/kubernetes/webhook-certs/webhook.crt \
    -subj "/CN=image-bouncer-webhook.default.svc" \
    -addext "subjectAltName=DNS:image-bouncer-webhook.default.svc,DNS:image-bouncer-webhook.default.svc.cluster.local" \
    2>/dev/null

  kubectl create secret tls webhook-tls \
    --cert=/etc/kubernetes/webhook-certs/webhook.crt \
    --key=/etc/kubernetes/webhook-certs/webhook.key \
    --dry-run=client -o yaml | kubectl apply -f -

  cat <<'WEBHOOK_EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: image-bouncer-webhook
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: image-bouncer-webhook
  template:
    metadata:
      labels:
        app: image-bouncer-webhook
    spec:
      containers:
      - name: webhook
        image: registry.k8s.io/e2e-test-images/agnhost:2.45
        args:
        - webhook
        - --tls-cert-file=/etc/webhook/certs/tls.crt
        - --tls-private-key-file=/etc/webhook/certs/tls.key
        ports:
        - containerPort: 1323
          protocol: TCP
        volumeMounts:
        - name: webhook-certs
          mountPath: /etc/webhook/certs
          readOnly: true
      volumes:
      - name: webhook-certs
        secret:
          secretName: webhook-tls
---
apiVersion: v1
kind: Service
metadata:
  name: image-bouncer-webhook
  namespace: default
spec:
  selector:
    app: image-bouncer-webhook
  ports:
  - port: 1323
    targetPort: 1323
    protocol: TCP
WEBHOOK_EOF
  echo "Waiting for webhook server..."
  kubectl wait --for=condition=available deployment/image-bouncer-webhook --timeout=60s 2>/dev/null || true
fi

mkdir -p /etc/kubernetes/admission

# Create a partial/broken admission config (student must fix)
cat <<'EOF' > /etc/kubernetes/admission/admission-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/admission/webhook-kubeconfig.yaml
      allowTTL: 50
      denyTTL: 50
      retryBackoff: 500
      defaultAllow: true
EOF

# Create webhook kubeconfig
cat <<'EOF' > /etc/kubernetes/admission/webhook-kubeconfig.yaml
apiVersion: v1
kind: Config
clusters:
- name: image-policy-webhook
  cluster:
    server: https://image-bouncer-webhook.default.svc:1323/image_policy
    certificate-authority: /etc/kubernetes/admission/webhook-ca.crt
contexts:
- name: image-policy-webhook
  context:
    cluster: image-policy-webhook
    user: api-server
current-context: image-policy-webhook
users:
- name: api-server
  user:
    client-certificate: /etc/kubernetes/pki/apiserver.crt
    client-key: /etc/kubernetes/pki/apiserver.key
EOF

# Use the webhook server's cert as the CA cert for admission config
if [ -f /etc/kubernetes/webhook-certs/webhook.crt ]; then
  cp /etc/kubernetes/webhook-certs/webhook.crt /etc/kubernetes/admission/webhook-ca.crt
elif [ -f /etc/kubernetes/pki/ca.crt ]; then
  cp /etc/kubernetes/pki/ca.crt /etc/kubernetes/admission/webhook-ca.crt
else
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /tmp/webhook-ca.key \
    -out /etc/kubernetes/admission/webhook-ca.crt \
    -subj "/CN=image-policy-webhook" 2>/dev/null
fi

echo ""
echo "✅ Environment ready!"
echo ""
echo "Files to review/fix:"
echo "  /etc/kubernetes/admission/admission-config.yaml"
echo "  /etc/kubernetes/admission/webhook-kubeconfig.yaml"
echo ""
echo "ISSUES TO FIX:"
echo "  1. admission-config.yaml has defaultAllow: true (should be false)"
echo "  2. kube-apiserver needs ImagePolicyWebhook admission plugin enabled"
echo "  3. kube-apiserver needs --admission-control-config-file flag"
echo "  4. Volume mount needed for /etc/kubernetes/admission"
echo ""
echo "Run 'bash verify.sh' after solving to check your answer."
