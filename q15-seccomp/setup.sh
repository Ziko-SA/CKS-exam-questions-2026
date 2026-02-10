#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q15: Seccomp Profile
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS PRACTICE Q15: SECCOMP PROFILE"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  You need to apply a Seccomp profile to restrict system calls"
echo "  made by a pod."
echo ""
echo "TASK:"
echo "  1. A custom Seccomp profile is provided at:"
echo "     /var/lib/kubelet/seccomp/profiles/audit.json"
echo "     (This profile logs all syscalls — used for auditing)"
echo ""
echo "  2. Create a pod named 'seccomp-pod' in namespace 'secure-ns' with:"
echo "     - Image: busybox:1.36"
echo "     - Command: sh -c 'echo Seccomp applied! && sleep 3600'"
echo "     - Apply the Seccomp profile using:"
echo "       securityContext.seccompProfile.type: Localhost"
echo "       securityContext.seccompProfile.localhostProfile:"
echo "         profiles/audit.json"
echo ""
echo "  3. Also create a pod named 'default-seccomp-pod' in 'secure-ns' with:"
echo "     - Image: busybox:1.36"
echo "     - Apply the RuntimeDefault Seccomp profile"
echo ""
echo "=================================================================="
echo "  Setting up environment..."
echo "=================================================================="

kubectl create namespace secure-ns --dry-run=client -o yaml | kubectl apply -f -

# Create the custom Seccomp profile directory and file
mkdir -p /var/lib/kubelet/seccomp/profiles

cat <<'EOF' > /var/lib/kubelet/seccomp/profiles/audit.json
{
    "defaultAction": "SCMP_ACT_LOG"
}
EOF

# Also create a more restrictive profile
cat <<'EOF' > /var/lib/kubelet/seccomp/profiles/restricted.json
{
    "defaultAction": "SCMP_ACT_ERRNO",
    "architectures": [
        "SCMP_ARCH_X86_64",
        "SCMP_ARCH_X86",
        "SCMP_ARCH_X32"
    ],
    "syscalls": [
        {
            "names": [
                "accept4", "access", "arch_prctl", "bind", "brk",
                "clone", "close", "connect", "dup2", "dup3",
                "epoll_create1", "epoll_ctl", "epoll_pwait", "execve",
                "exit", "exit_group", "fcntl", "fstat", "futex",
                "getdents64", "getpid", "getsockname", "getsockopt",
                "ioctl", "listen", "lseek", "mmap", "mprotect",
                "munmap", "nanosleep", "newfstatat", "open", "openat",
                "pipe2", "pread64", "read", "recvfrom", "recvmsg",
                "rt_sigaction", "rt_sigprocmask", "rt_sigreturn",
                "sched_yield", "sendmsg", "sendto", "set_tid_address",
                "setgid", "setgroups", "setuid", "sigaltstack",
                "socket", "tgkill", "uname", "wait4", "write",
                "writev"
            ],
            "action": "SCMP_ACT_ALLOW"
        }
    ]
}
EOF

echo ""
echo "✅ Environment ready!"
echo ""
echo "Seccomp profiles available at:"
echo "  /var/lib/kubelet/seccomp/profiles/audit.json"
echo "  /var/lib/kubelet/seccomp/profiles/restricted.json"
echo ""
echo "HINTS:"
echo "  - Pod-level seccomp: spec.securityContext.seccompProfile"
echo "  - Container-level: spec.containers[].securityContext.seccompProfile"
echo "  - type: Localhost + localhostProfile: profiles/<file>.json"
echo "  - type: RuntimeDefault for the default profile"
echo ""
echo "Run 'bash solution.sh' when ready to see the answer."
