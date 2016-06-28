{ systemNixpkgs ? import <nixpkgs> {}
}:
let
  inherit (systemNixpkgs) stdenv fetchzip;

  version = import ./version.nix;

  getUrl = name: channels:
    "${channels.${name}.baseUrl}/${channels.${name}.version}/nixexprs.tar.xz";
  getSha = name: channels: channels.${name}.sha256;
  getVer = name: channels: channels.${name}.version;
  fetchChannel = url: sha256: name:
    fetchzip { inherit url sha256 name; };

  channelPath = name: channels: fetchChannel
    (getUrl name channels)
    (getSha name channels)
    "${name}-${getVer name channels}";

  nixpkgsPath = builtins.toPath (channelPath "nixpkgs" version.channels);
  nixpkgs = import nixpkgsPath {};

  orgName = "referentiallabs";
  appName = "certmon";
  appRoot = builtins.toPath ../..;

  homeDir = builtins.getEnv "HOME";

  haskell = nixpkgs.haskellPackages.ghcWithPackages (p: with p; [
    optparse-applicative
    cabal-install
    ghc-mod
    pointfree
    amazonka
    amazonka-core
    amazonka-autoscaling
    amazonka-elb
    amazonka-ec2
    async
    hnix
    lens
    transformers
    conduit
    criterion
    doctest
    QuickCheck
  ]);

in stdenv.mkDerivation {
  name = "${orgName}-${appName}";
  buildInputs = with nixpkgs; [
    bash
    git
    haskell
  ];

  shellHook = ''
    export Z_APP_NAME="${appName}"
    export Z_APP_ROOT="${appRoot}"

    export NIX_PATH="nixpkgs=${nixpkgsPath}"
    export NIX_PATH="$NIX_PATH:nixos=${nixpkgsPath}/nixos"
  '';
}
