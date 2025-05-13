output "web_global_ip" {
  description = "Web Global IP Address"
  value       = google_compute_global_address.web_ip.address
}

output "web_url" {
  description = "Web Application URL"
  value       = "http://${google_dns_record_set.web_a_record.name}"
}

output "web_load_balancer_url" {
  description = "Web Load Balancer External IP"
  value       = "http://${google_compute_global_address.web_ip.address}"
}

output "web_backend_service" {
  description = "Web Backend Service Name"
  value       = google_compute_backend_service.web_backend_service.name
}

output "web_instance_group_manager" {
  description = "Web Instance Group Manager Name"
  value       = google_compute_instance_group_manager.web_mig.name
}

output "app_global_ip" {
  description = "App Global IP Address"
  value       = google_compute_global_address.app_ip.address
}

output "app_url" {
  description = "App Application URL"
  value       = "http://${google_dns_record_set.app_a_record.name}"
}

output "app_load_balancer_url" {
  description = "App Load Balancer External IP"
  value       = "http://${google_compute_global_address.app_ip.address}"
}

output "app_backend_service" {
  description = "App Backend Service Name"
  value       = google_compute_backend_service.app_backend_service.name
}

output "app_instance_group_manager" {
  description = "App Instance Group Manager Name"
  value       = google_compute_instance_group_manager.app_mig.name
}

output "dns_zone_web" {
  description = "Web DNS Managed Zone"
  value       = google_dns_managed_zone.web_zone.name
}

output "dns_zone_app" {
  description = "App DNS Managed Zone"
  value       = google_dns_managed_zone.app_zone.name
}
output "connection_name" {
  value = google_sql_database_instance.db.connection_name
}

output "db_connection_string" {
  description = "MYSQL_8_0 connection string without password"
  value       = "MYSQL_8_0://${google_sql_user.db_user.name}@${google_sql_database_instance.db.ip_address[0].ip_address}:3306/${var.db_name}"
}


output "db_instance_ip" {
  description = "The public IP address of the database instance"
  value       = google_sql_database_instance.db.ip_address[0].ip_address
}
