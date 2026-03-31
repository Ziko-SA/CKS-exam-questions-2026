#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q04: Docker Daemon Security
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS PRACTICE Q04: DOCKER DAEMON SECURITY"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  The Docker daemon on this node has several security issues that"
echo "  need to be fixed."
echo ""
echo "TASK:"
echo "  1. Remove user 'develop' from the 'docker' group"
echo "  2. Change ownership of Docker socket /var/run/docker.sock to"
echo "     root:root"
echo "  3. Change Docker daemon to use Unix socket instead of TCP by"
echo "     editing /lib/systemd/system/docker.service"
echo "     (change -H tcp://0.0.0.0:2375 to -H unix:///var/run/docker.sock)"
echo ""
echo "IMPORTANT:"
echo "  - After all changes, restart the Docker daemon"
echo "  - Verify Docker still works after changes"
echo ""
echo "=================================================================="
echo "  Setting up environment..."
echo "=================================================================="

# Create the 'develop' user and add to docker group
id -u develop &>/dev/null || useradd -m develop
getent group docker &>/dev/null || groupadd docker
usermod -aG docker develop 2>/dev/null || true

# Simulate insecure docker.service file
mkdir -p /tmp/cks-q04
cat <<'EOF' > /tmp/cks-q04/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target docker.socket firewalld.service containerd.service
Wants=network-online.target containerd.service

[Service]
Type=notify
ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 --containerd=/run/containerd/containerd.sock
ExecReload=/bin/kill -s HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF

# Simulate insecure socket ownership
echo ""
echo "NOTE: This is a simulation. In the real exam, you will edit actual"
echo "system files. For practice, files are at /tmp/cks-q04/"
echo ""

echo "Current state (simulated):"
echo "  - User 'develop' is in the 'docker' group:"
echo "    $(groups develop 2>/dev/null || echo '    develop : develop docker')"
echo "  - Docker socket ownership: develop:docker (INSECURE)"
echo "  - Docker daemon listening on: tcp://0.0.0.0:2375 (INSECURE)"
echo ""

echo "Files to edit:"
echo "  /tmp/cks-q04/docker.service (simulates /lib/systemd/system/docker.service)"
echo ""

echo "✅ Environment ready!"

#!/bin/bash
# ============================================================================
# CKS REAL EXAM QUESTION 4: Secure Docker Daemon
# ============================================================================

set -e

echo ""
echo "Run 'bash verify.sh' after solving to check your answer."
