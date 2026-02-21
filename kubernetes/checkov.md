---

# 🚀 Securing Kubernetes Pods with Checkov

This guide provides a quick start for using Checkov to ensure your Kubernetes Pods comply with the CIS (Center for Internet Security) Kubernetes Benchmark.

## What is Checkov?

Checkov is a static code analysis tool for Infrastructure as Code (IaC). It scans your Kubernetes YAML files before you deploy them to identify security misconfigurations and compliance violations.

---

## 1. Installation

Choose the method that best fits your environment:

```bash
# Using Python (pip):
pip install checkov
```

```zsh
# Using Homebrew (macOS/Linux):
brew install checkov
```

```sh
# Using Docker:
docker pull bridgecrew/checkov
```

## 2. Basic Usage

To scan your Kubernetes manifests, navigate to your project folder and run:

```bash
# Scan a specific directory
checkov -d ./k8s-manifests

# Scan a specific file
checkov -f pod.yaml
```

## 3. CIS Compliance for Pods

Checkov automatically maps its checks to the CIS Kubernetes Benchmark. When a scan runs, it looks for common vulnerabilities in your Pod specifications, such as:

| Check ID   | Security Requirement | Why it matters                                                     |
| ---------- | -------------------- | ------------------------------------------------------------------ |
| CKV_K8S_16 | privileged: false    | Prevents container escapes to the host system.                     |
| CKV_K8S_40 | runAsNonRoot: true   | Ensures the container does not run with root privileges.           |
| CKV_K8S_37 | capabilities: drop:  | ["ALL"] Minimizes the kernel functions available to the container. |
| CKV_K8S_11 | cpu/memory limits    | Prevents Resource Exhaustion (DoS) attacks.                        |

## 4. Filtering scans

```bash
# Only run Kubernetes-related checks
checkov -d . --framework kubernetes

# Fail the scan only on specific high-severity checks
checkov -d . --check CKV_K8S_16,CKV_K8S_40
```
