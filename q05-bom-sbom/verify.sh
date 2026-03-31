#!/bin/bash
# ============================================================================
# CKS Q05: BOM/SBOM — Verify Solution
# ============================================================================

PASS=0; FAIL=0
check() {
  if eval "$2" &>/dev/null; then
    echo "✅ PASS: $1"; ((PASS++))
  else
    echo "❌ FAIL: $1"; ((FAIL++))
  fi
}

echo "=================================================================="
echo "  VERIFYING Q05: BOM/SBOM — SUPPLY CHAIN SECURITY"
echo "=================================================================="
echo ""

# Check the vulnerable container (alpine:3.16.1 / container-c) was removed
CONTAINERS=$(kubectl get deploy alpine-multi -n apps -o jsonpath="{.spec.template.spec.containers[*].name}" 2>/dev/null)

check "container-c (vulnerable alpine:3.16.1) is removed from deployment" \
  'echo "$CONTAINERS" | grep -v -q "container-c"'

check "container-a still exists in deployment" \
  'echo "$CONTAINERS" | grep -q "container-a"'

check "container-b still exists in deployment" \
  'echo "$CONTAINERS" | grep -q "container-b"'

# Check deployment still works
check "alpine-multi deployment is available" \
  'kubectl get deploy alpine-multi -n apps -o jsonpath="{.status.availableReplicas}" 2>/dev/null | grep -q "[1-9]"'

# Check SBOM report exists
check "SBOM report exists at /root/sbom-report.spdx" \
  '[ -f /root/sbom-report.spdx ]'

check "SBOM report is not empty" \
  '[ -s /root/sbom-report.spdx ]'

# Check SBOM report contains SPDX content
check "SBOM report contains SPDX format data" \
  'grep -qi "spdx\|SPDXRef\|DocumentNamespace" /root/sbom-report.spdx 2>/dev/null'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All checks passed!" || exit 1
