{ inputs, lib, pkgs, config,  ... }:
{
  networking.firewall.enable = false;

  networking.interfaces.ens3.ipv4.addresses = [ {
    address = "192.168.200.2";
    prefixLength = 24;
  }];

  networking.nameservers = [ "127.0.0.1" ];
  networking.extraHosts =
  ''
    127.0.0.1 0.nixos.pool.ntp.org
    127.0.0.1 1.nixos.pool.ntp.org
    127.0.0.1 2.nixos.pool.ntp.org
    127.0.0.1 3.nixos.pool.ntp.org
    192.168.200.2 time.cloudflare.com
    # 192.168.200.2 docker.io
    # 192.168.200.2 gcr.io
    # 192.168.200.2 ghcr.io
    # 192.168.200.2 registry.k8s.io
  ''; # talos install failes due to dns issues...

  services.chrony.enable = true;
  services.chrony.serverOption = "offline";
  services.chrony.extraConfig = ''
    allow 192.168.200.0/24
  '';

  services.dnsmasq.enable = true;
  services.dnsmasq.alwaysKeepRunning = true;
  services.dnsmasq.settings = {
    log-dhcp = true;
    log-queries = true;
    log-debug = true;
    log-facility = "/var/log/dnsmasq.log";

    no-resolv = true;
    dhcp-authoritative = true;
    interface = "ens3";
    dhcp-range = [ "192.168.200.3,192.168.200.254,255.255.255.0,24h" ];
    dhcp-option = [
      "3,192.168.200.2" # Gateway
      # "6,192.168.200.2" # DNS servers
      "option:ntp-server,192.168.200.2"
      # "option:dns-server,192.168.200.2"
    ];
  };
}
