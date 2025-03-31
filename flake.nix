{
  description = "nixos-managed trollsystem";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.colmena.url = "github:zhaofengli/colmena/main";
  inputs.colmena.inputs.nixpkgs.follows = "/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.sops-nix.url = "github:Mic92/sops-nix";
  inputs.sops-nix.inputs.nixpkgs.follows = "/nixpkgs";
  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "/nixpkgs";

  outputs = { self, nixpkgs, colmena, flake-utils, sops-nix, disko, ...
    }@inputs:
    let
      specialArgs = {
        evalConfig = extraSpecial: system: config:
          nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              config

              sops-nix.nixosModules.sops
              disko.nixosModules.disko
            ];
            specialArgs = {
              inherit (specialArgs) evalConfig;
              inherit hosts;
              sources = inputs;
            } // extraSpecial;
          };
      };
      hostsDir = "${./.}/hosts";
      hostNames = with nixpkgs.lib;
        attrNames (filterAttrs (name: type: type == "directory")
          (builtins.readDir hostsDir));
      hostMeta = host:
        if builtins.pathExists "${hostsDir}/${host}/meta.nix" then
          (import "${hostsDir}/${host}/meta.nix")
          (inputs // { inherit (specialArgs) evalConfig; })
        else
          { };
      hostConfig = host:
        nixpkgs.lib.recursiveUpdateUntil (path: lhs: rhs:
          !(builtins.isAttrs lhs && builtins.isAttrs rhs) || rhs == { }) {
            nixosConfiguration = specialArgs.evalConfig { hostname = host; } "x86_64-linux" {
              imports = [ "${hostsDir}/${host}/configuration.nix" ];
              networking.hostName = host;
            };
            deployment = {
              allowLocalDeployment = true;
              targetHost = "${host}.gulas.ch";
              targetUser = null;
            };
          } (hostMeta host);
      hosts = with nixpkgs.lib;
        listToAttrs
        (map (name: nameValuePair name (hostConfig name)) hostNames);

      colmenaHiveMeta = {
        allowApplyAll = true;
        description = "troll deployment";
        machinesFile = null;
        name = "hive";
      };

      nixosHosts = nixpkgs.lib.filterAttrs (_: c: !(c.meta.darwin or false)) hosts;
    in {
      nixosConfigurations = builtins.mapAttrs (host: config:
        config.nixosConfiguration // {
          meta = hostMeta host;
        }) nixosHosts;

      colmenaHive = import ./lib/colmena-compat.nix { inherit nixpkgs hosts colmena colmenaHiveMeta; };
    } // flake-utils.lib.eachSystem ([
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ]) (system:
    let
      pkgs = (import nixpkgs {
        inherit system;
      });
    in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            colmena.packages.${system}.colmena
            sops-nix.packages.${system}.sops-init-gpg-key
            pkgs.age
            pkgs.sops
          ];
        };
      });
}
