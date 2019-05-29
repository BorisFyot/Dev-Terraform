provider "google" {
  credentials = "${file("united-lane-241907-c7fa43cedef5.json")}"
  project     = "${var.project}"
  region      = "${var.region}"
}

resource "google_compute_firewall" "admin" {
  name    = "admin-firewall"
  network = "${google_compute_network.my-network.name}"

  allow {
    protocol = "tcp"
    ports    = ["8080", "22", "80"]
  }
  target_tags = ["admin"]
}


resource "google_compute_firewall" "nexus" {
  name    = "nexus-firewall"
  network = "${google_compute_network.my-network.name}"

  allow {
    protocol = "tcp"
    ports    = ["8081","22"]
  }
  target_tags = ["nexus"]
}


resource "google_compute_firewall" "jenkins" {
  name    = "jenkinss-firewall"
  network = "${google_compute_network.my-network.name}"

  allow {
    protocol = "tcp"
    ports    = ["8080","22"]
  }
  target_tags = ["jenkins"]
}


resource "google_compute_router" "vpc-router" {
  name    = "${google_compute_network.my-network.name}-router"
  region  = "${var.region}"
  network = "${google_compute_network.my-network.self_link}"
  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "vpc-nat" {
  name                               = "${google_compute_network.my-network.name}-nat"
  router                             = "${google_compute_router.vpc-router.name}"
  region                             = "${var.region}"
  nat_ip_allocate_option             = "AUTO_ONLY"
  //nat_ips                            = ["${google_compute_address.vpc-address.self_link}"]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
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

resource "google_compute_subnetwork" "jenkins" {
  name          = "jenkins-subnetwork"
  ip_cidr_range = "10.9.0.0/21"
  region        = "${var.region}"
  network       = "${google_compute_network.my-network.self_link}"
}

resource "google_compute_subnetwork" "maven" {
  name          = "maven-subnetwork"
  ip_cidr_range = "10.10.0.0/21"
  region        = "${var.region}"
  network       = "${google_compute_network.my-network.self_link}"
}

resource "google_compute_subnetwork" "nexus" {
  name          = "nexus-subnetwork"
  ip_cidr_range = "10.11.0.0/21"
  region        = "${var.region}"
  network       = "${google_compute_network.my-network.self_link}"
}

resource "google_compute_network" "my-network" {
  provider = "google"
  name = "projectfinal"
  auto_create_subnetworks = "false"
}


