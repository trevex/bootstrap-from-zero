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
  mode = "none"
  domain = "airgapped.local"

  dns {
    enabled = false
  }

  dhcp {
    enabled = false
  }
}

resource "libvirt_pool" "pool" {
  name = "airgapped-pool"
  type = "dir"
  path = "${path.root}/build/storage"
}

resource "libvirt_domain" "talos" {
  
}
