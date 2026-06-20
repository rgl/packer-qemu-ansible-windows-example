# About

This shows how to provision a VM image using [Ansible](https://www.ansible.com/) from a [Packer](https://www.packer.io/) template.

# Usage (Ubuntu 24.04)

Install packer, qemu/kvm, docker, make, vagrant and the [Windows 2022 UEFI vagrant box](https://github.com/rgl/windows-vagrant).

Lint the [`playbook.yml` playbook](playbook.yml) playbook:

```bash
./ansible-lint.sh --offline --parseable playbook.yml || echo 'ERROR linting'
```

Provision the VM image and vagrant box:

```bash
make
```

Try using the VM image in a new VM:

```bash
vagrant box add -f packer-qemu-ansible-windows-example packer-qemu-ansible-windows-example.box
for vol in $(virsh vol-list --pool default | awk '/packer-qemu-ansible-windows-example_/ {print $1}'); do
    virsh vol-delete --pool default "$vol"
done
pushd example
vagrant up --no-destroy-on-error --no-tty --provider=libvirt
vagrant ssh
exit
vagrant destroy -f
popd
vagrant box remove -f packer-qemu-ansible-windows-example
for vol in $(virsh vol-list --pool default | awk '/packer-qemu-ansible-windows-example_/ {print $1}'); do
    virsh vol-delete --pool default "$vol"
done
```

List this repository dependencies (and which have newer versions):

```bash
GITHUB_COM_TOKEN='YOUR_GITHUB_PERSONAL_TOKEN' ./renovate.sh
```
