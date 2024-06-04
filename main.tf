terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_network" "network" {
  name = "airgapped-net"
  mode = "open"
  domain = "airgapped.local"
  addresses = ["192.168.200.0/24"]

  dns {
    enabled = false
  }

  dhcp {
    enabled = false
  }
}

locals {
  build_dir = "${abspath(path.root)}/build"
  ddinode_dir = "${abspath(path.root)}/ddinode"
}

resource "libvirt_pool" "pool" {
  name = "airgapped-data"
  type = "dir"
  path = "${local.build_dir}/storage"
}

resource "libvirt_volume" "talos" {
  name  = "talos1-vol"
  size  = 10 * 1024 * 1024 * 1024 # 10 GB
  pool  = libvirt_pool.pool.name
}

resource "libvirt_domain" "talos" {
  name        = "talos1"
  memory      = 4096
  vcpu        = 2

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_name   = libvirt_network.network.name
    wait_for_lease = false
  }

  disk {
    file = "${local.build_dir}/talos-amd64.iso"
  }

  disk {
    volume_id = libvirt_volume.talos.id
    scsi      = "true"
  }

  boot_device {
    dev = ["hd", "cdrom"]
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  tpm {
    backend_type    = "emulator"
    backend_version = "2.0"
  }
}

resource "libvirt_volume" "ddinode" {
  name  = "ddinode-vol"
  size  = 20 * 1024 * 1024 * 1024 # 1 GB
  pool  = libvirt_pool.pool.name
}

resource "libvirt_domain" "ddinode" {
  name        = "ddinode"
  memory      = 8192
  vcpu        = 2

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_name   = libvirt_network.network.name
    wait_for_lease = false
  }

  disk {
    file = "${local.ddinode_dir}/result/iso/nixos.iso"
  }

  disk {
    volume_id = libvirt_volume.ddinode.id
    scsi      = "true"
  }

  boot_device {
    dev = ["cdrom"]
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  tpm {
    backend_type    = "emulator"
    backend_version = "2.0"
  }
}
