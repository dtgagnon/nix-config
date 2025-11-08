{ lib
, pkgs
, claude-desktop
, ...
}:

let
  # Stub implementation for claude-native module (from original derivation)
  claudeNativeStub = ''
    // Stub implementation of claude-native using KeyboardKey enum values
    const KeyboardKey = {
      Backspace: 43, Tab: 280, Enter: 261, Shift: 272, Control: 61, Alt: 40,
      CapsLock: 56, Escape: 85, Space: 276, PageUp: 251, PageDown: 250,
      End: 83, Home: 154, LeftArrow: 175, UpArrow: 282, RightArrow: 262,
      DownArrow: 81, Delete: 79, Meta: 187
    };
    Object.freeze(KeyboardKey);
    module.exports = {
      getWindowsVersion: () => "10.0.0",
      setWindowEffect: () => {},
      removeWindowEffect: () => {},
      getIsMaximized: () => false,
      flashFrame: () => {},
      clearFlashFrame: () => {},
      showNotification: () => {},
      setProgressBar: () => {},
      clearProgressBar: () => {},
      setOverlayIcon: () => {},
      clearOverlayIcon: () => {},
      KeyboardKey
    };
  '';
in
# Patched version of claude-desktop that adds --quick-input CLI flag support
# for triggering the quick input overlay on Wayland/Hyprland
claude-desktop.overrideAttrs (oldAttrs: {
  pname = "claude-desktop-patched";

  buildPhase = ''
    runHook preBuild

    # Replace the Windows-specific claude-native module with a stub
    if [ -d ./app/node_modules/claude-native ]; then
      echo "Replacing claude-native module with Linux stub..."
      rm -rf ./app/node_modules/claude-native/*.node
      cat > ./app/node_modules/claude-native/index.js << 'EOF'
${claudeNativeStub}
EOF
    fi

    # Fix the title bar detection (from aaddrick script)
    echo "Fixing title bar detection..."
    SEARCH_BASE="./app/.vite/renderer/main_window/assets"
    if [ -d "$SEARCH_BASE" ]; then
      TARGET_FILE=$(find "$SEARCH_BASE" -type f -name "MainWindowPage-*.js" | head -1)
      if [ -n "$TARGET_FILE" ]; then
        echo "Found target file: $TARGET_FILE"
        sed -i -E 's/if\(!([a-zA-Z]+)[[:space:]]*&&[[:space:]]*([a-zA-Z]+)\)/if(\1 \&\& \2)/g' "$TARGET_FILE"
        echo "Title bar fix applied"
      fi
    fi

    # PATCH: Add --quick-input CLI flag support
    echo "Adding --quick-input CLI flag support..."
    cat > /tmp/quick-input-patch.js << 'EOF'
// Quick Input Trigger Patch for Wayland/Hyprland
if (process.argv.includes('--quick-input')) {
  const { BrowserWindow, app } = require('electron');

  app.whenReady().then(() => {
    setTimeout(() => {
      const windows = BrowserWindow.getAllWindows();
      // Quick window dimensions: 320x54 + padding (8*2) = 336x70
      const quickWindow = windows.find(w => {
        const bounds = w.getBounds();
        return bounds.width === 336 && bounds.height === 70;
      });

      if (quickWindow && !quickWindow.isDestroyed()) {
        quickWindow.show();
        quickWindow.focus();
      }
    }, 2000);
  });
}

EOF

    # Prepend patch to index.pre.js (main entry point)
    if [ -f ./app/.vite/build/index.pre.js ]; then
      cat /tmp/quick-input-patch.js ./app/.vite/build/index.pre.js > /tmp/patched-index.pre.js
      mv /tmp/patched-index.pre.js ./app/.vite/build/index.pre.js
      echo "Quick input CLI flag patch applied to index.pre.js"
    else
      echo "WARNING: index.pre.js not found, quick input patch not applied"
    fi

    runHook postBuild
  '';

  meta = oldAttrs.meta // {
    description = oldAttrs.meta.description + " (patched with --quick-input support for Wayland)";
  };
})
