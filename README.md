# nix-visor

Run Nix Flakes on virt-ssh managed virtual machines.

## Tasks

### build-image

If you add more, add more builds, one for each host.

```bash
nix build ./#packages.vm.nix-host-a
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

### virt-kill

Shutdown with virtsh shutdown, or in this case, completely remove it with undefine.

Env: LIBVIRT_DEFAULT_URI=qemu:///system

```bash
virsh destroy nix-visor || true
virsh undefine nix-visor --remove-all-storage || true
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
