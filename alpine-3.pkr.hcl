/*
 * Alpine 3 Packer template for building Triton DataCenter/SmartOS images
 */

/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

/*
 * Copyright 2025 MNX Cloud, Inc.
 * Copyright 2025 Jeff Goeke-Smith 
 */

locals {
  alpine_3_ver          = "3.21"
  alpine_3_iso_url      = "https://dl-cdn.alpinelinux.org/alpine/v${local.alpine_3_ver}/releases/x86_64/alpine-virt-3.21.3-x86_64.iso"
  alpine_3_iso_checksum = "file:https://dl-cdn.alpinelinux.org/alpine/v${local.alpine_3_ver}/releases/x86_64/alpine-virt-3.21.3-x86_64.iso.sha256"

  alpine_3_boot_command = [
    "<wait5>",
    "root<enter>",
    "echo '${var.ssh_username}:${var.ssh_password}' | chpasswd<enter>",
    "setup-alpine -e -f http://{{ .HTTPIP }}:{{ .HTTPPort }}/alpine-3.answers<enter><wait30>",
    "mount /dev/vda2 /mnt<enter>",
    "echo PermitRootLogin yes >> /mnt/etc/ssh/sshd_config<enter><wait>",
    "chroot /mnt apk add cloud-init fstrim py3-pyserial e2fsprogs-extra<enter><wait10>",
    "umount /mnt<enter>",
    "reboot<enter>",
  ]

}

source "bhyve" "alpine-3-x86_64" {
  boot_command       = local.alpine_3_boot_command
  boot_wait          = var.boot_wait
  cpus               = var.cpus
  disk_size          = var.disk_size
  disk_use_zvol      = var.disk_use_zvol
  disk_zpool         = var.disk_zpool
  host_nic           = var.host_nic
  http_directory     = var.http_directory
  iso_checksum       = local.alpine_3_iso_checksum
  iso_url            = local.alpine_3_iso_url
  memory             = var.memory
  shutdown_command   = "/sbin/poweroff"
  ssh_password       = var.ssh_password
  ssh_timeout        = var.ssh_timeout
  ssh_username       = var.ssh_username
  vm_name            = "alpine-3-${formatdate("YYYYMMDD", timestamp())}.x86_64.zfs"
  vnc_bind_address   = var.vnc_bind_address
  vnc_use_password   = var.vnc_use_password
  vnc_port_min       = var.vnc_port_min
  vnc_port_max       = var.vnc_port_max
}

build {
  sources = [
    "bhyve.alpine-3-x86_64"
  ]

  provisioner "ansible" {
    playbook_file    = "./ansible/smartos.yml"
    galaxy_file      = "./ansible/requirements.yml"
    roles_path       = "./ansible/roles"
    collections_path = "./ansible/collections"
    extra_arguments  = [ "--scp-extra-args", "'-O '" ]
    ansible_env_vars = [
      "ANSIBLE_PIPELINING=True",
      "ANSIBLE_REMOTE_TEMP=/tmp",
      "ANSIBLE_SSH_ARGS='-o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa -o ControlMaster=no -o ControlPersist=180s -o ServerAliveInterval=120s -o TCPKeepAlive=yes'",
    ]
  }
}
