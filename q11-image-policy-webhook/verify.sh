#!/bin/bash
# ============================================================================
# CKS Q11: ImagePolicyWebhook — Verify Solution
# ============================================================================

PASS=0; FAIL=0
check() {
  if eval "$2" &>/dev/null; then
    echo "✅ PASS: $1"; ((PASS++))
  else
    echo "❌ FAIL: $1"; ((FAIL++))
  fi
}

echo "=================================================================="
echo "  VERIFYING Q11: IMAGE POLICY WEBHOOK"
echo "=================================================================="
echo ""

ADMISSION_CONFIG="/etc/kubernetes/admission/admission-config.yaml"
APISERVER="/etc/kubernetes/manifests/kube-apiserver.yaml"
WEBHOOK_KUBECONFIG="/etc/kubernetes/admission/webhook-kubeconfig.yaml"

# Check webhook TLS secret exists and has required keys
check "Webhook TLS secret exists" \
  'kubectl get secret webhook-tls -n default >/dev/null 2>&1'

check "Webhook TLS secret has tls.crt" \
  'kubectl get secret webhook-tls -n default -o jsonpath="{.data.tls\\.crt}" 2>/dev/null | grep -q "."'

check "Webhook TLS secret has tls.key" \
  'kubectl get secret webhook-tls -n default -o jsonpath="{.data.tls\\.key}" 2>/dev/null | grep -q "."'

# Check webhook deployment is configured to use TLS certs
check "Webhook deployment exists" \
  'kubectl get deploy image-bouncer-webhook -n default >/dev/null 2>&1'

check "Webhook container uses tls-cert-file arg" \
  'kubectl get deploy image-bouncer-webhook -n default -o jsonpath="{.spec.template.spec.containers[0].args}" 2>/dev/null | grep -q "--tls-cert-file=/etc/webhook/certs/tls.crt"'

check "Webhook container uses tls-private-key-file arg" \
  'kubectl get deploy image-bouncer-webhook -n default -o jsonpath="{.spec.template.spec.containers[0].args}" 2>/dev/null | grep -q "--tls-private-key-file=/etc/webhook/certs/tls.key"'

check "Webhook deployment mounts webhook cert secret" \
  'kubectl get deploy image-bouncer-webhook -n default -o jsonpath="{.spec.template.spec.volumes[?(@.name==\"webhook-certs\")].secret.secretName}" 2>/dev/null | grep -q "webhook-tls"'

check "Webhook service has ready endpoints" \
  'kubectl get endpoints image-bouncer-webhook -n default -o jsonpath="{.subsets[0].addresses[0].ip}" 2>/dev/null | grep -q "."'

# Check admission config has defaultAllow: false
check "Admission config has 'defaultAllow: false'" \
  'grep -q "defaultAllow.*false" "$ADMISSION_CONFIG" 2>/dev/null'

check "Admission config does NOT have 'defaultAllow: true'" \
  '! grep -q "defaultAllow.*true" "$ADMISSION_CONFIG" 2>/dev/null'

# Check webhook kubeconfig server is set (not empty)
check "Webhook kubeconfig server is set" \
  'grep -Eq "^[[:space:]]*server:[[:space:]]*https://image-bouncer-webhook\\.default\\.svc:1323/image_policy[[:space:]]*$" "$WEBHOOK_KUBECONFIG" 2>/dev/null'

# Check apiserver has ImagePolicyWebhook in admission plugins
check "kube-apiserver has ImagePolicyWebhook in --enable-admission-plugins" \
  'grep -q "ImagePolicyWebhook" "$APISERVER" 2>/dev/null'

# Check apiserver has --admission-control-config-file
check "kube-apiserver has --admission-control-config-file flag" \
  'grep -q "\-\-admission-control-config-file" "$APISERVER" 2>/dev/null'

# Check volume mount and volume for admission config
check "kube-apiserver has volumeMount for /etc/kubernetes/admission" \
  'grep -q "mountPath: /etc/kubernetes/admission" "$APISERVER" 2>/dev/null'

check "kube-apiserver has hostPath volume for /etc/kubernetes/admission" \
  'grep -q "path: /etc/kubernetes/admission" "$APISERVER" 2>/dev/null'

# Check apiserver is still running
check "kube-apiserver pod is running after changes" \
  'kubectl get pods -n kube-system -l component=kube-apiserver --no-headers 2>/dev/null | grep -q "Running"'

# Functional test: try to create a pod with denied image
echo ""
echo "Running functional test..."
if kubectl get deploy image-bouncer-webhook -n default &>/dev/null 2>&1; then
  # Try creating a pod with a denied image (nginx:latest should be denied)
  TEST_RESULT=$(kubectl run test-denied --image=nginx:latest --dry-run=server 2>&1)
  if echo "$TEST_RESULT" | grep -qi "denied\|forbidden\|rejected"; then
    echo "✅ PASS: Webhook correctly denied nginx:latest"; ((PASS++))
  else
    echo "⚠️  INFO: Could not confirm webhook is denying images (webhook may allow this image)"
  fi
  kubectl delete pod test-denied --ignore-not-found &>/dev/null
else
  echo "  ℹ️  Webhook server not deployed — run 'bash install-prereqs.sh' to install"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All checks passed!" || exit 1
