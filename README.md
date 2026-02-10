# CKS Exam Practice Scripts for KillerCoda

## 16 Questions covering the CKS 2025 exam

Each question folder contains:
- `setup.sh` — Run first. Sets up the environment and prints the question.
- `solution.sh` — Run after attempting. Shows the solution step-by-step.
- Supporting files (YAML, configs, Dockerfiles) as needed.

## Questions

| # | Topic | Domain |
|---|-------|--------|
| 01 | Falco — Runtime Security | Runtime Security |
| 02 | Istio — mTLS & Sidecar | Service Mesh Security |
| 03 | Ingress with TLS | Network Security |
| 04 | Docker Daemon Security | Node Security |
| 05 | BOM/SBOM Analysis | Supply Chain Security |
| 06 | Static File Analysis | Static Analysis |
| 07 | Secret TLS | Secrets Management |
| 08 | Projected Volume & ServiceAccount | Access Control |
| 09 | Kube-bench — Fix CIS Issues | Cluster Hardening |
| 10 | Auditing | Audit Logging |
| 11 | ImagePolicyWebhook | Admission Control |
| 12 | Network Policies | Network Security |
| 13 | PSS — Fix Deployment | Pod Security Standards |
| 14 | Kube-apiserver Anonymous Auth | API Server Hardening |
| 15 | Seccomp Profile | Runtime Security |
| 16 | Upgrade Worker Node | Cluster Maintenance |

## How to Use on KillerCoda

1. Open a KillerCoda Kubernetes playground (1 control-plane + 1 worker)
2. Clone or copy this folder
3. For each question:
   ```bash
   cd cks-practice/q01-falco
   chmod +x setup.sh solution.sh
   bash setup.sh       # Sets up the scenario
   # ... attempt the question ...
   bash solution.sh    # Reveals the solution
   ```

## Pre-requisites
- KillerCoda Kubernetes environment (or any kubeadm cluster)
- kubectl configured
- Root/sudo access on nodes
