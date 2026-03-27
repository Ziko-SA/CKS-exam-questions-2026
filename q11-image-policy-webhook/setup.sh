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

# Create a fake CA cert for the webhook
if [ -f /etc/kubernetes/pki/ca.crt ]; then
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
echo "Run 'bash solution.sh' when ready to see the answer."
