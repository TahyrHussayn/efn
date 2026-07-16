# ─────────────────────────────────────────────────────────────────────────────
# Remote state — S3 backend with native locking (Terraform 1.10+)
# ─────────────────────────────────────────────────────────────────────────────
# Before enabling this backend, create the S3 bucket:
#   aws s3api create-bucket --bucket efn-terraform-state --region us-east-1
#   aws s3api put-bucket-versioning --bucket efn-terraform-state \
#     --versioning-configuration Status=Enabled
#
# Then uncomment the backend block below and run:
#   terraform init -migrate-state
# ─────────────────────────────────────────────────────────────────────────────
terraform {
  backend "s3" {
    bucket       = "efn-terraform-state"
    key          = "efn/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
