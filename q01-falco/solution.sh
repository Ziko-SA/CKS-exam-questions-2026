#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q01 SOLUTION: Falco Runtime Security
# ============================================================================

echo "=================================================================="
echo "  SOLUTION Q01: FALCO — RUNTIME SECURITY"
echo "=================================================================="
echo ""

echo "STEP 1: Analyze Falco logs to find pods accessing /dev/mem"
echo "--------"
echo '$ cat /var/log/falco/falco_alerts.log | grep "/dev/mem"'
echo ""
cat /var/log/falco/falco_alerts.log | grep "/dev/mem"
echo ""
echo "From the logs we can identify the deployments:"
echo "  - nvidia-app (k8s_ns=monitoring)"
echo "  - cpu-app    (k8s_ns=monitoring)"
echo "  - ollama-app (k8s_ns=monitoring)"
echo ""

echo "STEP 2: Verify current state of deployments"
echo "--------"
kubectl get deploy -n monitoring
echo ""

echo "STEP 3: Scale down ALL offending deployments to 0 replicas"
echo "--------"
echo '$ kubectl scale deployment nvidia-app cpu-app ollama-app --replicas=0 -n monitoring'
kubectl scale deployment nvidia-app cpu-app ollama-app --replicas=0 -n monitoring
echo ""

echo "STEP 4: Verify no pods remain from those deployments"
echo "--------"
sleep 3
kubectl get deploy -n monitoring
echo ""
kubectl get pods -n monitoring
echo ""

echo "=================================================================="
echo "  ✅ SOLUTION COMPLETE"
echo "=================================================================="
echo ""
echo "KEY POINTS:"
echo "  1. Read Falco logs to identify offending pods/deployments"
echo "  2. Use 'kubectl scale deployment <name> --replicas=0 -n <ns>'"
echo "  3. Do NOT delete deployments — only scale to 0"
echo "  4. Verify with 'kubectl get pods -n monitoring'"
echo "  5. The safe-app should still be running"
