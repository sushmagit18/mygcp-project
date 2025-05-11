## Cloud DNS - Creating a DNS Managed Zone
resource "google_dns_managed_zone" "web_zone" {
  name        = "web-zone"
  dns_name    = "mygcp-exampleproject.com."
  description = "Managed zone for my web project."
}

# Global IP Address for Load Balancer
resource "google_compute_global_address" "web_ip" {
  name = "web-ip"
}

# Instance Template for backend instances
resource "google_compute_instance_template" "web_template" {
  name         = "web-template"
  machine_type = "f1-micro"

  tags = ["apache-server"]

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y apache2
    echo "Hello from Web Terraform" > /var/www/html/index.html
    sudo systemctl start apache2
  EOT
}

# Managed Instance Group
resource "google_compute_instance_group_manager" "web_igm" {
  name               = "web-igm"
  base_instance_name = "web"
  zone               = var.zone

  version {
    instance_template = google_compute_instance_template.web_template.self_link
  }

  target_size = 1

  named_port {
    name = "http"
    port = 80
  }
}

# Backend Service with MIG
resource "google_compute_backend_service" "web_backend_service" {
  name     = "web-backend-service"
  protocol = "HTTP"

  backend {
    group = google_compute_instance_group_manager.web_igm.instance_group
  }

  health_checks = [google_compute_http_health_check.web_health_check.self_link]
}

# Cloud Load Balancer - HTTP Health Check
resource "google_compute_http_health_check" "web_health_check" {
  name                = "web-health-check"
  request_path        = "/"
  port                = 80
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

# URL Map for HTTP Load Balancer
resource "google_compute_url_map" "web_url_map" {
  name            = "web-url-map"
  default_service = google_compute_backend_service.web_backend_service.self_link
}

# Target HTTP Proxy
resource "google_compute_target_http_proxy" "web_http_proxy" {
  name    = "web-http-proxy"
  url_map = google_compute_url_map.web_url_map.self_link
}

# Global Forwarding Rule
resource "google_compute_global_forwarding_rule" "web_forwarding_rule" {
  name        = "web-forwarding-rule"
  target      = google_compute_target_http_proxy.web_http_proxy.self_link
  port_range  = "80"
  ip_address  = google_compute_global_address.web_ip.address
  ip_protocol = "TCP"
}
# Create a Cloud DNS A Record
resource "google_dns_record_set" "web_a_record" {
  name         = "web.mygcp-exampleproject.com."  # Optional: use subdomain
  managed_zone = google_dns_managed_zone.web_zone.name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.web_ip.address]
}
# App DNS Managed Zone (optional if same as web)
resource "google_dns_managed_zone" "app_zone" {
  name        = "app-zone"
  dns_name    = "mygcp-appproject.com."
  description = "Managed zone for app project."
}

# Global IP for App Load Balancer
resource "google_compute_global_address" "app_ip" {
  name = "app-ip"
}

# App Instance Template
resource "google_compute_instance_template" "app_template" {
  name         = "app-template"
  machine_type = "f1-micro"

  tags = ["app-server"]

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y apache2
    echo "Hello from APP Terraform" > /var/www/html/index.html
    sudo systemctl enable apache2
    sudo systemctl start apache2
  EOT
}

# App Instance Group Manager
resource "google_compute_instance_group_manager" "app_mig" {
  name               = "app-mig"
  base_instance_name = "app"
  zone               = var.zone

  version {
    instance_template = google_compute_instance_template.app_template.self_link
  }

  target_size = 1

  named_port {
    name = "http"
    port = 80
  }
}

# App Health Check
resource "google_compute_http_health_check" "app_health_check" {
  name                = "app-health-check"
  request_path        = "/"
  port                = 80
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

# App Backend Service
resource "google_compute_backend_service" "app_backend_service" {
  name     = "app-backend-service"
  protocol = "HTTP"

  backend {
    group = google_compute_instance_group_manager.app_mig.instance_group
  }

  health_checks = [google_compute_http_health_check.app_health_check.self_link]
}

# App URL Map
resource "google_compute_url_map" "app_url_map" {
  name            = "app-url-map"
  default_service = google_compute_backend_service.app_backend_service.self_link
}

# App HTTP Proxy
resource "google_compute_target_http_proxy" "app_http_proxy" {
  name    = "app-http-proxy"
  url_map = google_compute_url_map.app_url_map.self_link
}

# App Forwarding Rule
resource "google_compute_global_forwarding_rule" "app_forwarding_rule" {
  name        = "app-forwarding-rule"
  target      = google_compute_target_http_proxy.app_http_proxy.self_link
  port_range  = "80"
  ip_address  = google_compute_global_address.app_ip.address
  ip_protocol = "TCP"
}

resource "google_dns_record_set" "app_a_record" {
  name         = "app.${var.app_dns_name}."  # <-- now using variable
  managed_zone = google_dns_managed_zone.app_zone.name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.app_ip.address]
}


# Cloud SQL Instance
resource "google_sql_database_instance" "db" {
  name             = var.db_instance_name
  database_version = var.db_version
  region           = var.region

  deletion_protection = false

  settings {
    tier = var.db_tier
  }
}

resource "google_sql_user" "db_user" {
  instance = google_sql_database_instance.db.name
  name     = var.db_user
  password = var.db_password
  host     = "%"
}








