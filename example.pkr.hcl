packer {
  required_plugins {
    # see https://github.com/hashicorp/packer-plugin-qemu
    qemu = {
      version = "1.1.4"
      source  = "github.com/hashicorp/qemu"
    }
    # see https://github.com/hashicorp/packer-plugin-vagrant
    vagrant = {
      version = "1.1.7"
      source  = "github.com/hashicorp/vagrant"
    }
    # see https://github.com/hashicorp/packer-plugin-ansible
    ansible = {
      version = "1.1.5"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "disk_size" {
  type    = string
  default = "61440"
}

variable "disk_image" {
  type = string
}

variable "vagrant_box" {
  type = string
}

source "qemu" "example" {
  efi_boot          = true
  efi_firmware_code = "/usr/share/OVMF/OVMF_CODE_4M.fd"
  efi_firmware_vars = "/usr/share/OVMF/OVMF_VARS_4M.fd"
  cpus              = 2
  memory            = 4096
  qemuargs = [
    ["-machine", "type=q35,accel=kvm,hpet=off"],
    ["-cpu", "host,hv-passthrough"],
    ["-rtc", "base=localtime,clock=host"],
    ["-device", "qemu-xhci"],
    ["-device", "virtio-tablet"],
    ["-device", "virtio-scsi-pci,id=scsi0"],
    ["-device", "scsi-hd,bus=scsi0.0,drive=drive0"],
    ["-device", "virtio-net,netdev=user.0"],
    ["-vga", "qxl"],
    ["-device", "virtio-serial-pci"],
    ["-chardev", "socket,path=/tmp/{{ .Name }}-qga.sock,server,nowait,id=qga0"],
    ["-device", "virtserialport,chardev=qga0,name=org.qemu.guest_agent.0"],
    ["-chardev", "spicevmc,id=spicechannel0,name=vdagent"],
    ["-device", "virtserialport,chardev=spicechannel0,name=com.redhat.spice.0"],
    ["-spice", "unix,addr=/tmp/{{ .Name }}-spice.socket,disable-ticketing"],
  ]
  headless         = true
  disk_size        = var.disk_size
  disk_interface   = "virtio-scsi"
  disk_cache       = "unsafe"
  disk_discard     = "unmap"
  disk_image       = true
  use_backing_file = true
  net_device       = "virtio-net"
  iso_url          = var.disk_image
  iso_checksum     = "none"
  communicator     = "winrm"
  winrm_username   = "vagrant"
  winrm_password   = "vagrant"
  winrm_timeout    = "4h"
  shutdown_command = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
}

build {
  sources = [
    "source.qemu.example",
  ]
  provisioner "ansible" {
    use_proxy = false
    user      = "vagrant"
    command   = "./ansible-playbook.sh"
    extra_arguments = [
      "-e", "ansible_connection=psrp",
      "-e", "ansible_psrp_protocol=http",
      "-e", "ansible_psrp_message_encryption=never",
      "-e", "ansible_psrp_auth=credssp",
    ]
    playbook_file = "playbook.yml"
  }
  # TODO https://github.com/hashicorp/packer-plugin-vagrant/issues/44
  post-processor "vagrant" {
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile.template"
  }
}
