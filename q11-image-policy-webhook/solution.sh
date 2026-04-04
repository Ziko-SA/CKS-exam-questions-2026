#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q11 SOLUTION: ImagePolicyWebhook
# ============================================================================

echo "=================================================================="
echo "  SOLUTION Q11: IMAGEPOLICYWEBHOOK"
echo "=================================================================="
echo ""

echo "STEP 1: Fix the admission config — set defaultAllow to false"
echo "--------"
echo '$ sed -i "s/defaultAllow: true/defaultAllow: false/" /etc/kubernetes/admission/admission-config.yaml'
sed -i "s/defaultAllow: true/defaultAllow: false/" /etc/kubernetes/admission/admission-config.yaml
echo ""
echo "Fixed admission-config.yaml:"
cat /etc/kubernetes/admission/admission-config.yaml
echo ""

echo "STEP 2: Fix webhook kubeconfig server value"
echo "--------"
WEBHOOK_SERVER="https://image-bouncer-webhook.default.svc:1323/image_policy"
if grep -Eq '^[[:space:]]*server:[[:space:]]*""[[:space:]]*$' /etc/kubernetes/admission/webhook-kubeconfig.yaml; then
  sed -i "s#^[[:space:]]*server:[[:space:]]*\"\"[[:space:]]*$#    server: ${WEBHOOK_SERVER}#" /etc/kubernetes/admission/webhook-kubeconfig.yaml
  echo "✅ Set webhook kubeconfig server to ${WEBHOOK_SERVER}"
elif grep -Eq '^[[:space:]]*server:[[:space:]]*$' /etc/kubernetes/admission/webhook-kubeconfig.yaml; then
  sed -i "s#^[[:space:]]*server:[[:space:]]*$#    server: ${WEBHOOK_SERVER}#" /etc/kubernetes/admission/webhook-kubeconfig.yaml
  echo "✅ Set webhook kubeconfig server to ${WEBHOOK_SERVER}"
else
  echo "Webhook kubeconfig server already set"
fi
echo ""
echo "webhook-kubeconfig.yaml:"
cat /etc/kubernetes/admission/webhook-kubeconfig.yaml
echo ""

echo "STEP 3: Enable ImagePolicyWebhook in kube-apiserver"
echo "--------"

APISERVER="/etc/kubernetes/manifests/kube-apiserver.yaml"

if [ -f "$APISERVER" ]; then
  # Add ImagePolicyWebhook to enable-admission-plugins
  if grep -q "enable-admission-plugins" "$APISERVER"; then
    if ! grep -q "ImagePolicyWebhook" "$APISERVER"; then
      sed -i 's/--enable-admission-plugins=\(.*\)/--enable-admission-plugins=\1,ImagePolicyWebhook/' "$APISERVER"
      echo "✅ Added ImagePolicyWebhook to existing admission plugins"
    else
      echo "ImagePolicyWebhook already in admission plugins"
    fi
  else
    sed -i '/- --tls-private-key-file/a\    - --enable-admission-plugins=NodeRestriction,ImagePolicyWebhook' "$APISERVER"
    echo "✅ Added --enable-admission-plugins with ImagePolicyWebhook"
  fi

  # Add admission control config file
  if ! grep -q "admission-control-config-file" "$APISERVER"; then
    sed -i '/--enable-admission-plugins/a\    - --admission-control-config-file=/etc/kubernetes/admission/admission-config.yaml' "$APISERVER"
    echo "✅ Added --admission-control-config-file"
  fi

  # Add volume mount for admission config
  if ! grep -q "mountPath: /etc/kubernetes/admission" "$APISERVER"; then
    sed -i '/volumeMounts:/a\    - mountPath: /etc/kubernetes/admission\n      name: admission-config\n      readOnly: true' "$APISERVER"
    echo "✅ Added volumeMount for admission config"
  fi

  # Add volume for admission config
  if ! grep -q "path: /etc/kubernetes/admission" "$APISERVER"; then
    sed -i '/volumes:/a\  - hostPath:\n      path: /etc/kubernetes/admission\n      type: DirectoryOrCreate\n    name: admission-config' "$APISERVER"
    echo "✅ Added hostPath volume for admission config"
  fi

  echo ""
  echo "Waiting for kube-apiserver to restart..."
  sleep 15
  kubectl wait --for=condition=Ready pod -l component=kube-apiserver -n kube-system --timeout=120s 2>/dev/null || echo "(waiting...)"
else
  echo "⚠ kube-apiserver manifest not found. Manual steps:"
  echo ""
  echo "1. Add to --enable-admission-plugins: ImagePolicyWebhook"
  echo "2. Add flag: --admission-control-config-file=/etc/kubernetes/admission/admission-config.yaml"
  echo "3. Add volumeMount:"
  cat <<'YAML'
    - mountPath: /etc/kubernetes/admission
      name: admission-config
      readOnly: true
YAML
  echo "4. Add volume:"
  cat <<'YAML'
  - hostPath:
      path: /etc/kubernetes/admission
      type: DirectoryOrCreate
    name: admission-config
YAML
fi
echo ""

echo "STEP 4: Verify"
echo "--------"
echo '$ kubectl get pods -n kube-system | grep apiserver'
kubectl get pods -n kube-system 2>/dev/null | grep apiserver || true
echo ""

echo "=================================================================="
echo "  ✅ SOLUTION COMPLETE"
echo "=================================================================="
echo ""
echo "KEY POINTS:"
echo "  1. defaultAllow: false — reject images not explicitly approved"
echo "  2. Add ImagePolicyWebhook to --enable-admission-plugins"
echo "  3. Set --admission-control-config-file pointing to the admission config"
echo "  4. The admission config references the webhook kubeconfig"
echo "  5. Mount the /etc/kubernetes/admission directory into the apiserver pod"
echo ""
echo "STRUCTURE:"
echo "  kube-apiserver → admission-config.yaml → webhook-kubeconfig.yaml → webhook server"
