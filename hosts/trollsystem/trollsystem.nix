{ config, lib, pkgs, ... }:

{
  sops.secrets = {
    mail_pass = {};
    oidc_client_id = {};
    oidc_client_secret = {};
  };
  users.users.engelsystem.extraGroups = [ config.users.groups.keys.name ];

  services.engelsystem = {
    enable = true;
    domain = "troll.gulas.ch";
    createDatabase = true;
    settings = {
      maintenance = false;

      database = {
        host = "localhost";
        database = "engelsystem";
        username = "engelsystem";
      };

      app_name = "Trollsystem";
      environment = "production";
      password_algorithm = "2y"; # bcrypt

      footer_items = {
        "faq.faq" = [ "/faq" "faq.view" ];
        "Impressum" = "https://entropia.de/Impressum";
      };
      contact_options = {
        "general.email" = "mailto:troll@gulas.ch";
      };

      email = {
        driver = "smtp";
        from.name = "GPN23 Trollsystem";
        from.address = "noreply@gulas.ch";

        host = "mail.entropia.de";
        port = 465;
        tls = true;
        username = "noreply@gulas.ch";
        password._secret = config.sops.secrets.mail_pass.path;
      };

      oauth.entropia = {
        name = "Entropia SSO";
        client_id._secret = config.sops.secrets.oidc_client_id.path;
        client_secret._secret = config.sops.secrets.oidc_client_secret.path;
        url_auth = "https://sso.entropia.de/realms/entropia/protocol/openid-connect/auth";
        url_token = "https://sso.entropia.de/realms/entropia/protocol/openid-connect/token";
        url_info = "https://sso.entropia.de/realms/entropia/protocol/openid-connect/userinfo";
        scope = [ "openid" "email" ];
        id = "sub";
        username = "nickname";
        email = "email";
        url = "https://sso.entropia.de";
        nested_info = false;
        hidden = false;
        mark_arrived = false;
        enable_password = false;
        allow_registration = true;
      };

      version = "${config.services.engelsystem.package.version}";

      enable_email_goodie = true;
      registration_enabled = true;
      signup_requires_arrival = true;
      autoarrive = false;
      supporters_can_promote = true;
      last_unsubscribe = 3;
      enable_password = true;
      enable_dect = true;
      enable_mobile_show = false;
      enable_full_name = false;
      enable_pronoun = true;
      enable_planned_arrival = true;
      enable_force_active = true;
      enable_self_worklog = false;
      goodie_type = "goodie";
      enable_voucher = true;
      max_freeloadable_shifts = 2;
      timezone = "Europe/Berlin";
      driving_license_enabled = false;
      ifsg_enabled = false;
      ifsg_light_enabled = true;
      enable_day_of_event = true;
      event_has_day0 = true;

      night_shifts = {
        enabled = true;
        start = 2;
        end = 8;
        multiplier = 2;
      };

      default_locale = "de_DE";
      locales = {
        de_DE = "Deutsch";
        en_US = "English";
      };
    };
    package = pkgs.engelsystem.overrideAttrs (prev: {
      version = "3.6.0-gulasch";
      src = pkgs.fetchzip {
        url = "https://github.com/engelsystem/engelsystem/releases/download/v3.6.0/engelsystem-v3.6.0.zip";
        hash = "sha256-AZVW04bcSlESSRmtfvP2oz15xvZLlGEz/X9rX7PuRGg=";
      };
      patches = [
        ./patches/0001-Trollsystem-Patches.patch
        (pkgs.fetchurl {
          url = "https://github.com/engelsystem/engelsystem/pull/1536.patch";
          hash = "sha256-yP27j8S+bf0uZkTMLQ9bZ6g73NeHw8yPLNp1/Ny3Shg=";
        })
      ];
    });
  };

  services.phpfpm.pools.engelsystem.phpEnv = {
    CONTACT_EMAIL = "mailto:troll@gulas.ch";
  };

  services.nginx.package = pkgs.nginx.override {
    withGeoIP = true;
  };
  services.nginx.appendHttpConfig = ''
    geo $auth_bypass {
      127.0.0.1/32 "off";
      ::1/128 "off";
      78.46.200.166/32 "off";
      2a01:4f8:c2c:188::/64 "off";
      default "secured";
    }

    geoip_country ${pkgs.geolite-legacy}/share/GeoIP/GeoIPv6.dat;
    map $geoip_country_code $allow_visit {
      DE yes;
      AT yes;
      CH yes;
      FR yes;
      default no;
    }
  '';
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx.virtualHosts."troll.gulas.ch" = {
    enableACME = true;
    forceSSL = true;
    locations."/".extraConfig = lib.mkBefore ''
      if ($allow_visit = no) {
        return 403;
      }
    '';
    locations."/metrics" = {
      root = "${config.services.engelsystem.package}/share/engelsystem/public";
      extraConfig = ''
        index index.php;
        try_files $uri $uri/ /index.php?$args;
        autoindex off;
        auth_basic $auth_bypass;
        auth_basic_user_file ${pkgs.writeText "metrics-htpasswd" ''
          metrics:$2b$05$Dcy8l.crQzwNdUvcRM5TQehMMUdwphwTwMawr6PKFBCBaIe38gxeK
        ''};
      '';
    };
    locations."/trolltypes".return = "301 https://troll.gulas.ch/angeltypes$is_args$args";
  };
}
