## Cloud DNS - Creating a DNS Managed Zone
resource "google_dns_managed_zone" "web_zone" {
  name        = "web-zone"
  dns_name    = "mygcp-exampleproject.com."
  description = "Managed zone for my web."
}

# Global IP Address for Load Balancer
resource "google_compute_global_address" "web_ip" {
  name = "web-ip"
}

# Instance Template for backend instances
resource "google_compute_instance_template" "web_template" {
  name         = "web-template"
  machine_type = "e2-micro"

  tags = ["web-server"]

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = data.google_compute_network.default.self_link
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt update
    apt install -y apache2
    echo "Welcome to Web Terraform" > /var/www/html/index.html
    systemctl start apache2
    systemctl enable apache2
  EOT
}
resource "google_compute_firewall" "allow_http_web" {
  name    = "allow-http-web"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}


# Managed Instance Group
resource "google_compute_instance_group_manager" "web_mig" {
  name               = "web-mig"
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
  port_name = "http"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group_manager.web_mig.instance_group
  }

  health_checks = [google_compute_http_health_check.web_health_check.id]
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
  default_service = google_compute_backend_service.web_backend_service.id
}

# Target HTTP Proxy
resource "google_compute_target_http_proxy" "web_http_proxy" {
  name    = "web-http-proxy"
  url_map = google_compute_url_map.web_url_map.id
}

# Global Forwarding Rule
resource "google_compute_global_forwarding_rule" "web_forwarding_rule" {
  name        = "web-forwarding-rule"
  target      = google_compute_target_http_proxy.web_http_proxy.id
  port_range  = "80"
  ip_address  = google_compute_global_address.web_ip.address
  ip_protocol = "TCP"
}


# A Record for web
resource "google_dns_record_set" "web_a_record" {
  name         = "web.mygcp-exampleproject.com."  # Fully qualified domain name (FQDN)
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.web_zone.name
  rrdatas      = [google_compute_global_address.web_ip.address]
}

# Global IP for App Load Balancer
resource "google_compute_global_address" "app_ip" {
  name = "app-ip"
}
###############################################
# App DNS Managed Zone
resource "google_dns_managed_zone" "app_zone" {
  name        = "app-zone"
  dns_name    = "mygcp-appproject.com."  # mygcp-appproject.com.
  description = "Managed zone for app."
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
    network = data.google_compute_network.default.self_link
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

## Firewall Rules
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server", "app-server"]
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

# DATA BLOCK: Lookup the managed instance group
data "google_compute_instance_group" "app_instance_group" {
  name = google_compute_instance_group_manager.app_mig.name
  zone = var.zone
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
  timeout_sec = 10

  backend {
    group = google_compute_instance_group_manager.app_mig.instance_group
  }

  health_checks = [google_compute_http_health_check.app_health_check.id]
}

# App URL Map
resource "google_compute_url_map" "app_url_map" {
  name            = "app-url-map"
  default_service = google_compute_backend_service.app_backend_service.id
}

# App HTTP Proxy
resource "google_compute_target_http_proxy" "app_http_proxy" {
  name    = "app-http-proxy"
  url_map = google_compute_url_map.app_url_map.id
}

# App Forwarding Rule
resource "google_compute_global_forwarding_rule" "app_forwarding_rule" {
  name        = "app-forwarding-rule"
  target      = google_compute_target_http_proxy.app_http_proxy.id
  port_range  = "80"
  ip_address  = google_compute_global_address.app_ip.address
  ip_protocol = "TCP"
}



## App DNS Record
resource "google_dns_record_set" "app_a_record" {
  name         = "app.mygcp-appproject.com."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.app_zone.name
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

    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        name  = "allow-all"
        value = "0.0.0.0/0"
      }
    }
  }
}


# Create the database
resource "google_sql_database" "database" {
  name     = var.db_name
  instance = google_sql_database_instance.db.name
}

# Create the DB user
resource "google_sql_user" "db_user" {
  instance = google_sql_database_instance.db.name
  name     = var.db_user
  password = var.db_password
  host     = "%"  # Allows connection from any host
}








