# OpenCode for Nix/NixOS

OpenCode - AI coding agent built for the terminal, packaged for NixOS and Nix users.

## About

This flake provides OpenCode v2.2.6 from the binaries published in the GitHub releases.

- **Version**: 2.2.6
- **Source**: GitHub releases of anomalyco/opencode (`opencode-linux-x64.tar.gz`, `opencode-darwin-arm64.zip`, etc.). Since v2 the npm platform packages are no longer updated (they stop at 1.19.5).
- **License**: MIT
- **Homepage**: https://opencode.ai

## Important Notes

⚠️ **Special Packaging Requirements**

This package uses a Bun-based binary that requires special handling:

- `autoPatchelfHook` and `strip` are **disabled** to prevent binary corruption
- Only the ELF interpreter is manually patched using `patchelf` (Linux only)
- See `docs/custom-package-troubleshooting.md` for details

## MCP Support

OpenCode includes native MCP (Model Context Protocol) CLI commands:

```bash
opencode mcp add [name]     # add an MCP server
opencode mcp list           # list MCP servers
opencode mcp auth [name]    # authenticate with OAuth
opencode mcp logout [name]  # remove OAuth credentials
opencode mcp debug <name>   # debug connection
```

You can also configure MCP servers declaratively via the home-manager module:

```nix
programs.opencode = {
  enable = true;
  mcpServers = {
    filesystem = {
      type = "local";
      command = [ "npx" "-y" "@modelcontextprotocol/server-filesystem" "/home/user/docs" ];
    };
    context7 = {
      type = "remote";
      url = "https://mcp.context7.com/mcp";
      headers = { CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}"; };
    };
  };
};
```

## Usage

### With Flakes (basic)

Add to your `flake.nix`:

```nix
{
  inputs = {
    opencode.url = "github:GutMutCode/opencode-nix";
  };

  outputs = { self, nixpkgs, opencode, ... }: {
    nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
      modules = [
        {
          nixpkgs.overlays = [ opencode.overlays.default ];
          home-manager.users.your-user = {
            programs.opencode = {
              enable = true;

              # MCP servers (manual)
              mcpServers = {
                filesystem = {
                  type = "local";
                  command = [ "npx" "-y" "@modelcontextprotocol/server-filesystem" "/tmp" ];
                };
                context7 = {
                  type = "remote";
                  url = "https://mcp.context7.com/mcp";
                  headers = { CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}"; };
                };
              };

              # General settings
              settings = {
                model = "anthropic/claude-sonnet-4-20250514";
                autoupdate = true;
              };

              # TUI config
              tui = {
                theme = "system";
              };

              # Add tools to PATH
              extraPackages = [ pkgs.uv ];

              # Global context (AGENTS.md)
              context = ''
                # Project Rules
                - Always write tests
                - Use TypeScript strict mode
              '';
            };
          };
        }
      ];
    };
  };
}
```

### With Flakes + mcp-servers-nix (recommended)

Use [mcp-servers-nix](https://github.com/natsukium/mcp-servers-nix) for 25+ pre-configured MCP servers:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    opencode.url = "github:GutMutCode/opencode-nix";
    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
  };

  outputs = { self, nixpkgs, home-manager, opencode, mcp-servers-nix, ... }: {
    nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
      modules = [
        home-manager.nixosModules.home-manager
        {
          nixpkgs.overlays = [ opencode.overlays.default ];
          home-manager.users.your-user = { pkgs, ... }: {
            home.stateVersion = "25.11";

            # Import modules
            imports = [
              opencode.homeManagerModules.default
              mcp-servers-nix.homeManagerModules.default
            ];

            # Define MCP servers once, share across all tools
            mcp-servers.programs = {
              filesystem = {
                enable = true;
                args = [ "/home/user/documents" ];
              };
              context7.enable = true;
              playwright.enable = true;
              github.enable = true;
              fetch.enable = true;
            };

            # Enable centralized MCP infrastructure
            programs.mcp.enable = true;

            # Each tool consumes MCP servers via enableMcpIntegration
            programs.opencode = {
              enable = true;
              enableMcpIntegration = true;
              settings.model = "anthropic/claude-sonnet-4-20250514";
            };

            # Works with other tools too
            programs.claude-code = {
              enable = true;
              enableMcpIntegration = true;
            };
          };
        }
      ];
    };
  };
}
```

**Available servers in mcp-servers-nix:**
`clickup`, `codex`, `context7`, `deepl`, `esa`, `everything`, `fetch`, `filesystem`, `freee`, `git`, `github`, `grafana`, `home-assistant`, `mastra`, `memory`, `netdata`, `nixos`, `notion`, `playwright`, `sequential-thinking`, `serena`, `slite`, `tavily`, `terraform`, `textlint`, `time`

See [mcp-servers-nix modules](https://github.com/natsukium/mcp-servers-nix/tree/main/modules/servers) for each server's options.

### Direct Installation

```bash
nix profile install github:GutMutCode/opencode-nix
```

### Run Without Installing

```bash
nix run github:GutMutCode/opencode-nix
```

## Module Options

| Option                                   | Type        | Default         | Description                                                                                                        |
| ---------------------------------------- | ----------- | --------------- | ------------------------------------------------------------------------------------------------------------------ |
| `programs.opencode.enable`               | bool        | `false`         | Enable OpenCode                                                                                                    |
| `programs.opencode.package`              | package     | `pkgs.opencode` | Package to use                                                                                                     |
| `programs.opencode.extraPackages`        | list        | `[]`            | Extra packages in PATH                                                                                             |
| `programs.opencode.enableMcpIntegration` | bool        | `false`         | Integrate with `programs.mcp.servers` (works with [mcp-servers-nix](https://github.com/natsukium/mcp-servers-nix)) |
| `programs.opencode.mcpServers`           | attrs       | `{}`            | MCP server definitions                                                                                             |
| `programs.opencode.settings`             | attrs       | `{}`            | opencode.json config                                                                                               |
| `programs.opencode.tui`                  | attrs       | `{}`            | tui.json config                                                                                                    |
| `programs.opencode.context`              | string/path | `""`            | AGENTS.md content                                                                                                  |
| `programs.opencode.commands`             | attrs/path  | `{}`            | Custom commands                                                                                                    |
| `programs.opencode.agents`               | attrs/path  | `{}`            | Custom agents                                                                                                      |
| `programs.opencode.skills`               | attrs/path  | `{}`            | Custom skills                                                                                                      |
| `programs.opencode.themes`               | attrs/path  | `{}`            | Custom themes                                                                                                      |
| `programs.opencode.tools`                | attrs/path  | `{}`            | Custom tools                                                                                                       |
| `programs.opencode.web.enable`           | bool        | `false`         | Enable web service                                                                                                 |
| `programs.opencode.web.extraArgs`        | list        | `[]`            | Extra serve arguments                                                                                              |
| `programs.opencode.web.environmentFile`  | path/null   | `null`          | Environment file for web service                                                                                   |

### Deprecated

- `services.opencode.*` → Use `programs.opencode.*` instead (auto-migrated with warning)

## Verification

```bash
# Check version
opencode --version  # Should show: 2.2.6

# List available models
opencode models

# Run help
opencode --help

# List MCP commands
opencode mcp --help
```

## Building from Source

```bash
git clone https://github.com/GutMutCode/opencode-nix
cd opencode-nix
nix build
./result/bin/opencode --version
```

## Troubleshooting

If you see Bun help instead of OpenCode help, the binary may have been corrupted by build hooks. This package is specifically configured to avoid this issue. See the inline comments in `package.nix` for details.

## Updating

To update to a newer version:

1. Check the latest release: `gh release list --repo anomalyco/opencode --limit 5` (the release marked as Latest may be an older line, check the newest tags)
2. Update `version` in `package.nix`
3. Update the hashes. GitHub publishes the sha256 of each asset:
   ```bash
   gh api repos/anomalyco/opencode/releases/tags/vVERSION --jq '.assets[] | select(.name | test("^opencode-(linux|darwin)-(x64|arm64)\\.(tar\\.gz|zip)$")) | "\(.name) \(.digest)"'
   nix hash convert --hash-algo sha256 --to sri HEX_DIGEST
   ```
4. Build and check: `nix build .#opencode && ./result/bin/opencode --version`
5. Update the version in this README and in `overlay.nix`

## License

MIT (for both the packaging code and OpenCode itself)
