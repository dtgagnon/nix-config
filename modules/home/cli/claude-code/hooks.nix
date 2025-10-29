{ lib, config, namespace, ... }:
{
  programs.claude-code.hooks = {
    post-commit = ''
      #!/usr/bin/env bash
      echo "Committed with message: $1"
    '';
    pre-edit = ''
      #!/usr/bin/env bash
      echo "About to edit file: $1"
    '';
  };
}
