build-dir:
    mkdir -p build/storage

talos-iso: build-dir
    #!/usr/bin/env bash
    set -euxo pipefail
    cd build
    if [ -f talos-amd64.iso ]; then
        echo "talos ISO already downloaded"
    else
        curl -L https://github.com/siderolabs/talos/releases/download/v1.7.4/metal-amd64.iso -o talos-amd64.iso
    fi

prepare: talos-iso
