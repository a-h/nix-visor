# nix-visor

Run Nix Flakes on virt-ssh managed virtual machines.

## Tasks

### build-image-1

```bash
nix build ./#packages.vm.nix-runner-1
```

### build-images

If you add more, add more builds, one for each host.

```bash
sudo mkdir -p /vm

nix build ./#packages.vm.runner-1
sudo cp -L ./result/nixos.qcow2 /vm/runner-1.qcow2

nix build ./#packages.vm.runner-2
sudo cp -L ./result/nixos.qcow2 /vm/runner-2.qcow2

sudo chmod 660 /vm/*.qcow2
sudo chown -R libvirt-qemu:libvirt-qemu /vm
```

### virt-run

Env: LIBVIRT_DEFAULT_URI=qemu:///system

Copy the image from the read-only Nix store to the local directory, and run it.

```bash
sudo mkdir -p /vm
sudo cp -L ./result/nixos.qcow2 /vm
sudo chmod 660 /vm/nixos.qcow2
sudo chown -R libvirt-qemu:libvirt-qemu /vm
virt-install --name nix-visor --memory 2048 --vcpus 1 --disk /vm/nixos.qcow2,bus=sata --import --os-variant nixos-unknown --network default --noautoconsole
```

### virt-list

Env: LIBVIRT_DEFAULT_URI=qemu:///system

```bash
virsh list --all
```

### virt-kill-all

Shutdown with virtsh shutdown, or in this case, completely remove it with undefine.

Env: LIBVIRT_DEFAULT_URI=qemu:///system

```bash
virsh destroy runner-1 || true
virsh undefine runner-1 --remove-all-storage || true
virsh destroy runner-2 || true
virsh undefine runner-2 --remove-all-storage || true
```

### virt-ssh

https://www.cyberciti.biz/faq/find-ip-address-of-linux-kvm-guest-virtual-machine/

```bash
virsh domifaddr nix-visor | virsh-json | jq -r ".[0].Address"
```

### firewall-config

On the host machine, to allow the VMs to access your machine, run:

```
sudo ufw allow from 192.168.122.0/16 to 192.168.122.1 port 9494 proto tcp
sudo ufw reload
```

### serve-metadata

```
serve -addr "0.0.0.0:9494" -dir ./metadata
```

### virsh-dumpxml

To see the underlying XML of a domain, you can dump it.

```
virsh dumpxml runner-1  > config.xml
```
