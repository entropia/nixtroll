{ nixpkgs, hosts, colmena, colmenaHiveMeta }:

with nixpkgs.lib;

let
  inherit (nixpkgs) lib;

  filteredHosts = filterAttrs
    (_: v: !(v.meta.dummy or false || v.deploy.profiles or lib == {} || v.meta.darwin or false))
    hosts;

  getDeploymentConfig = n: v:
    evalModule (
      if hasAttr "deployment" v
      then { inherit (v) deployment; }
      else translateDeploy n v
    );
  evalModule = config: nixpkgs.lib.evalModules {
    modules = [ colmena.nixosModules.deploymentOptions config ];
  };
  translateDeploy = n: v: {
    deployment = {
      allowLocalDeployment = true;
      targetHost = v.deploy.hostname;
      targetPort = 54160;
      targetUser = null;
    };
  };

in rec {
  __schema = "v0.20241006";

  nodes = mapAttrs (_: v: v.nixosConfiguration) filteredHosts;
  toplevel = mapAttrs (_: v: v.config.system.build.toplevel) nodes;
  deploymentConfig = mapAttrs (n: v: (getDeploymentConfig n v).config.deployment) filteredHosts;
  deploymentConfigSelected = names: filterAttrs (name: _: elem name names) deploymentConfig;
  evalSelected = names: filterAttrs (name: _: elem name names) toplevel;
  evalSelectedDrvPaths = names: mapAttrs (_: v: v.drvPath) (evalSelected names);
  metaConfig = colmenaHiveMeta;
  introspect = f:
    f {
      inherit lib nodes hosts;
      pkgs = nixpkgs;
    };
}
