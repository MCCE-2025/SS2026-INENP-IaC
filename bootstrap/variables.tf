variable "project_id" {
  description = "Google Cloud project ID (supply via TF_VAR_project_id, e.g. export TF_VAR_project_id=$(gcloud config get-value project))"
  type        = string
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