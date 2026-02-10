#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q11: ImagePolicyWebhook
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS PRACTICE Q11: IMAGEPOLICYWEBHOOK"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  You need to enable the ImagePolicyWebhook admission controller"
echo "  to validate container images before pods are created."
echo ""
echo "TASK:"
echo "  1. An admission webhook server is running (simulated)."
echo "     The configuration files are partially set up."
echo ""
echo "  2. Complete the ImagePolicyWebhook configuration:"
echo "     a. Create/fix the admission config at"
echo "        /etc/kubernetes/admission/admission-config.yaml"
echo "     b. Create/fix the webhook kubeconfig at"
echo "        /etc/kubernetes/admission/webhook-kubeconfig.yaml"
echo "     c. Set defaultAllow to false (deny images not approved)"
echo ""
echo "  3. Enable ImagePolicyWebhook in the kube-apiserver:"
echo "     a. Add ImagePolicyWebhook to --enable-admission-plugins"
echo "     b. Set --admission-control-config-file"
echo "     c. Mount the admission config directory"
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
