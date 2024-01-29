{ pkgs, lib, hostname, ... }: {
  networking = {
    hostName = hostname;
  };
  # Enable the OpenSSH server.
  services.openssh = {
    enable = true;
  };
  systemd = {
    services = {
      fetch-github-pat = {
        script =
          ''
            mkdir -p /run/secrets/github-runner
            ${pkgs.curl}/bin/curl --retry 5 --retry-max-time 120 http://192.168.122.1:9494/secrets/github_pat >> /run/secrets/github-runner/github_pat
          '';
        enable = true;
        description = "fetch-github-pat";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          Restart = "on-failure";
          RemainAfterExit = "yes";
        };
      };
    };
  };
  # Enable a Github Runner.
  services.github-runner = {
    enable = true;
    replace = true;
    ephemeral = true;
    # Shutdown the machine when the Github Action finishes processing its job.
    serviceOverrides = {
      Restart = lib.mkForce "on-failure";
      ExecStopPost = [ "+${pkgs.shutdown-on-success}/bin/shutdown-on-success" ];
      After = "fetch-github-pat.service";
    };
    url = "https://github.com/a-h/self-hosted-runner-test";
    tokenFile = "/run/secrets/github-runner/github_pat";
  };
  # Setup nix to use flakes.
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      trusted-users = [ "root" "@wheel" ];
    };
  };
  users.users = {
    adrian = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      initialPassword = "password";
      openssh.authorizedKeys.keys = [
        # github.com/a-h.keys
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4ZYYVVw4dsNtzOnBCTXbjuRqOowMOvP3zetYXeE5i+2Strt1K4vAw37nrIwx3JsSghxq1Qrg9ra0aFJbwtaN3119RR0TaHpatc6TJCtwuXwkIGtwHf0/HTt6AH8WOt7RFCNbH3FuoJ1oOqx6LZOqdhUjAlWRDv6XH9aTnsEk8zf+1m30SQrG8Vcclj1CTFMAa+o6BgGdHoextOhGMlTx8ESAlgIXCo+dIVjANE2qbfAg0XL0+BpwlRDJt5OcgzrILXZ1jSIYRW4eg/JBcDW/WqorEummxhB26Y6R0jeswRF3DOQhU2fAhbsCWdairLam42rFGlKfWyTbgjRXl/BNR"
      ];
      packages = [
        pkgs.vim
      ];
    };
  };
  system.stateVersion = "23.11";
}
