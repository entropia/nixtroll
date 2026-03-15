{ config, lib, pkgs, sources, ... }:

{
  services.nginx.package = pkgs.nginx.override {
    withGeoIP = true;
  };
  services.nginx.appendHttpConfig = ''
    geoip_country ${pkgs.geolite-legacy}/share/GeoIP/GeoIPv6.dat;
    map $geoip_country_code $allow_visit {
      DE yes;
      AT yes;
      CH yes;
      FR yes;
      NL yes;
      DK yes;
      GB yes;
      default $geoip_bypass;
    }

    geo $geoip_bypass {
      151.218.0.0/18 yes;
      2a0e:c5c0::/29 yes;
      default no;
    }
  '';
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx.enable = true;
  services.nginx.virtualHosts."troll.gulas.ch" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      root = "/var/www";
      extraConfig = "try_files $uri $uri/ /index.html;";
    };
    locations."/api/" = {
      proxyPass = "http://localhost:8080/";
      extraConfig = ''
        if ($allow_visit = no) {
          return 403;
        }
      '';
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    ensureDatabases = [
      "trollsystem-auth"
    ];
    ensureUsers = [
      {
        name = "trollsystem-auth";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.trollsystem-auth = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "postgresql.service" ];
    serviceConfig = {
      DynamicUser = true;
      ExecStart = "${sources.trollsystem.packages.${pkgs.system}.trollsystem-auth}/bin/trollsystem-auth";
      Restart = "always";
    };
  };

  systemd.services.trollsystem-api = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "trollsystem-auth.service" ];
    serviceConfig = {
      DynamicUser = true;
      ExecStart = "${sources.trollsystem.packages.${pkgs.system}.trollsystem-api}/bin/trollsystem-api";
      Restart = "always";
    };
  };
}
