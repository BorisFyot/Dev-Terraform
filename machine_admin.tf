resource "google_compute_instance" "admin-instance" {
  name         = "admin-instance"
  machine_type = "n1-standard-1"
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
    network_ip    = "10.5.0.10"
    access_config = {
    }
  }
  metadata_startup_script = "sudo yum -y install epel-release nginx git python-pip; pip install ansible; git clone https://github.com/BorisFyot/devops2019-FYOT_Boris.git; sudo systemctl start nginx.service; sudo systemctl enable nginx.service"
}
