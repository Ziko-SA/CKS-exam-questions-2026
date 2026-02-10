#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q06 SOLUTION: Static File Analysis
# ============================================================================

echo "=================================================================="
echo "  SOLUTION Q06: STATIC FILE ANALYSIS"
echo "=================================================================="
echo ""

echo "STEP 1: Fix the Dockerfile — Change USER root to USER couchdb"
echo "--------"
echo '$ sed -i "s/^USER root/USER couchdb/" /root/Dockerfile'
sed -i "s/^USER root/USER couchdb/" /root/Dockerfile
echo ""
echo "Verify the Dockerfile:"
grep -n "USER" /root/Dockerfile
echo ""

echo "STEP 2: Fix deploy.yaml — Change readOnlyRootFilesystem to true"
echo "--------"
echo '$ sed -i "s/readOnlyRootFilesystem: false/readOnlyRootFilesystem: true/" /root/deploy.yaml'
sed -i "s/readOnlyRootFilesystem: false/readOnlyRootFilesystem: true/" /root/deploy.yaml
echo ""
echo "Verify the deployment:"
grep -n "readOnlyRootFilesystem" /root/deploy.yaml
echo ""

echo "STEP 3: Verify full files"
echo "--------"
echo "=== Dockerfile ==="
cat /root/Dockerfile
echo ""
echo "=== deploy.yaml ==="
cat /root/deploy.yaml
echo ""

echo "=================================================================="
echo "  ✅ SOLUTION COMPLETE"
echo "=================================================================="
echo ""
echo "KEY POINTS:"
echo "  1. Change ONE line only — use sed for precision"
echo "  2. Dockerfile: USER root → USER couchdb"
echo "     (container should not run as root)"
echo "  3. deploy.yaml: readOnlyRootFilesystem: false → true"
echo "     (prevents writes to container filesystem)"
echo "  4. Do NOT build the image, do NOT add/remove lines"
echo "  5. These are CIS benchmark best practices for container security"
