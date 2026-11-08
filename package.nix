{ lib
, stdenv
, fetchurl
, patchelf
, unzip
}:

let
  # Platform and architecture detection for the GitHub release asset names
  arch =
    if stdenv.hostPlatform.isAarch64 then "arm64"
    else if stdenv.hostPlatform.isx86_64 then "x64"
    else throw "Unsupported architecture for opencode";

  platform =
    if stdenv.hostPlatform.isLinux then "linux"
    else if stdenv.hostPlatform.isDarwin then "darwin"
    else throw "Unsupported OS for opencode";

  # Linux ships a .tar.gz, macOS a .zip. Both contain a single `opencode` binary.
  extension = if stdenv.hostPlatform.isDarwin then "zip" else "tar.gz";

  # Latest version. Since v2 it is only published as GitHub release assets,
  # the npm platform packages stopped at 1.19.5.
  version = "2.2.6";

  # SRI hashes of the release assets
  # (sha256 digests published by GitHub, converted with `nix hash convert --to sri`)
  hashes = {
    x86_64-linux = "sha256-CLsh1jJs50DZHM5+voimU2kz9uHjA1O5GgawHyXaMGw=";
    aarch64-linux = "sha256-8tJ2AMNn5FBX1qFvalwqqNd7QamxDUvD2EnC+Ihw6UQ=";
    x86_64-darwin = "sha256-spYtxEXYc99Wrn07p+ZlArBGu8Ta+oIOyhjQMDqYopw=";
    aarch64-darwin = "sha256-FUkWCPawvE3r5erDXqtimisH6pofusaK1TvOpZ/MS0U=";
  };

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-${platform}-${arch}.${extension}";
    hash = hashes.${stdenv.hostPlatform.system};
  };
in
stdenv.mkDerivation {
  pname = "opencode";
  inherit version;
  inherit src;

  # Do NOT use autoPatchelfHook - it corrupts the Bun-based binary
  nativeBuildInputs =
    lib.optional stdenv.hostPlatform.isLinux patchelf
    ++ lib.optional stdenv.hostPlatform.isDarwin unzip;

  # The archive holds a single file and no directory, so there is nothing to unpack into
  dontUnpack = true;

  # Disable all default fixup phases that might corrupt the binary
  dontStrip = true;
  dontPatchELF = true;
  dontPatchShebangs = true;

  installPhase = ''
    runHook preInstall

    mkdir extracted
    cd extracted
    ${if stdenv.hostPlatform.isDarwin then "unzip -q $src" else "tar -xzf $src"}

    install -Dm755 opencode $out/bin/opencode

    ${lib.optionalString stdenv.hostPlatform.isLinux ''
    # Only patch the interpreter on Linux, nothing else
    patchelf --set-interpreter "$(cat ${stdenv.cc}/nix-support/dynamic-linker)" $out/bin/opencode
    ''}

    runHook postInstall
  '';

  meta = with lib; {
    description = "AI coding agent built for the terminal (latest release from GitHub)";
    homepage = "https://opencode.ai";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = [ ];
    mainProgram = "opencode";
  };
}
