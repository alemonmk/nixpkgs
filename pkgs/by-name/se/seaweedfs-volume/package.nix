{
  lib,
  rustPlatform,
  seaweedfs,
  pkg-config,
  protobuf,
  aws-lc,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  inherit (seaweedfs) version src;
  __structuredAttrs = true;

  pname = "seaweedfs-volume";

  sourceRoot = "${finalAttrs.src.name}/seaweed-volume";

  cargoHash = "sha256-lWwoUHgbcg/rZyNYNS5NyNqA8pjsixhCtsUJhkTk+cA=";

  env.PROTOC = lib.getExe protobuf;

  nativeBuildInputs = [
    protobuf
    pkg-config
  ];

  buildInputs = [
    aws-lc
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    inherit (seaweedfs.meta) homepage license;

    description = "weed-volume is a drop-in replacement for SeaweedFS's Go volume server";
    maintainers = with lib.maintainers; [ alemonmk ];
    mainProgram = "weed-volume";
  };
})
