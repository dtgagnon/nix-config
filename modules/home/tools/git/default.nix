{ lib
, config
, namespace
, ...
}:

let
  inherit (lib) types mkEnableOption mkIf;
  inherit (lib.${namespace}) mkOpt enabled;
  cfg = config.${namespace}.tools.git;
  user = config.${namespace}.user;
in
{

  options.${namespace}.tools.git = {
    enable = mkEnableOption "Git";
    userName = mkOpt types.str user.name "The name to configure git with.";
    userEmail = mkOpt types.str user.email "The email to configure git with.";
    signingKey = mkOpt types.str "/home/dtgagnon/.ssh/${user.name}-key.pub" "The key ID to sign commits with.";
    signByDefault = mkOpt types.bool true "Whether to sign commits by default.";
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      inherit (cfg) userName userEmail;
      lfs = enabled;

      signing = {
        key = cfg.signingKey;
        inherit (cfg) signByDefault;
      };

      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        core = {
          whitespace = "trailing-space,space-before-tab";
        };
        url = {
          "ssh://git@github.com".insteadOf = "https://github.com";
          "ssh://git@gitlab.com".insteadOf = "https://gitlab.com";
        };
        commit.gpgsign = true;
        gpg.format = "ssh";
        user.signing.key = "${cfg.signingKey}";
      };
    };
    programs.ssh = {
      matchBlocks = {
        "git" = {
          host = "github.com gitlab.com";
          user = "git";
          forwardAgent = true;
          identitiesOnly = true;
          identityFile = "$HOME/.ssh/${user.name}-key";
        };
      };
    };
  };
}
