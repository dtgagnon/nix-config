{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.bat;
in {
  options.${namespace}.cli.bat = {
    enable = mkBoolOpt false "Whether or not to enable bat";
  };

  config = mkIf cfg.enable {
    programs.bat = {
      enable = true;
      config = {
        # theme = "TwoDark";  # A popular theme that works well with most color schemes
        style = "numbers,changes,header";  # Show line numbers, Git changes and file headers
        pager = "less -FR";  # Use less as the pager with proper color support
      };
      # You can uncomment and customize these if needed
      # extraPackages = with pkgs.bat-extras; [
      #   batdiff     # Diff tool
      #   batman      # Man page viewer
      #   batgrep     # Grep with syntax highlighting
      #   batwatch    # Watch files for changes
      # ];
    };
  };
}
