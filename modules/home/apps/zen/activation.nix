# Zen Browser activation scripts for user-overrides.js management
{ lib, localOverridesPath, profileFullPath }:
{
  # Create template user-overrides.js file if it doesn't exist
  createZenOverridesTemplate = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    OVERRIDES_FILE="${localOverridesPath}"
    OVERRIDES_DIR=$(dirname "$OVERRIDES_FILE")

    if [ ! -f "$OVERRIDES_FILE" ]; then
      $DRY_RUN_CMD mkdir -p "$OVERRIDES_DIR"
      $DRY_RUN_CMD tee "$OVERRIDES_FILE" > /dev/null <<'EOF'
// Zen Browser Local Overrides
// Location: ~/.config/zen/user-overrides.js
//
// This file is preserved across rebuilds and can be edited directly.
// Preferences here will be appended to your profile's user.js on each rebuild.
//
// Add your custom preferences using the format:
//   user_pref("preference.name", value);
//
// These preferences override any declarative settings from Nix.

// Your custom preferences below:

EOF
      $DRY_RUN_CMD chmod 600 "$OVERRIDES_FILE"
      $VERBOSE_ECHO "Created Zen Browser local overrides file at $OVERRIDES_FILE"
    fi
  '';

  # Append user-overrides.js to profile's user.js at activation time
  applyZenOverrides = lib.hm.dag.entryAfter [ "linkGeneration" "createZenOverridesTemplate" ] ''
    OVERRIDES_FILE="${localOverridesPath}"
    PROFILE_USER_JS="${profileFullPath}/user.js"
    PROFILE_DIR="${profileFullPath}"

    # Create profile directory if it doesn't exist
    $DRY_RUN_CMD mkdir -p "$PROFILE_DIR"

    # Get the base content (either from nix-store symlink or existing file)
    BASE_CONTENT=""
    if [ -L "$PROFILE_USER_JS" ]; then
      # It's a symlink (from home-manager/nix store) - read and remove it
      $VERBOSE_ECHO "Reading declarative user.js from nix store"
      BASE_CONTENT=$(cat "$PROFILE_USER_JS")
      $DRY_RUN_CMD rm "$PROFILE_USER_JS"
    elif [ -f "$PROFILE_USER_JS" ]; then
      # Regular file exists - read content, stripping old overrides
      BASE_CONTENT=$(sed '/^\/\/ BEGIN LOCAL OVERRIDES/,/^\/\/ END LOCAL OVERRIDES/d' "$PROFILE_USER_JS")
    fi

    # Build the new user.js with base content + overrides
    if [ -f "$OVERRIDES_FILE" ] && [ -s "$OVERRIDES_FILE" ]; then
      $VERBOSE_ECHO "Applying local overrides from $OVERRIDES_FILE"

      $DRY_RUN_CMD tee "$PROFILE_USER_JS" > /dev/null <<EOF
// Zen Browser User Preferences
// Base configuration from Nix/Stylix (if any)
$BASE_CONTENT

// BEGIN LOCAL OVERRIDES (from ~/.config/zen/user-overrides.js)
// These settings take precedence over declarative config above
$(cat "$OVERRIDES_FILE")
// END LOCAL OVERRIDES
EOF
      $DRY_RUN_CMD chmod 600 "$PROFILE_USER_JS"
      $VERBOSE_ECHO "✓ Zen Browser user.js created with local overrides"
    elif [ -n "$BASE_CONTENT" ]; then
      # No overrides file, but we have base content - restore it as regular file
      $VERBOSE_ECHO "Restoring declarative user.js (no local overrides found)"
      $DRY_RUN_CMD tee "$PROFILE_USER_JS" > /dev/null <<EOF
$BASE_CONTENT
EOF
      $DRY_RUN_CMD chmod 600 "$PROFILE_USER_JS"
    else
      $VERBOSE_ECHO "No user.js configuration (declarative or local)"
    fi
  '';
}
