{
  lib,
  rustPlatform,
  seaweedfs,
  pkg-config,
  protobuf,
  aws-lc,
  zstd,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  inherit (seaweedfs) version src;
  __structuredAttrs = true;

  pname = "seaweedfs-worker";

  sourceRoot = "${finalAttrs.src.name}/seaweed-worker";

  cargoHash = "sha256-XHr6iOtoAQJzt+/RXSjHplq924WzmM4YSqx+VBBvVU8=";

  env.PROTOC = lib.getExe protobuf;

  nativeBuildInputs = [
    protobuf
    pkg-config
  ];

  buildInputs = [
    aws-lc
    zstd
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    inherit (seaweedfs.meta) homepage license;

    description = "Cluster maintenance job worker of Seaweedfs.";
    maintainers = with lib.maintainers; [ alemonmk ];
    mainProgram = "weed-worker";
  };
})
