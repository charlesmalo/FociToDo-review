# Release readiness checklist

- [ ] `verify` passes from a clean clone of the release commit (arm64 locally; amd64 in CI)
- [ ] Test gate green with 100% coverage; e2e green
- [ ] All stress invariants hold; no 5xx under load
- [ ] No critical/high vulnerabilities without an accepted, documented reason
- [ ] Hadolint clean or findings accepted
- [ ] Traceability matrix: every requirement implemented and verified
- [ ] Findings log: no open High findings
- [ ] README quick start followed verbatim on a clean machine
