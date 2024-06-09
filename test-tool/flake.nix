{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      mkPackage = { pkgs, currentSystem }:
        with pkgs;
        stdenvNoCC.mkDerivation {
          name = "test-tool";

          version = "1.0.0";

          impureEnvVars = ["GITHUB_TOKEN"];

          src = fetchurl {
            url = currentSystem.url;
            sha256 = currentSystem.checksum;
            curlOptsList = [ "-H" "Authorization: Bearer ${builtins.getEnv("GITHUB_TOKEN")}" "-H" "Accept: application/octet-stream" "-L"];
            name = "archive.tar.gz";
          };

          sourceRoot = ".";

          installPhase = ''
            mkdir -p $out/bin
            mv $name $out/bin
          '';
        };
    in
    (flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      supportedSystems = {
        x86-64-linux = {
          url = "https://api.github.com/repos/jlevesy/test-tool/releases/assets/170752768";
          checksum = "t3mxvPMXajx+Kt3J7YD8+hJkpsHhRDglu3GSvvS3qYA=";
        };
      };

      args = {
        inherit pkgs;
        currentSystem = supportedSystems.${system} or builtins.throw "unsupported";
      };

    in {
      packages.${system} = mkPackage args;
      defaultPackage = mkPackage args;
     })
    );
}
