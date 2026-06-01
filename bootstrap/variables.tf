variable "project_id" { type = string }

variable "state_bucket_prefix" {
  type        = string
  description = "Prefix for the Terraform state bucket; a random suffix is appended for global uniqueness."
  default     = "terraform-state-ss2026"
}
variable "region" {
  type    = string
  default = "europe-west3"
}
variable "terraform_state_users" {
  type = list(string)
  default = [
    "2510781028@hochschule-burgenland.at",
    "2510781033@hochschule-burgenland.at",
    "2510781034@hochschule-burgenland.at",
  ]
}