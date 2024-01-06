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

### build-flake

```bash
nix build --builders "ssh://lima-default aarch64-linux" ./#packages.aarch64-linux.iso 
```

### run

```bash
nix shell nixpkgs#qemu
qemu-system-aarch64 -boot d -machine virt -cdrom ./result/iso/nixos.iso -m 512
```
