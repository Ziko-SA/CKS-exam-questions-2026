#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q01: Falco Runtime Security
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS PRACTICE Q01: FALCO — RUNTIME SECURITY"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  A Falco instance is running on the cluster. You have been alerted"
echo "  that several pods are accessing /dev/mem, which is a security risk."
echo ""
echo "TASK:"
echo "  1. Use Falco logs to identify pods that are accessing /dev/mem"
echo "  2. Given: 3 deployments (nvidia-app, cpu-app, ollama-app) in the"
echo "     namespace 'monitoring' are accessing /dev/mem"
echo "  3. Scale down the replicas to 0 for ALL pods/deployments that"
echo "     are accessing /dev/mem"
echo ""
echo "NOTES:"
echo "  - Do NOT delete the deployments, only scale them to 0 replicas"
echo "  - Ensure no pods from those deployments remain running"
echo ""
echo "=================================================================="
echo "  Setting up environment..."
echo "=================================================================="

# Create namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Create the 3 offending deployments
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nvidia-app
  namespace: monitoring
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nvidia-app
  template:
    metadata:
      labels:
        app: nvidia-app
    spec:
      containers:
      - name: nvidia
        image: busybox:1.36
        command: ["sh", "-c", "while true; do echo 'nvidia processing...'; sleep 5; done"]
        securityContext:
          privileged: true
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-app
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cpu-app
  template:
    metadata:
      labels:
        app: cpu-app
    spec:
      containers:
      - name: cpu
        image: busybox:1.36
        command: ["sh", "-c", "while true; do echo 'cpu processing...'; sleep 5; done"]
        securityContext:
          privileged: true
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ollama-app
  namespace: monitoring
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ollama-app
  template:
    metadata:
      labels:
        app: ollama-app
    spec:
      containers:
      - name: ollama
        image: busybox:1.36
        command: ["sh", "-c", "while true; do echo 'ollama inference...'; sleep 5; done"]
        securityContext:
          privileged: true
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: safe-app
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: safe-app
  template:
    metadata:
      labels:
        app: safe-app
    spec:
      containers:
      - name: safe
        image: busybox:1.36
        command: ["sh", "-c", "while true; do echo 'safe app running'; sleep 10; done"]
EOF

# Simulate Falco logs
mkdir -p /var/log/falco
cat <<'EOF' > /var/log/falco/falco_alerts.log
2025-08-15T10:23:01.123456789+0000 Warning Sensitive file opened for reading (user=root user_loginuid=-1 program=cat command=cat /dev/mem file=/dev/mem container_id=abc123 container_name=nvidia k8s_ns=monitoring k8s_pod=nvidia-app-7f8d9c6b5-x2k4l)
2025-08-15T10:23:05.234567890+0000 Warning Sensitive file opened for reading (user=root user_loginuid=-1 program=cat command=cat /dev/mem file=/dev/mem container_id=def456 container_name=cpu k8s_ns=monitoring k8s_pod=cpu-app-5c4d3b2a1-m8n7p)
2025-08-15T10:23:09.345678901+0000 Warning Sensitive file opened for reading (user=root user_loginuid=-1 program=dd command=dd if=/dev/mem file=/dev/mem container_id=ghi789 container_name=ollama k8s_ns=monitoring k8s_pod=ollama-app-9e8f7d6c5-q3r2s)
2025-08-15T10:24:01.456789012+0000 Warning Sensitive file opened for reading (user=root user_loginuid=-1 program=cat command=cat /dev/mem file=/dev/mem container_id=abc124 container_name=nvidia k8s_ns=monitoring k8s_pod=nvidia-app-7f8d9c6b5-y5z6w)
EOF

echo ""
echo "✅ Environment ready!"
echo ""
echo "HINTS:"
echo "  - Falco logs are at: /var/log/falco/falco_alerts.log"
echo "  - Check deployments: kubectl get deploy -n monitoring"
echo "  - Grep the logs for /dev/mem to find offending pods"
echo ""
echo "Run 'bash solution.sh' when ready to see the answer."
