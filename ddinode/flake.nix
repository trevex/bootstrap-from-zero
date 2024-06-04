{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators, ... }:
    let
      allSystems = [ "x86_64-linux" ]; # "aarch64-linux"
      mkPkgs = system:  pkgs: overlays: import pkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = overlays;
      };
      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        inherit system;
        pkgs = mkPkgs system nixpkgs [
          (final: prev: {
            images = self.packages."${system}";
          })
        ];
      });
    in
    {
      # nixosModules.origin = { config, ... }: {
      #   imports = [
      #     nixos-generators.nixosModules.all-formats
      #   ];

      #   nixpkgs.hostPlatform = "x86_64-linux";

      #   # # customize an existing format
      #   # formatConfigs.vmware = { config, ... }: {
      #   #   services.openssh.enable = true;
      #   # };

      #   # # define a new format
      #   # formatConfigs.my-custom-format = { config, modulesPath, ... }: {
      #   #   imports = [ "${toString modulesPath}/installer/cd-dvd/installation-cd-base.nix" ];
      #   #   formatAttr = "isoImage";
      #   #   fileExtension = ".iso";
      #   #   networking.wireless.networks = {
      #   #     # ...
      #   #   };
      #   # };

      #   # the evaluated machine
      #   nixosConfigurations.origin = nixpkgs.lib.nixosSystem {
      #     modules = [ self.nixosModules.origin ];
      #   };
      # };
      # overlays.default = final: prev: {
      #   prefetched-images = self.packages."x86_64-linux".prefetched-images;
      # };
      packages = forAllSystems ({ system, pkgs }:
      let
        mkDockerImagePkg = image: imageDigest: sha256:
          let
            lib = pkgs.lib;
            imageParts = lib.strings.splitString ":" image;
            imageName = builtins.elemAt imageParts 0;
            name = builtins.replaceStrings ["/"] ["-"] imageName;
            tag = builtins.elemAt imageParts 1;
            version = lib.strings.removePrefix "v" tag;
            tar = pkgs.dockerTools.pullImage {
              inherit sha256 imageName imageDigest;
              finalImageTag = tag;
            };
          in pkgs.stdenv.mkDerivation rec {
            inherit name version;
            src = ./.;

            dontConfigure = true;
            dontBuild = true;

            installPhase = ''
              mkdir -p $out/share/prefetched
              cp ${tar} $out/${name}-${version}.tar
              echo "${image}" > $out/${name}-${version}.txt
            '';
          };
        mkIso = modules: nixos-generators.nixosGenerate {
          inherit system;
          modules = [
            # Pin nixpkgs to the flake input, so that the packages installed
            # come from the flake inputs.nixpkgs.url.
            ({ ... }: { nix.registry.nixpkgs.flake = nixpkgs; })
            {
              nixpkgs.pkgs = pkgs;
              system.stateVersion = "23.11";
            }
          ] ++ modules;
          format = "iso";
        };
      in {
        iso = mkIso [ ./configuration.nix ];
        iso-airgapped = mkIso [ ./configuration.nix ./airgapped.nix ];

        # mkDockerImagePkg is a helper function which expects:
        # 1. image - full image path including tag
        # 2. imageDigest - digest of the image
        # 3. sha256 - hash of the files on disk
        #
        # For any given image they can be easily retrieved by running (there is most likely a better way):
        # `nix run nixpkgs#nix-prefetch-docker -- --image-name ghcr.io/siderolabs/install-cni --image-tag v1.7.0-1-gbb76755`
        # (NOTE: sha256 will be incorrect due to tag manipulation, but will be reported during nix build of ISO with correct value)

        busybox = mkDockerImagePkg "docker.io/busybox:v1.36.1" "sha256:50aa4698fa6262977cff89181b2664b99d8a56dbca847bf62f2ef04854597cf8" "sha256-hhg75zK34Au5tOlkMUDfdbZzIpX5AR6CN/6WNnB+oJw=";
        sidero-flannel = mkDockerImagePkg "ghcr.io/siderolabs/flannel:v0.25.1" "sha256:d8c4a6c1db4794e7138b5a7e6518b59a361c128477ca1e5670974fc98b80bd75" "sha256-dN+mYxeE4rgPclxEt9GlHW+rf+F3cvDNGBmL5DyfVA0=";
        sidero-install-cni = mkDockerImagePkg "ghcr.io/siderolabs/install-cni:v1.7.0-1-gbb76755" "sha256:260b18a4a40395db4636399b2ee503bb72f9d852427ba59c52468ac6c0f63548" "sha256-6nHQ40LyFG9UVxvBVmQSOzV+yQN+Bg+lbX35UWCgy4c=";
        coredns = mkDockerImagePkg "registry.k8s.io/coredns/coredns:v1.11.1" "sha256:1eeb4c7316bacb1d4c8ead65571cd92dd21e27359f0d4917f1a5822a73b75db1" "sha256-o9kQXTiieXVPXQeUdmI1IfwxytiOQ0qyQBqRzw9QJm8=";
        etcd = mkDockerImagePkg "gcr.io/etcd-development/etcd:v3.5.13" "sha256:f435f2be55ca8fbaa56126419f3d0d3a43695a856ffcb7e51a3b82dcab784c14" "sha256-9CKZzLqWjy2PIPnX0OXAcO7GF3tfLzMiJP8kSfEWuFk=";
        kube-apiserver = mkDockerImagePkg "registry.k8s.io/kube-apiserver:v1.30.1" "sha256:0d4a3051234387b78affbcde283dcde5df21e0d6d740c80c363db1cbb973b4ea" "sha256-5V6CJ7Ott3s1x6HbrdkmRTSoB3s4BHHeTl9PbNa+Mbw=";
        kube-controller-manager = mkDockerImagePkg "registry.k8s.io/kube-controller-manager:v1.30.1" "sha256:0c34190fbf807746f6584104811ed5cda72fb30ce30a036c132dea692d55ec52" "sha256-fKiiw07aI8sJWUHnkMGPdGY5pLQRsKJt32whGva+J7o=";
        kube-scheduler = mkDockerImagePkg "registry.k8s.io/kube-scheduler:v1.30.1" "sha256:74d02f6debc5ff3d3bc03f96ae029fb9c72ec1ea94c14e2cdf279939d8e0e036" "sha256-+AxEQHLdlCZ0Z8W3HARDEqHsRkg909aiYFTBV1g8K5E=";
        kube-proxy = mkDockerImagePkg "registry.k8s.io/kube-proxy:v1.30.1" "sha256:a1754e5a33878878e78dd0141167e7c529d91eb9b36ffbbf91a6052257b3179c" "sha256-Zblc0d5ohe9M8Xp1mrKH4vaiSWKpnfvDtKX4yegLEz4=";
        sidero-kubelet = mkDockerImagePkg "ghcr.io/siderolabs/kubelet:v1.30.1" "sha256:8f4676166f2b00394d3d33e69188223fa71a4155889f8033f6f567662ebf4358" "sha256-uZIddAwMMyJ5FUBYGSAcYAk5w/tasHm9X8eYKAd2MKc=";
        sidero-installer = mkDockerImagePkg "ghcr.io/siderolabs/installer:v1.7.2" "sha256:4aa890d7bd47a1aa369a91e832b613ecfd6f929f9b993af5f1097dd00c46f665" "sha256-GHmRJBjWF9mocJ7v1zaDeON0IqoI+o9UI3fjDlGSxnU=";
        kube-pause = mkDockerImagePkg "registry.k8s.io/pause:3.8" "sha256:9001185023633d17a2f98ff69b6ff2615b8ea02a825adffa40422f51dfdcde9d" "sha256-Bkq7CP5ECMe2kuUWCx4q+G1IuJaIpJ8c5/r8tOF7UUE=";
      });
    };
}
