set shell := ["bash", "-uc"]

# Flavours live in recipes/<flavour>.yml. Override with e.g. `just build gaming`.
default_flavour := "workstation"

# Secure Boot: the blue-build base signs the kernel/modules with its own MOK key
# (not Fedora's). The ISO installer enrolls it; enter this password at the shim
# MOK manager on first boot. See README.md ("Secure Boot").
secure_boot_url := "https://github.com/blue-build/base-images/raw/main/files/base/etc/pki/akmods/certs/akmods-blue-build.der"
enrollment_password := "bluebuild"

# bootc-image-builder: builds disk/ISO images directly from a local bootc
# container image (no registry needed). Used by `just disk`.
bib_image := "quay.io/centos-bootc/bootc-image-builder:latest"

# build-container-installer: the third-party ISO builder that BlueBuild's
# `generate-iso` wraps. `iso-direct` calls it directly. Pinned to the tag
# bluebuild itself uses.
installer_image := "ghcr.io/jasonn3/build-container-installer:v1.5.0"

# Fedora release of the installer runtime for `iso-direct`. Keep in sync with
# the base image (image-version: latest -> currently Fedora 44).
iso_version := "44"

# List available tasks.
default:
    @just --list

# Print the generated Containerfile for a flavour (to stdout).
containerfile flavour=default_flavour:
    bluebuild generate recipes/{{flavour}}.yml

# Print the fully-resolved recipe with all from-file includes expanded.
recipe-dump flavour=default_flavour:
    bluebuild generate --display-full-recipe recipes/{{flavour}}.yml

# Build a flavour image locally (rootless podman storage).
build flavour=default_flavour:
    bluebuild build recipes/{{flavour}}.yml

# Build a flavour image into rootful podman storage (needed by bootc-image-builder).
build-root flavour=default_flavour:
    sudo "$(command -v bluebuild)" build recipes/{{flavour}}.yml

# Build a bootable QCOW2 from the local image (run `just build-root` first).
disk flavour=default_flavour:
    mkdir -p output
    sudo podman run --rm -it --privileged --pull=newer \
        --security-opt label=type:unconfined_t \
        -v ./bib/config.toml:/config.toml:ro \
        -v ./output:/output \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        {{bib_image}} \
        --type qcow2 --use-librepo=True --rootfs btrfs \
        --config /config.toml \
        localhost/silver-hour-{{flavour}}:latest

# Boot the QCOW2 from `just disk` in QEMU/KVM.
vm-disk flavour=default_flavour *args:
    qemu-system-x86_64 \
        -enable-kvm -m 8192 -smp 4 -cpu host \
        -machine q35,accel=kvm \
        -device virtio-vga-gl -display gtk,gl=on \
        -device virtio-net-pci,netdev=net0 -netdev user,id=net0 \
        -drive file=output/qcow2/disk.qcow2,if=virtio,format=qcow2 {{args}}

# Build the offline ISO from a *published* image, embedding the Secure Boot key.
# The Silverblue installer variant matches the base image.
iso flavour=default_flavour variant="silverblue":
    sudo -v
    bluebuild generate-iso \
        --iso-name silver-hour-{{flavour}}.iso \
        --variant {{variant}} \
        --secure-boot-url {{secure_boot_url}} \
        --enrollment-password {{enrollment_password}} \
        image ghcr.io/gooserooster/silver-hour-{{flavour}}:latest

# Build the offline ISO by invoking build-container-installer directly.
iso-direct flavour=default_flavour variant="silverblue" version=iso_version *extra:
    #!/usr/bin/env bash
    set -euo pipefail
    rm -f "$PWD/silver-hour-{{flavour}}.iso" "$PWD/silver-hour-{{flavour}}.iso-CHECKSUM"
    sudo -v
    args=(
        ISO_NAME=build/silver-hour-{{flavour}}.iso
        DNF_CACHE=/cache/dnf
        SECURE_BOOT_KEY_URL={{secure_boot_url}}
        ENROLLMENT_PASSWORD={{enrollment_password}}
        IMAGE_REPO=ghcr.io/gooserooster
        IMAGE_NAME=silver-hour-{{flavour}}
        IMAGE_TAG=latest
        VERSION={{version}}
    )
    if [ -n "{{variant}}" ]; then
        args+=(VARIANT={{variant}})
    else
        args+=("VARIANT=''")
    fi
    sudo podman run --rm -it --privileged --pull=always \
        --security-opt label=type:unconfined_t \
        -v "$PWD:/build-container-installer/build" -v dnf-cache:/cache/dnf \
        {{installer_image}} \
        "${args[@]}" {{extra}}

# Remove stale root-owned bluebuild artifacts left by an aborted root run.
clean:
    sudo rm -rf .bluebuild-scripts_

# Boot an ISO in QEMU/KVM (UEFI, virtio-gpu, software GL fallback).
vm iso="silver-hour-workstation.iso" *args:
    qemu-system-x86_64 \
        -enable-kvm -m 8192 -smp 4 -cpu host \
        -machine q35,accel=kvm \
        -device virtio-vga-gl -display gtk,gl=on \
        -device virtio-net-pci,netdev=net0 -netdev user,id=net0 \
        -cdrom {{iso}} -boot d {{args}}
