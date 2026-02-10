#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q04 SOLUTION: Docker Daemon Security
# ============================================================================

echo "=================================================================="
echo "  SOLUTION Q04: DOCKER DAEMON SECURITY"
echo "=================================================================="
echo ""

echo "STEP 1: Remove user 'develop' from the docker group"
echo "--------"
echo '$ gpasswd -d develop docker'
gpasswd -d develop docker 2>/dev/null || echo "(simulated: user removed from group)"
echo ""
echo "Verify:"
echo '$ groups develop'
groups develop 2>/dev/null || echo "develop : develop"
echo ""

echo "STEP 2: Change ownership of Docker socket to root:root"
echo "--------"
echo '$ chown root:root /var/run/docker.sock'
echo '$ chmod 660 /var/run/docker.sock'
# In real exam:
# chown root:root /var/run/docker.sock
# chmod 660 /var/run/docker.sock
echo "(simulated — would run on actual Docker socket)"
echo ""

echo "STEP 3: Fix Docker daemon to use Unix socket instead of TCP"
echo "--------"
echo "Edit /lib/systemd/system/docker.service"
echo ""
echo "BEFORE (insecure):"
echo "  ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 --containerd=/run/containerd/containerd.sock"
echo ""
echo "AFTER (secure):"
echo "  ExecStart=/usr/bin/dockerd -H unix:///var/run/docker.sock --containerd=/run/containerd/containerd.sock"
echo ""

# Apply the fix to the simulated file
sed -i 's|-H tcp://0.0.0.0:2375|-H unix:///var/run/docker.sock|' /tmp/cks-q04/docker.service
echo "Fixed file:"
grep "ExecStart" /tmp/cks-q04/docker.service
echo ""

echo "STEP 4: Reload systemd and restart Docker"
echo "--------"
echo '$ systemctl daemon-reload'
echo '$ systemctl restart docker'
# In real exam:
# systemctl daemon-reload
# systemctl restart docker
echo "(simulated — would restart Docker on actual node)"
echo ""

echo "STEP 5: Verify Docker is working"
echo "--------"
echo '$ docker ps'
echo '$ ss -tlnp | grep 2375   # Should show nothing (TCP closed)'
echo ""

echo "=================================================================="
echo "  ✅ SOLUTION COMPLETE"
echo "=================================================================="
echo ""
echo "KEY POINTS:"
echo "  1. Remove user from group: gpasswd -d <user> <group>"
echo "  2. Fix socket ownership: chown root:root /var/run/docker.sock"
echo "  3. Edit docker.service: change tcp:// to unix://"
echo "  4. Always: systemctl daemon-reload && systemctl restart docker"
echo "  5. Verify: docker ps works AND port 2375 is NOT listening"
echo ""
echo "COMMON MISTAKES:"
echo "  - Forgetting systemctl daemon-reload before restart"
echo "  - Using 'deluser' instead of 'gpasswd -d'"
echo "  - Not verifying Docker works after changes"
