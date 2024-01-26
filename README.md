# nix-visor

Run Nix Flakes on Lima virtual machines.

## Tasks

### create-lima-vm

Install Nix on via `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`

```bash
limactl create --tty=false --name=default template://ubuntu
```

### create-install-iso

```bash
nix-build '<nixpkgs/nixos>' -A vm \
-I nixpkgs=channel:nixos-23.11 \
-I nixos-config=./configuration.nix
```

### check-builder

```nix
NIX_SSHOPTS='-p 60022' nix store info --store ssh://adrian@127.0.0.1
```

### configure-ssh

You need to setup the correct SSH options, in `/etc/ssh/ssh_config` because in a multi-user system, the builder runs as root.

```
echo "Write the following in your ~/.ssh/config"
cat << EOF
Host lima-default
	HostName 127.0.0.1
	Port 60022
	StrictHostKeyChecking=no
	User adrian
 	IdentityFile /Users/adrian/.lima/_config/user
EOF
```

### check-builder-lima

```nix
nix store info --store ssh://lima-default
```

### display-system

```bash
nix build --impure \
  --builders 'ssh://lima-default aarch64-linux' \
  --expr '(with import <nixpkgs> { system = "aarch64-linux"; }; runCommand "foo" {} "uname > $out")' 
cat ./result
```

### build-flake-aarch64

```bash
nix build --builders "ssh://lima-default aarch64-linux" ./#packages.vm.aarch64-linux
```

### build-flake-x86_64

```bash
nix build ./#packages.vm.x86_64-linux
```

### virt-run

Env: LIBVIRT_DEFAULT_URI=qemu:///system

Copy the image from the read-only Nix store to the local directory, and run it.

```bash
sudo mkdir -p /vm
sudo cp -L ./result/nixos.qcow2 /vm
sudo chmod 660 /vm/nixos.qcow2
sudo chown -R libvirt-qemu:libvirt-qemu /vm
virt-install --name nix-visor --memory 2048 --vcpus 1 --disk /vm/nixos.qcow2,bus=sata --import --os-variant nixos-unknown --network default --no-auto-console
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
