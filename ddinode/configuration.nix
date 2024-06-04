{ inputs, lib, pkgs, config,  ... }:
{
  users.users.test = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/test";
    extraGroups = [ "wheel" "networkmanager" "input" "video" "dialout" "docker" ];
    hashedPassword = "$7$CU..../....darl3WJb9VjRQQ/4Z9sEj.$YFZjb2Cy7ODMLvfcvSm0TF1GbOWgrxf8dQtAHrEfXU8";
  };
  services.getty.autologinUser = "test";
  security.sudo.extraRules= [{
      users = [ "test" ];
      commands = [{
        command = "ALL" ;
        options= [ "NOPASSWD" ];
      }];
  }];

  services.dockerRegistry = {
    enable = true;
    listenAddress = "0.0.0.0";
  };
  virtualisation.docker.enable = true;

  systemd.services.docker-load = let
    images = with pkgs.images; [ # add all the images to preload
      busybox
      sidero-flannel
      sidero-install-cni
      coredns
      etcd
      kube-apiserver
      kube-controller-manager
      kube-scheduler
      kube-proxy
      sidero-kubelet
      sidero-installer
      kube-pause
    ];
    mkScript = image:
    let
      docker = "${pkgs.docker}/bin/docker";
      sed = "${pkgs.gnused}/bin/sed";
      filename = "${image.name}-${image.version}";
      port = builtins.toString config.services.dockerRegistry.port;
    in ''
      export IMAGE="$(cat ${image}/${filename}.txt)"
      export IMAGE_MIRROR="$(cat ${image}/${filename}.txt | ${sed} -E 's#^[^/]+/#127.0.0.1:${port}/#')"
      echo "image: $IMAGE\nmirror: $IMAGE_MIRROR"
      ${docker} load -i ${image}/${filename}.tar
      ${docker} image tag "$IMAGE" "$IMAGE_MIRROR"
      ${docker} push "$IMAGE_MIRROR"
      '';
    script = lib.strings.concatLines (lib.forEach images (image: mkScript image));
  in {
    inherit script;
    wantedBy = ["multi-user.target"];
    after = ["docker.service" "docker.socket" "docker-registry.service"];
  };

  environment.systemPackages = with pkgs; [
    gptfdisk
    vim
    git
    git-lfs
    ripgrep
    curl
    eza
    gcc
    bat
    moreutils
    tree
    gnumake
    unzip
    htop
    fd
    dig
    wget
    openssl
    tokei
    httpie
    tcpdump

    dive
    skopeo
    talosctl
    kubectl
    kubernetes-helm
  ];
}
