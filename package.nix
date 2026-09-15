{ lib
, stdenv
, fetchurl
, patchelf ? null
, glibc ? null
}:

let
  # Platform and architecture detection for npm package names
  arch =
    if stdenv.hostPlatform.isAarch64 then "arm64"
    else if stdenv.hostPlatform.isx86_64 then "x64"
    else throw "Unsupported architecture for opencode";

  platform =
    if stdenv.hostPlatform.isLinux then "linux"
    else if stdenv.hostPlatform.isDarwin then "darwin"
    else throw "Unsupported OS for opencode";

  # Latest version
  version = "1.18.31";

  # SHA256 hashes for npm packages (nix base32 format)
  hashes = {
    x86_64-linux = "1shd2il7nczfn0i85dq1a44zcp266kf9d0vj7s90s0wb58jxm2bd";
    aarch64-linux = "1l35fjdzsz5a5ccr1if822rvrxlk74kbakbiwmy2ny62hacgqc4z";
    x86_64-darwin = "1sll8hs3i2xc6zrqcxy2x02b5iksl0czw836zyk4f7vz42hlmkyz";
    aarch64-darwin = "0wfnaymjyfd4j8qi975b0zmc8xvr8pyxs1aznqck82szfq39myp1";
  };

  # Fetch the platform-specific npm package
  src = fetchurl {
    url = "https://registry.npmjs.org/opencode-${platform}-${arch}/-/opencode-${platform}-${arch}-${version}.tgz";
    sha256 = hashes.${stdenv.hostPlatform.system};
  };
in
stdenv.mkDerivation {
  pname = "opencode";
  inherit version;
  inherit src;

  # Do NOT use autoPatchelfHook - it corrupts the Bun-based binary
  nativeBuildInputs = lib.optional stdenv.hostPlatform.isLinux patchelf;

  # npm tarballs have a 'package' directory
  sourceRoot = "package";

  # Disable all default fixup phases that might corrupt the binary
  dontStrip = true;
  dontPatchELF = true;
  dontPatchShebangs = true;

  installPhase = ''
    runHook preInstall

    # Install binary
    install -Dm755 bin/opencode $out/bin/opencode

    ${lib.optionalString stdenv.hostPlatform.isLinux ''
    # Only patch the interpreter on Linux, nothing else
    patchelf --set-interpreter ${glibc}/lib/ld-linux-x86-64.so.2 $out/bin/opencode
    ''}

    runHook postInstall
  '';

  meta = with lib; {
    description = "AI coding agent built for the terminal (latest version from npm)";
    homepage = "https://opencode.ai";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = [ ];
    mainProgram = "opencode";
  };
}
