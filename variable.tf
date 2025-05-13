variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default = "metroc-project-456121"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default = "us-central1"
}

variable "zone" {
  description = "The zone in which the instance group and compute instances should be created."
  type        = string
  default = "us-central1-a"
}

# variable "db_instance" {
#   type    = string
#   default = "db-instance"
# }


variable "db_version" {
  type    = string
  default = "MYSQL_8_0"
}

variable "db_tier" {
  type    = string
  default = "db-f1-micro"
}

variable "db_name" {
  type    = string
  default = "projectdb"
}

variable "db_user" {
  type    = string
  default = "projectuser"
}

variable "db_password" {
  description = "Database user password"
  type        = string
  sensitive   = true
}

variable "db_region" {
  type    = string
  default = "us-central1"
}
variable "db_instance_name" {
  description = "The name of the database instance"
  type        = string
  default = "my-db-instance"
}
variable "app_dns_name" {
  description = "App DNS name"
  type        = string
}
data "google_compute_network" "default" {
  name = "default"
}


