final: prev:
{
  # OpenCode from the GitHub release assets (latest version 2.2.6)
  # The npm platform packages stopped at 1.19.5, v2 is only published on GitHub
  # See: docs/custom-package-troubleshooting.md for details on Bun binary packaging
  opencode = prev.callPackage ./package.nix { };
}
