# Debian 11
# ---
# Packer Template to create Debian 11

# Variable Definitions
variable "proxmox_api_url" {
    type = string
}

variable "proxmox_api_token_id" {
    type = string
}

variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
}

# Resource Definiation for the VM Template
source "proxmox" "debian-server" {
 
    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"
    # (Optional) Skip TLS Verification
    # insecure_skip_tls_verify = true
    
    # VM General Settings
    # node is name of proxmox node to work on
    node = "pve-test"
    vm_id = "9001"
    vm_name = "debian-server-template"
    template_description = "Debian 11 Server Template"

    # VM OS Settings
    # (Option 1) Local ISO File
    iso_file = "iso_NAS:iso/debian-11.2.0-amd64-netinst.iso"
    # - or -
    # (Option 2) Download ISO
    # iso_url = "https://releases.ubuntu.com/20.04/ubuntu-20.04.3-live-server-amd64.iso"
    # iso_checksum = "f8e3086f3cea0fb3fefb29937ab5ed9d19e767079633960ccb50e76153effc98"
    iso_storage_pool = "iso_NAS"
    unmount_iso = true

    # VM System Settings
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-pci"

    disks {
        disk_size = "4G"
        format = "qcow2"
        storage_pool = "vm-storage-01"
        storage_pool_type = "directory"
        type = "scsi"
        cache_mode = "writeback"
    }

    # VM CPU Settings
    cores = "4"
    
    # VM Memory Settings
    memory = "4096" 

    # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr1"
        firewall = "false"
        vlan_tag = "99"
    } 

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "vm-storage-01"

    # PACKER Boot Commands
    boot_command = [
        "<esc><wait>",
        "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg",
        "<enter>"
    ]
    boot = "c"
    boot_wait = "5s"

    # PACKER Autoinstall Settings
    http_directory = "http" 
    # (Optional) Bind IP Address and Port
    # http_bind_address = "0.0.0.0"
    # http_port_min = 8802
    # http_port_max = 8802

    ssh_username = "root"

    # (Option 1) Add your Password here
    ssh_password = "r00tme"
    # - or -
    # (Option 2) Add your Private SSH KEY file here
    #ssh_private_key_file = "~/.ssh/id_rsa"

    # Raise the timeout, when installation takes longer
    ssh_timeout = "20m"
}

# Build Definition to create the VM Template
build {

    name = "debian-server"
    sources = ["source.proxmox.debian-server"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "rm /etc/ssh/ssh_host_*",
            "truncate -s 0 /etc/machine-id",
            "apt -y autoremove --purge",
            "apt -y clean",
            "apt -y autoclean",
            "cloud-init clean",
            "sync",
            "passwd --expire root"
        ]
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
    provisioner "file" {
        source = "files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = [ "cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }

    # Add additional provisioning scripts here
    # ...
}