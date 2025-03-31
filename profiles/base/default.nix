{ config, lib, pkgs, ... }:

{
  imports = [
    ./users.nix
  ];

  nix.package = pkgs.lix;
  nix.settings = {
    trusted-users = [ "root" "@wheel" ];
    experimental-features = [ "nix-command" "flakes" "auto-allocate-uids" ];
  };

  nix.gc.automatic = lib.mkDefault true;
  nix.gc.options = lib.mkDefault "--delete-older-than 7d";
  environment.variables.EDITOR = "vim";
  programs.fish.enable = true;
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    kitty.terminfo
    htop
    tcpdump
    nload
    iftop
    bottom
    iperf
    binutils
    dnsutils
    minicom

    ripgrep
    fd
    pv
    progress
    parallel
    file
    vim
    git
    rsync
    whois
    p7zip
    zstd
    gnupg
    pinentry-curses
  ];

  services.zfs = lib.mkIf (config.boot.supportedFilesystems.zfs or false) {
    autoScrub.enable = true;
    autoSnapshot = {
      enable = true;
      frequent = 12;
      hourly = 24;
      daily = 3;
      weekly = 0;
      monthly = 0;
    };
  };

  systemd.network.enable = true;
  networking.useNetworkd = true;
  networking.nftables.enable = lib.mkDefault true;
  networking.domain = lib.mkDefault "gulas.ch";

  programs.command-not-found.enable = false;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = lib.mkDefault "no";
      GatewayPorts = lib.mkDefault "yes";
      LoginGraceTime = 0;
    };
    extraConfig = "StreamLocalBindUnlink yes";
  };
  security.sudo.wheelNeedsPassword = lib.mkDefault false;
  i18n.defaultLocale = "en_IE.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  programs.mtr.enable = true;
  time.timeZone = "UTC";
  sops.defaultSopsFile = ../../hosts/${config.networking.hostName}/secrets.sops.yaml;

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "oops@lists.entropia.de";

  environment.etc."ssl-unbundled".source = "${pkgs.cacert.unbundled}/etc/ssl";
}
