variable "hcloud_api_token" {
  sensitive = true
  type = string
}

variable "domain" {
  description = "Domain like signal.crazybanana.link"
  type = string
}