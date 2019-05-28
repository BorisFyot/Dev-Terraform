resource "google_compute_instance" "admin-instance" {
  name         = "admin-instance"
  machine_type = "f1-micro"
  zone         = "${var.zone}"

  tags = ["admin"]

  boot_disk {
    initialize_params {
      image = "centos-7"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network       = "${google_compute_network.my-network.name}"
    subnetwork    = "${google_compute_subnetwork.admin.name}"

    access_config = {
    }
  }
}
