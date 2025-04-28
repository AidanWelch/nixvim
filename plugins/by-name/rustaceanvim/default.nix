{
  lib,
  helpers,
  config,
  pkgs,
  ...
}:
with lib;
lib.nixvim.plugins.mkNeovimPlugin {
  name = "rustaceanvim";

  maintainers = [ maintainers.GaetanLepage ];

  # TODO: introduced 2024-05-17, remove on 2024-02-17
  deprecateExtraOptions = true;
  optionsRenamedToSettings = import ./renamed-options.nix;

  dependencies = [ "rust-analyzer" ];
  imports = [
    # TODO: added 2025-04-07, remove after 25.05
    (lib.nixvim.mkRemovedPackageOptionModule {
      plugin = "godot";
      packageName = "rust-analyzer";
      oldPackageName = "rustAnalyzer";
    })
  ];

  settingsOptions = import ./settings-options.nix { inherit lib helpers pkgs; };

  settingsExample = {
    server = {
      standalone = false;
      cmd = [
        "rustup"
        "run"
        "nightly"
        "rust-analyzer"
      ];
      default_settings = {
        rust-analyzer = {
          inlayHints = {
            lifetimeElisionHints = {
              enable = "always";
            };
          };
          check = {
            command = "clippy";
          };
        };
      };
    };
  };

  callSetup = false;
  hasLuaConfig = false;
  extraConfig =
    cfg:
    mkMerge [
      {
        globals.rustaceanvim = cfg.settings;

        assertions = lib.nixvim.mkAssertions "plugins.rustaceanvim" {
          assertion = cfg.enable -> !config.plugins.lsp.servers.rust_analyzer.enable;
          message = ''
            Both `plugins.rustaceanvim.enable` and `plugins.lsp.servers.rust_analyzer.enable` are true.
            Disable one of them otherwise you will have multiple clients attached to each buffer.
          '';
        };

        # TODO: remove after 24.11
        warnings = lib.nixvim.mkWarnings "plugins.rustaceanvim" {
          when = hasAttrByPath [
            "settings"
            "server"
            "settings"
          ] cfg;
          message = ''
            The `settings.server.settings' option has been renamed to `settings.server.default_settings'.

            Note that if you supplied an attrset and not a function you need to set this attr set in:
              `settings.server.default_settings.rust-analyzer'.
          '';
        };
      }
      # If nvim-lspconfig is enabled:
      (mkIf config.plugins.lsp.enable {
        # Use the same `on_attach` callback as for the other LSP servers
        plugins.rustaceanvim.settings.server.on_attach = mkDefault ''
          function(client, bufnr)
            return _M.lspOnAttach(client, bufnr)
          end
        '';
      })
    ];
}
