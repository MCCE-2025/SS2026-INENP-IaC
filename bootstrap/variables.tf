variable "project_id" { type = string }
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