#!/bin/bash

# ============================================================================
# CKS EXAM REAL QUESTION — Q15: Seccomp Profile Application
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS REAL Q15: SECCOMP PROFILE APPLICATION"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  A custom Seccomp profile is available at /var/lib/kubelet/seccomp/profiles/audit.json (logs all syscalls for auditing)."
echo ""
echo "TASK:"
echo "  - Create a pod named 'seccomp-pod' in namespace 'secure-ns' using busybox:1.36, running 'sh -c \"echo Seccomp applied! && sleep 3600\"', and apply the custom Seccomp profile using securityContext.seccompProfile.type: Localhost and securityContext.seccompProfile.localhostProfile: profiles/audit.json."
echo "  - Create a pod named 'default-seccomp-pod' in 'secure-ns' using busybox:1.36 and apply the RuntimeDefault Seccomp profile."
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
echo "Run 'bash verify.sh' after solving to check your answer."
