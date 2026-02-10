#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — MASTER RUNNER
# ============================================================================
# Usage:
#   bash run.sh           — List all questions
#   bash run.sh 1         — Setup question 1
#   bash run.sh 1 solve   — Show solution for question 1
#   bash run.sh all       — Setup all questions at once
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

QUESTIONS=(
  "q01-falco|Falco — Runtime Security (scale down /dev/mem pods)"
  "q02-istio-mtls|Istio — mTLS & Sidecar Injection"
  "q03-ingress-tls|Ingress with TLS (HTTP→HTTPS redirect)"
  "q04-docker-daemon|Docker Daemon Security (user, socket, unix)"
  "q05-bom-sbom|BOM/SBOM Analysis (libcrypto3 + SPDX report)"
  "q06-static-analysis|Static File Analysis (Dockerfile + deploy fix)"
  "q07-secret-tls|Secret TLS (create + mount in deployment)"
  "q08-projected-volume|Projected Volume & ServiceAccount Token"
  "q09-kube-bench|Kube-bench — Fix 3 CIS Issues (--profiling)"
  "q10-auditing|Kubernetes Auditing (policy + apiserver config)"
  "q11-image-policy-webhook|ImagePolicyWebhook Admission Controller"
  "q12-network-policies|Network Policies (deny-all + allow specific)"
  "q13-pss-fix|Pod Security Standards — Fix Deployment"
  "q14-apiserver-anonymous|Kube-apiserver Anonymous Auth Hardening"
  "q15-seccomp|Seccomp Profile (Localhost + RuntimeDefault)"
  "q16-upgrade-worker|Upgrade Worker Node (1.33.0 → 1.33.1)"
)

print_banner() {
  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║          CKS 2025 EXAM PRACTICE — 16 QUESTIONS             ║"
  echo "║          For KillerCoda / kubeadm clusters                 ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo ""
}

list_questions() {
  print_banner
  echo "  #  │ Topic"
  echo "─────┼──────────────────────────────────────────────────────────"
  for i in "${!QUESTIONS[@]}"; do
    IFS='|' read -r dir desc <<< "${QUESTIONS[$i]}"
    num=$((i + 1))
    printf "  %02d │ %s\n" "$num" "$desc"
  done
  echo ""
  echo "Usage:"
  echo "  bash run.sh <number>         — Setup a question"
  echo "  bash run.sh <number> solve   — Show the solution"
  echo "  bash run.sh all              — Setup all questions"
  echo ""
}

run_question() {
  local num=$1
  local mode=$2
  local idx=$((num - 1))

  if [ $idx -lt 0 ] || [ $idx -ge ${#QUESTIONS[@]} ]; then
    echo "❌ Invalid question number: $num (valid: 1-${#QUESTIONS[@]})"
    exit 1
  fi

  IFS='|' read -r dir desc <<< "${QUESTIONS[$idx]}"

  if [ "$mode" = "solve" ] || [ "$mode" = "solution" ]; then
    if [ -f "${SCRIPT_DIR}/${dir}/solution.sh" ]; then
      bash "${SCRIPT_DIR}/${dir}/solution.sh"
    else
      echo "❌ Solution not found: ${dir}/solution.sh"
    fi
  else
    if [ -f "${SCRIPT_DIR}/${dir}/setup.sh" ]; then
      bash "${SCRIPT_DIR}/${dir}/setup.sh"
    else
      echo "❌ Setup not found: ${dir}/setup.sh"
    fi
  fi
}

# Main logic
case "${1}" in
  ""|"list"|"help"|"-h"|"--help")
    list_questions
    ;;
  "all")
    print_banner
    echo "⚠ Setting up ALL questions... This may take a while."
    echo ""
    for i in "${!QUESTIONS[@]}"; do
      num=$((i + 1))
      IFS='|' read -r dir desc <<< "${QUESTIONS[$i]}"
      echo "━━━ Setting up Q${num}: ${desc} ━━━"
      bash "${SCRIPT_DIR}/${dir}/setup.sh"
      echo ""
    done
    echo "✅ All questions set up!"
    ;;
  *)
    if [[ "$1" =~ ^[0-9]+$ ]]; then
      run_question "$1" "$2"
    else
      echo "❌ Unknown command: $1"
      list_questions
    fi
    ;;
esac
