# packer-debian11

## Build a proxmox template with debian11-netinst iso using packer

clone, edit vars/params as needed then run this in the debian-cloud-init dir

```bash
packer build --var-file=../credentials.pkr.hcl .
```
