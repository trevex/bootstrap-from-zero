{
  description = "bootstrap-from-zero";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    let
      overlays = [ ];
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system overlays; };
      in
      rec {
        devShell = pkgs.mkShell rec {
          name = "bootstrap-from-zero";

          buildInputs = with pkgs; [
            just
            curl
            gnugrep
            gnused

            qemu
            opentofu

            kubectl
            kubernetes-helm
            kind
            kubevirt
            clusterctl
            talosctl
          ];
        };
      }
    );
}
