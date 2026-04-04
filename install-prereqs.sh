#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Master Prerequisites Installer
# ============================================================================
# Installs all tools and components needed to simulate a real CKS exam.
# Run this ONCE before starting any questions.
#
# Usage:
#   bash install-prereqs.sh          # Install everything
#   bash install-prereqs.sh --skip-istio   # Skip Istio (heavy, ~3 min)
# ============================================================================

SKIP_ISTIO=false
for arg in "$@"; do
  case "$arg" in
    --skip-istio) SKIP_ISTIO=true ;;
  esac
done

PASS=0
SKIP=0
FAIL=0

log()  { echo -e "\n\033[1;34m>>> $1\033[0m"; }
ok()   { echo "  ✅ $1"; PASS=$((PASS + 1)); }
skip() { echo "  ⏭️  $1 (already installed)"; SKIP=$((SKIP + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }

# ── Helm ───────────────────────────────────────────────────────────────────
log "Helm"
if command -v helm &>/dev/null; then
  skip "helm $(helm version --short 2>/dev/null)"
else
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && ok "Helm installed" || fail "Helm install failed"
fi

# ── Falco (Q01) ───────────────────────────────────────────────────────────
log "Falco (Q01 — Runtime Security)"
if helm list -A 2>/dev/null | grep -q falco; then
  skip "Falco Helm release exists"
else
  helm repo add falcosecurity https://falcosecurity.github.io/charts 2>/dev/null || true
  helm repo update falcosecurity 2>/dev/null
  helm install falco falcosecurity/falco \
    --namespace falco --create-namespace \
    --set driver.kind=modern_ebpf \
    --set tty=true \
    --set falcosidekick.enabled=false \
    --wait --timeout 120s \
    && ok "Falco installed via Helm" \
    || fail "Falco install failed (kernel may not support modern_ebpf — logs will be simulated)"
fi

# ── NGINX Ingress Controller (Q03) ────────────────────────────────────────
log "NGINX Ingress Controller (Q03 — Ingress TLS)"
if kubectl get deploy -n ingress-nginx ingress-nginx-controller &>/dev/null 2>&1; then
  skip "NGINX Ingress Controller"
else
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0/deploy/static/provider/baremetal/deploy.yaml
  echo "  Waiting for Ingress Controller to be ready..."
  kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=180s 2>/dev/null \
    && ok "NGINX Ingress Controller installed" \
    || fail "Ingress Controller not ready (may still be pulling image)"
fi

# ── Istio (Q02) ───────────────────────────────────────────────────────────
log "Istio (Q02 — mTLS & Sidecar Injection)"
if [ "$SKIP_ISTIO" = true ]; then
  skip "Istio (--skip-istio flag)"
elif command -v istioctl &>/dev/null; then
  skip "istioctl $(istioctl version --remote=false 2>/dev/null)"
else
  echo "  Downloading Istio..."
  cd /tmp
  curl -fsSL https://istio.io/downloadIstio | ISTIO_VERSION=1.24.2 sh - 2>/dev/null
  cp /tmp/istio-*/bin/istioctl /usr/local/bin/ 2>/dev/null
  echo "  Installing Istio demo profile..."
  istioctl install --set profile=demo -y 2>/dev/null \
    && ok "Istio installed (demo profile)" \
    || fail "Istio install failed"
  cd - >/dev/null
fi

# ── kube-bench (Q09) ──────────────────────────────────────────────────────
log "kube-bench (Q09 — CIS Benchmarks)"
if command -v kube-bench &>/dev/null; then
  skip "kube-bench"
else
  KBENCH_VER="0.9.3"
  curl -fsSL "https://github.com/aquasecurity/kube-bench/releases/download/v${KBENCH_VER}/kube-bench_${KBENCH_VER}_linux_amd64.tar.gz" \
    -o /tmp/kube-bench.tar.gz
  mkdir -p /tmp/kube-bench-extract
  tar xzf /tmp/kube-bench.tar.gz -C /tmp/kube-bench-extract
  cp /tmp/kube-bench-extract/kube-bench /usr/local/bin/
  chmod +x /usr/local/bin/kube-bench
  # Copy cfg directory for kube-bench to work
  mkdir -p /etc/kube-bench
  cp -r /tmp/kube-bench-extract/cfg /etc/kube-bench/ 2>/dev/null || true
  rm -rf /tmp/kube-bench-extract /tmp/kube-bench.tar.gz
  if [ -f /usr/local/bin/kube-bench ]; then
    ok "kube-bench ${KBENCH_VER} installed"
  else
    fail "kube-bench install failed"
  fi
fi

# ── syft (Q05 — SBOM) ────────────────────────────────────────────────────
log "syft (Q05 — SBOM Generation)"
if command -v syft &>/dev/null; then
  skip "syft $(syft version 2>/dev/null | head -1)"
else
  curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin 2>/dev/null \
    && ok "syft installed" \
    || fail "syft install failed"
fi

# ── trivy (Q05 — Vulnerability Scanning) ─────────────────────────────────
log "trivy (Q05 — Image Scanning)"
if command -v trivy &>/dev/null; then
  skip "trivy $(trivy --version 2>/dev/null | head -1)"
else
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin 2>/dev/null \
    && ok "trivy installed" \
    || fail "trivy install failed"
fi

# ── Image Bouncer Webhook (Q11) ──────────────────────────────────────────
log "Image Policy Webhook Server (Q11 — ImagePolicyWebhook)"
# Wait for API server to be reachable (may be recovering after Istio install)
echo "  Waiting for API server to be ready..."
for i in $(seq 1 30); do
  kubectl get nodes &>/dev/null && break
  echo "  API server not ready yet... retrying ($i/30)"
  sleep 5
done

if kubectl get deploy image-bouncer-webhook -n default &>/dev/null 2>&1; then
  skip "image-bouncer-webhook deployment"
else
  # Generate TLS certs for the webhook server
  mkdir -p /etc/kubernetes/webhook-certs
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/kubernetes/webhook-certs/webhook.key \
    -out /etc/kubernetes/webhook-certs/webhook.crt \
    -subj "/CN=image-bouncer-webhook.default.svc" \
    -addext "subjectAltName=DNS:image-bouncer-webhook.default.svc,DNS:image-bouncer-webhook.default.svc.cluster.local" \
    2>/dev/null

  # Deploy the webhook server
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
        - --deny-name=nginx:latest
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

  # Copy the CA cert for the admission config
  cp /etc/kubernetes/webhook-certs/webhook.crt /etc/kubernetes/admission/webhook-ca.crt 2>/dev/null || true
  if kubectl get deploy image-bouncer-webhook -n default &>/dev/null 2>&1; then
    ok "Image Bouncer Webhook deployed"
  else
    fail "Webhook deployment failed"
  fi
fi

# ── Verify cluster basics ────────────────────────────────────────────────
log "Cluster Health Check"
if kubectl cluster-info &>/dev/null; then
  ok "Cluster is reachable"
  NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
  echo "  Nodes: $NODE_COUNT"
  kubectl get nodes -o wide 2>/dev/null | head -5
else
  fail "Cannot reach cluster — kubectl cluster-info failed"
fi

# ── Summary ──────────────────────────────────────────────────────────────
echo ""
echo "=================================================================="
echo "  PREREQUISITES SUMMARY"
echo "=================================================================="
echo "  ✅ Installed: $PASS"
echo "  ⏭️  Skipped:   $SKIP"
echo "  ❌ Failed:    $FAIL"
echo "=================================================================="
echo ""
if [ "$FAIL" -gt 0 ]; then
  echo "⚠️  Some installs failed. Questions using those tools may not"
  echo "   be fully testable, but you can still practice the YAML/concepts."
fi
echo ""
echo "You're ready! Run any question's setup.sh to begin:"
echo "  cd q01-falco && bash setup.sh"
echo ""
