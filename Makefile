# Disable builtin rules and variables since they aren't used
# This makes the output of "make -d" much easier to follow and speeds up evaluation
# NB you can use make --print-data-base --dry-run to troubleshoot this Makefile.
MAKEFLAGS+= --no-builtin-rules
MAKEFLAGS+= --no-builtin-variables

.PHONY: build

build: packer-qemu-ansible-windows-example.box

%.box: example.pkr.hcl
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$*-packer-init.log \
		packer init example.pkr.hcl
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$*-packer.log \
	PKR_VAR_vagrant_box=$@ \
  	PKR_VAR_disk_image="${HOME}/.vagrant.d/boxes/windows-2022-amd64/0.0.0/libvirt/box.img" \
		packer build -only=qemu.example -on-error=abort example.pkr.hcl
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f $* $@
