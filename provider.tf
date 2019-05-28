provider "google" {
  credentials = "${file("united-lane-241907-c7fa43cedef5.json")}"
  project     = "${var.project}"
  region      = "${var.region}"
}

resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = "${google_compute_network.my-network.name}"

  allow {
    protocol = "tcp"
    ports    = ["8080", "22"]
  }
  target_tags = ["admin"]
}

resource "google_compute_project_metadata_item" "ssh-keys" {
  key   = "ssh-keys"
  value = "${var.ssh_user}:${var.public_key}"
}

resource "google_compute_subnetwork" "admin" {
  name          = "admin-subnetwork"
  ip_cidr_range = "10.5.0.0/21"
  region        = "${var.region}"
  network       = "${google_compute_network.my-network.self_link}"
}

resource "google_compute_subnetwork" "kube" {
  name          = "kube-subnetwork-pod"
  ip_cidr_range = "10.6.0.0/21"
  region        = "${var.region}"
  network       = "${google_compute_network.my-network.self_link}"
  secondary_ip_range {
    range_name    = "kube-subnetwork-node"
    ip_cidr_range = "10.7.0.0/21"
  }
  secondary_ip_range {
    range_name    = "kube-subnetwork-service"
    ip_cidr_range = "10.8.0.0/21"
  }
}

resource "google_compute_network" "my-network" {
  provider = "google"
  name = "myproject"
  auto_create_subnetworks = "false"
}


