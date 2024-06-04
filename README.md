# `bootstrap-from-zero`

## Prerequisites

```
nix
libvirtd
qemu
virt-manager (optional to use a UI to interface with VMs)
```

## Setup air-gapped cluster

```bash
# prepare ISOs for VMs
just prepare
# spin up VM-based environment
tofu init
tofu apply
```

Wait for the VMs to be up...

Fetch IP from Talos machine when booted and install Talos:
```bash
mkdir -p talos
cd talos
talosctl gen config airgapped-cluster https://192.168.200.184:6443 \
  --with-secrets ./secrets.yaml \
  --install-disk /dev/sda \
  --install-image=ghcr.io/siderolabs/installer:v1.7.2 \
  --registry-mirror docker.io=http://192.168.200.2:5000 \
  --registry-mirror gcr.io=http://192.168.200.2:5000 \
  --registry-mirror ghcr.io=http://192.168.200.2:5000 \
  --registry-mirror registry.k8s.io=http://192.168.200.2:5000
talosctl apply-config --insecure -n 192.168.200.13 -e 192.168.200.13 --file controlplane.yaml
talosctl bootstrap -e 192.168.200.184 --talosconfig ./talosconfig  --nodes 192.168.200.184
talosctl kubeconfig -e 192.168.200.184 --talosconfig ./talosconfig  --nodes 192.168.200.184
```
