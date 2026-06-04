variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
  default     = "sonorous-stone-498307-u2"
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