{ config, lib, pkgs, ... }:

{
  users.users.hexchen = {
    uid = 1000;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINJ0tCxsEilAzV6LaNpUpcjzyEn4ptw8kFz3R+Z3YjEF hexchen@backup"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDI3T1eFS77URHZ/HVWkMOqx7W1U54zJtn9C7QWsHOtyH72i/4EVj8SxYqLllElh1kuKUXSUipPeEzVsipFVvfH0wEuTDgFffiSQ3a8lfUgdEBuoySwceEoPgc5deapkOmiDIDeeWlrRe3nqspLRrSWU1DirMxoFPbwqJXRvpl6qJPxRg+2IolDcXlZ6yxB4Vv48vzRfVzZNUz7Pjmy2ebU8PbDoFWL/S3m7yOzQpv3L7KYBz7+rkjuF3AU2vy6CAfIySkVpspZZLtkTGCIJF228ev0e8NvhuN6ZnjzXxVTQOy32HCdPdbBbicu0uHfZ5O7JX9DjGd8kk1r2dnZwwy/ hexchen@yubi5"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4CLJ+mFfq5XiBXROKewmN9WYmj+79bj/AoaR6Iud2pirulot3tkrrLe2cMjiNWFX8CGVqrsAELKUA8EyUTJfStlcTE0/QNESTRmdDaC+lZL41pWUO9KOiD6/0axAhHXrSJ0ScvbqtD0CtpnCKKxtuOflVPoUGZsH9cLKJNRKfEka0H0GgeKb5Tp618R/WNAQOwaCcXzg/nG4Bgv3gJW4Nm9IKy/MwRZqtILi8Mtd+2diTqpMwyNRmbenmRHCQ1vRw46joYkledVqrmSlfSMFgIHI1zRSBXb/JkG2IvIyB5TGbTkC4N2fqJNpH8wnCKuOvs46xmgdiRA26P48C2em3 hexchen@yubi5c"
    ];
    isNormalUser = true;
    extraGroups = [ "wheel" "systemd-journal" ];
    shell = pkgs.fish;
  };

  users.users.avara = {
    uid = 1001;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyc5MWLx4kkAtkCCYvTOr6iIgGvOXRPmTIneg/x10uS"
    ];
    isNormalUser = true;
    extraGroups = [ "wheel" "systemd-journal" ];
    shell = pkgs.zsh;
  };
}
