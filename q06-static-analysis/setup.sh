#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q06: Static File Analysis
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS PRACTICE Q06: STATIC FILE ANALYSIS"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  You are given a Dockerfile and a Kubernetes deployment YAML file."
echo "  Both have security issues that need to be fixed."
echo ""
echo "TASK:"
echo "  1. In the Dockerfile at /root/Dockerfile:"
echo "     Change ONE line only — DO NOT add or remove any lines."
echo "     DO NOT build the image."
echo "     Fix: Change 'USER root' to 'USER couchdb'"
echo ""
echo "  2. In the deployment YAML at /root/deploy.yaml:"
echo "     Change ONE line only — DO NOT add or remove any lines."
echo "     Fix: Change 'readOnlyRootFilesystem: false' to"
echo "          'readOnlyRootFilesystem: true'"
echo ""
echo "IMPORTANT:"
echo "  - Only change the specified lines"
echo "  - Do NOT add or remove any lines"
echo "  - Do NOT build the Docker image"
echo ""
echo "=================================================================="
echo "  Setting up environment..."
echo "=================================================================="

# Create Dockerfile with security issues
cat <<'DOCKERFILE' > /root/Dockerfile
FROM debian:bullseye-slim

LABEL maintainer="admin@example.com"

ENV COUCHDB_VERSION=3.3.2

RUN groupadd -g 5984 -r couchdb && \
    useradd -u 5984 -d /opt/couchdb -g couchdb couchdb

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        erlang-nox \
        libicu67 \
        libmozjs-78-0 \
        openssl && \
    rm -rf /var/lib/apt/lists/*

COPY --chown=couchdb:couchdb ./opt/couchdb /opt/couchdb

RUN find /opt/couchdb \! \( -user couchdb -group couchdb \) -exec chown -f couchdb:couchdb '{}' +

VOLUME /opt/couchdb/data

EXPOSE 5984 4369 9100

WORKDIR /opt/couchdb

USER root

CMD ["/opt/couchdb/bin/couchdb"]
DOCKERFILE

# Create deployment with security issues
cat <<'EOF' > /root/deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: couchdb-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: couchdb
  template:
    metadata:
      labels:
        app: couchdb
    spec:
      containers:
      - name: couchdb
        image: couchdb:3.3.2
        ports:
        - containerPort: 5984
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: false
          runAsNonRoot: true
          capabilities:
            drop:
            - ALL
      serviceAccountName: default
EOF

echo ""
echo "✅ Environment ready!"
echo ""
echo "Files to fix:"
echo "  /root/Dockerfile  — Fix the USER line"
echo "  /root/deploy.yaml — Fix readOnlyRootFilesystem"
echo ""
echo "HINTS:"
echo "  - Use 'sed' or your editor to change exactly one line per file"
echo "  - Dockerfile: the USER directive near the end"
echo "  - deploy.yaml: the readOnlyRootFilesystem field"
echo ""
echo "Run 'bash solution.sh' when ready to see the answer."
