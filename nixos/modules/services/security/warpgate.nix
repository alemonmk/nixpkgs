{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.warpgate;
  yaml = pkgs.formats.yaml {};
in {
  options.services.warpgate = let
    inherit (lib.types) path submodule;
    inherit (lib.options) mkOption mkPackageOption mkEnableOption;
  in {
    enable = mkEnableOption "Warpgate, a smart SSH, HTTPS, MySQL and Postgres bastion/PAM that doesn't need additional client-side software.";

    package = mkPackageOption pkgs "warpgate" {};

    settings = mkOption {
      description = "Warpgate configuration, the default values were generated with `warpgate setup`.";
      type = submodule {
        freeformType = yaml.type;
        options = {
          sso_providers = mkOption {
            default = [];
            type = yaml.type;
          };
          recordings = {
            enable = mkOption {
              default = true;
              type = yaml.type;
            };
            path = mkOption {
              default = "/var/lib/warpgate/recordings";
              type = yaml.type;
            };
          };
          external_host = mkOption {
            default = null;
            type = yaml.type;
          };
          database_url = mkOption {
            default = "sqlite:/var/lib/warpgate/db";
            type = yaml.type;
          };
          ssh = {
            enable = mkOption {
              default = false;
              type = yaml.type;
            };
            listen = mkOption {
              default = "[::]:2222";
              type = yaml.type;
            };
            external_port = mkOption {
              default = null;
              type = yaml.type;
            };
            keys = mkOption {
              default = "/var/lib/warpgate/ssh-keys";
              type = yaml.type;
            };
            host_key_verification = mkOption {
              default = "prompt";
              type = yaml.type;
            };
            inactivity_timeout = mkOption {
              default = "5m";
              type = yaml.type;
            };
            keepalive_interval = mkOption {
              default = null;
              type = yaml.type;
            };
          };
          http = {
            enable = mkOption {
              default = true;
              type = yaml.type;
            };
            listen = mkOption {
              default = "[::]:8888";
              type = yaml.type;
            };
            external_port = mkOption {
              default = null;
              type = yaml.type;
            };
            certificate = mkOption {
              default = "/var/lib/warpgate/tls.certificate.pem";
              type = yaml.type;
            };
            key = mkOption {
              default = "/var/lib/warpgate/tls.key.pem";
              type = yaml.type;
            };
            trust_x_forwarded_headers = mkOption {
              default = false;
              type = yaml.type;
            };
            session_max_age = mkOption {
              default = "30m";
              type = yaml.type;
            };
            cookie_max_age = mkOption {
              default = "1day";
              type = yaml.type;
            };
          };
          mysql = {
            enable = mkOption {
              default = false;
              type = yaml.type;
            };
            listen = mkOption {
              default = "[::]:33306";
              type = yaml.type;
            };
            external_port = mkOption {
              default = null;
              type = yaml.type;
            };
            certificate = mkOption {
              default = "/var/lib/warpgate/tls.certificate.pem";
              type = yaml.type;
            };
            key = mkOption {
              default = "/var/lib/warpgate/tls.key.pem";
              type = yaml.type;
            };
          };
          postgres = {
            enable = mkOption {
              default = false;
              type = yaml.type;
            };
            listen = mkOption {
              default = "[::]:55432";
              type = yaml.type;
            };
            external_port = mkOption {
              default = null;
              type = yaml.type;
            };
            certificate = mkOption {
              default = "/var/lib/warpgate/tls.certificate.pem";
              type = yaml.type;
            };
            key = mkOption {
              default = "/var/lib/warpgate/tls.key.pem";
              type = yaml.type;
            };
          };
          log = {
            retention = mkOption {
              default = "7days";
              type = yaml.type;
            };
            send_to = mkOption {
              default = null;
              type = yaml.type;
            };
          };
          config_provider = mkOption {
            default = "database";
            type = yaml.type;
          };
        };
      };
      example = {
        ssh = {
          enable = true;
          listen = "[::]:2211";
        };
        http = {
          listen = "[::]:8011";
        };
      };
    };

    initialAdminPassFile = mkOption {
      description = "Secure local file containing the admin password. You could also use this insecure method `builtins.path {path = pkgs.writeText \"wg-admin-pass\" \"mypass123\";}` then make sure to change the password afterwards in webui or with `warpgate recover-access admin`";
      type = path;
      default = throw "`services.warpgate.initialAdminPassFile` is required to initialize warpgate"; # TODO: assertion?
      example = builtins.path {path = ./adminpassword.secret;};
    };
  };

  config = let
    preStartScript = pkgs.writers.writeBash "warpgate-dbinit" ''
      TARGET_DIR="/var/lib/warpgate"
      if [ -z "$(ls --ignore="config.yml" "$TARGET_DIR")" ]; then
        INITPWD=$(tr -d '\n\r' < ${cfg.initialAdminPassFile})
        ${lib.getExe cfg.package} --config "$TARGET_DIR/throwaway.yml" unattended-setup --data-path "$TARGET_DIR" --http-port 8888 --admin-password $INITPWD
        rm /var/lib/warpgate/throwaway.yml
      fi
      cp -f ${yaml.generate "warpgate-yaml-config" cfg.settings} /var/lib/warpgate/config.yml 2>/dev/null
    ''; # note: we only need the keys and db from setup command, since we provide our declarative configs
  in
    lib.mkIf cfg.enable {
      environment.systemPackages = [cfg.package];

      systemd.services.warpgate = {
        description = "Warpgate smart bastion";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        startLimitBurst = 5;
        restartTriggers = ["/var/lib/warpgate/config.yml"];
        serviceConfig = {
          ExecStartPre = preStartScript;
          ExecStart = "${lib.getExe cfg.package} --config /var/lib/warpgate/config.yml run";
          DynamicUser = true;
          RestartSec = 3;
          Restart = "on-failure";
          StateDirectory = "warpgate";
          StateDirectoryMode = "0700";
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectHome = true;
          PrivateDevices = true;
          DeviceAllow = [
            "/dev/null rw"
            "/dev/urandom r"
          ];
          DevicePolicy = "strict";
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          RestrictNamespaces = true;
          ProtectProc = "invisible";
          ProtectSystem = "full";
          ProtectClock = true;
          ProtectControlGroups = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          RemoveIPC = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
          ];
          AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
          CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE"];
        };
      };
    };

  meta.maintainers = with lib.maintainers; [alemonmk];
}
