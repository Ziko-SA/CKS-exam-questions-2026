#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q15 SOLUTION: Seccomp Profile
# ============================================================================

echo "=================================================================="
echo "  SOLUTION Q15: SECCOMP PROFILE"
echo "=================================================================="
echo ""

echo "STEP 1: Create pod with custom Localhost Seccomp profile"
echo "--------"

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: seccomp-pod
  namespace: secure-ns
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/audit.json
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "echo Seccomp applied! && sleep 3600"]
EOF

echo ""
echo "Pod YAML:"
cat <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: seccomp-pod
  namespace: secure-ns
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/audit.json   # Relative to /var/lib/kubelet/seccomp/
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "echo Seccomp applied! && sleep 3600"]
EOF
echo ""

echo "STEP 2: Create pod with RuntimeDefault Seccomp profile"
echo "--------"

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: default-seccomp-pod
  namespace: secure-ns
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "echo Default Seccomp! && sleep 3600"]
EOF

echo ""
echo "Pod YAML:"
cat <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: default-seccomp-pod
  namespace: secure-ns
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "echo Default Seccomp! && sleep 3600"]
EOF
echo ""

echo "STEP 3: Verify pods are running"
echo "--------"
sleep 8
echo '$ kubectl get pods -n secure-ns'
kubectl get pods -n secure-ns
echo ""

echo "STEP 4: Check Seccomp is applied"
echo "--------"
echo '$ kubectl get pod seccomp-pod -n secure-ns -o jsonpath="{.spec.securityContext.seccompProfile}"'
kubectl get pod seccomp-pod -n secure-ns -o jsonpath='{.spec.securityContext.seccompProfile}' 2>/dev/null
echo ""
echo '$ kubectl get pod default-seccomp-pod -n secure-ns -o jsonpath="{.spec.securityContext.seccompProfile}"'
kubectl get pod default-seccomp-pod -n secure-ns -o jsonpath='{.spec.securityContext.seccompProfile}' 2>/dev/null
echo ""
echo ""

echo "=================================================================="
echo "  ✅ SOLUTION COMPLETE"
echo "=================================================================="
echo ""
echo "KEY POINTS:"
echo "  1. Seccomp profiles are stored at /var/lib/kubelet/seccomp/"
echo "  2. localhostProfile path is RELATIVE to /var/lib/kubelet/seccomp/"
echo "     So 'profiles/audit.json' → /var/lib/kubelet/seccomp/profiles/audit.json"
echo "  3. Three types: Unconfined, RuntimeDefault, Localhost"
echo "  4. Can be applied at pod level or container level"
echo "  5. Pod-level: spec.securityContext.seccompProfile"
echo "  6. Container-level: spec.containers[].securityContext.seccompProfile"
echo ""
echo "SECCOMP ACTIONS:"
echo "  - SCMP_ACT_ALLOW: Allow the syscall"
echo "  - SCMP_ACT_ERRNO: Block and return error"
echo "  - SCMP_ACT_LOG:   Allow but log (audit mode)"
echo "  - SCMP_ACT_KILL:  Kill the process"
