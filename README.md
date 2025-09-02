# EDCAAS Terraform Infrastructure

This project sets up the complete AWS infrastructure for the **EDCAAS** application using **Terraform**. It follows a modular design to manage resources like VPC, EKS, RDS, ALB, and OIDC separately. All infrastructure is defined as code and deployed securely, with remote state stored in an S3 bucket.

---

## 📦 Terraform Modules Used

- `vpc`
- `eks`
- `rds`
- `oidc`
- `alb`
- `add-ons`

---

## 🔍 Module Details

### 1. `vpc/` – Virtual Private Cloud
Creates a secure network layer:
- 3 Public Subnets (used for ALB)
- 3 Private Subnets (used for EKS nodes and RDS)
- Internet Gateway for public connectivity
- NAT Gateway for internet access from private subnets
- Public and private route tables for traffic routing

---

### 2. `eks/` – Elastic Kubernetes Service
Deploys a Kubernetes cluster inside private subnets:
- EKS Control Plane
- Managed Node Group
- Cluster IAM role and node IAM role
- Security groups
- Integrated with OIDC and ALB

---

### 3. `rds/` – Relational Database Service

Creates a secure PostgreSQL RDS instance for the backend application.

Key configurations:
- Hosted inside private subnets (no public access)
- Attached to a DB Subnet Group spanning multiple Availability Zones
- Security groups restrict access only to required resources (e.g., EKS)
- Credentials (username and password) are **not hardcoded** — instead:
  - Fetched from an existing AWS Secrets Manager secret named: `dev-rds-db-secrets`

> 🔐 This approach avoids storing database credentials in Terraform code or state files, enhancing overall security posture.


### 3. `rds/` – Relational Database Service
Creates a PostgreSQL RDS instance:
- Hosted inside private subnets
- Attached to a DB Subnet Group
- Not publicly accessible
- Designed for high availability and security

---

### 4. `oidc/` – OpenID Connect Provider
Enables IAM roles for Kubernetes service accounts (IRSA):
- Sets up OIDC identity provider for EKS
- Required for secure AWS service access by pods (e.g. ALB Controller, external-dns)

---

### 5. `alb/` – Application Load Balancer Controller
Sets up ALB Ingress Controller:
- Creates IAM role with required policy
- Enables EKS services to be exposed via HTTP/HTTPS through ALB
- Supports Kubernetes Ingress resources

---

### 6. `add-ons/` – EKS Managed Add-ons

This module installs a set of **AWS-managed EKS add-ons** using Terraform. These add-ons are critical components for networking, storage, and identity in an EKS cluster.

The following add-ons are installed by default:

| Add-on Name              | Version                  | Description                              |
|--------------------------|--------------------------|------------------------------------------|
| `vpc-cni`                | `v1.19.5-eksbuild.1`     | Networking for EKS pods                  |
| `coredns`                | `v1.11.4-eksbuild.2`     | DNS service inside the cluster           |
| `kube-proxy`             | `v1.32.3-eksbuild.7`     | Network proxy for Kubernetes services    |
| `aws-ebs-csi-driver`     | `v1.39.0-eksbuild.1`     | CSI driver for EBS volume provisioning   |
| `aws-efs-csi-driver`     | `v2.1.6-eksbuild.1`      | CSI driver for EFS file system mounts    |
| `eks-pod-identity-agent` | `v1.3.5-eksbuild.2`      | Enables IAM Roles for Service Accounts   |


---

## 📁 Project Structure
```
edcaas-terraform-infra/
├── backend.tf # S3 backend config for remote state
├── main.tf # Root module to call all child modules
├── provider.tf # AWS provider and authentication setup
├── variables.tf # Input variable definitions
├── terraform.tfvars # Values for variables
├── modules/
│ ├── vpc/ # VPC configuration
│ ├── eks/ # EKS cluster setup
│ ├── rds/ # PostgreSQL database
│ ├── oidc/ # OIDC provider setup
│ ├── alb/ # ALB Ingress Controller setup
│ └── add-ons/ # Optional EKS add-ons
```

---

## 🚀 Terraform Deployment Steps

Follow the steps below to deploy the infrastructure:

### 1️⃣ Initialize the backend and modules
```bash
terraform init
```
### 2️⃣ Validate the configuration
```bash
terraform validate
```
### 3️⃣ Review the planned changes
```bash
terraform plan
```
### 4️⃣ Apply the infrastructure
```bash
terraform apply
```
### 5️⃣ (Optional) Destroy the infrastructure
```bash
terraform destroy
```

---

## ✅ Conclusion

This project delivers a clean and modular AWS infrastructure setup for EDCAAS using Terraform. It’s built for reliability, security, and easy maintenance—ready to support production workloads.
