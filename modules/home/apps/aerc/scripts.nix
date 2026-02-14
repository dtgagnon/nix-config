# Extra scripts and utilities for aerc
{
  pkgs,
  config,
  namespace,
}:
let
  mailCfg = config.${namespace}.services.mail;
  homeDir = config.home.homeDirectory;
  mailDir = "${homeDir}/${mailCfg.mailDir}";
in
{
  # Tag picker script for quick tag-based searches
  "${config.xdg.configHome}/aerc/scripts/tag-picker.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Tag picker for aerc - shows notmuch tags in fzf and performs search

      # Get all unique tags from notmuch, excluding system tags
      TAGS=$(${pkgs.notmuch}/bin/notmuch search --output=tags '*' | \
             grep -v '^attachment$' | \
             grep -v '^encrypted$' | \
             grep -v '^signed$' | \
             grep -v '^replied$' | \
             grep -v '^passed$' | \
             sort -u)

      # Let user pick a tag with fzf (using /dev/tty for input)
      SELECTED=$(echo "$TAGS" | ${pkgs.fzf}/bin/fzf \
        --prompt="Search tag: " \
        --height=40% \
        --reverse \
        --border \
        --preview='${pkgs.notmuch}/bin/notmuch count tag:{}' \
        --preview-label='Message count' \
        < /dev/tty > /dev/tty 2>&1)

      # If a tag was selected, output the aerc search command
      if [ -n "$SELECTED" ]; then
        echo ":search tag:$SELECTED"
      fi
    '';
  };

  # Folder picker script for quick folder navigation
  "${config.xdg.configHome}/aerc/scripts/folder-picker.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Folder picker for aerc - shows all folders in fzf and changes to selected

      # Get all folders from notmuch
      FOLDERS=$(${pkgs.notmuch}/bin/notmuch search --output=tags 'tag:*' | \
                grep '^folder/' | \
                sed 's|^folder/||' | \
                sort -u)

      # Let user pick a folder with fzf (using /dev/tty for input)
      SELECTED=$(echo "$FOLDERS" | ${pkgs.fzf}/bin/fzf \
        --prompt="Go to folder: " \
        --height=40% \
        --reverse \
        --border \
        --preview='${pkgs.notmuch}/bin/notmuch count folder:{}' \
        --preview-label='Message count' \
        < /dev/tty > /dev/tty 2>&1)

      # If a folder was selected, output the aerc change folder command
      if [ -n "$SELECTED" ]; then
        echo ":cf $SELECTED"
      fi
    '';
  };
}
