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

    # PATCH: Add --quick-input CLI flag support with custom quick window
    echo "Adding --quick-input CLI flag support..."
    cat > /tmp/quick-input-patch.js << 'EOF'
// Quick Input Patch for Wayland/Hyprland - Custom Implementation
if (process.argv.includes('--quick-input')) {
  const { BrowserWindow, app, ipcMain } = require('electron');

  app.whenReady().then(() => {
    // Create custom quick input window
    const quickWin = new BrowserWindow({
      width: 336,
      height: 70,
      frame: false,
      transparent: true,
      skipTaskbar: true,
      resizable: false,
      alwaysOnTop: true,
      webPreferences: {
        nodeIntegration: false,
        contextIsolation: true
      }
    });

    // Load simple HTML
    quickWin.loadURL('data:text/html;charset=utf-8,' + encodeURIComponent(`
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body {
            width: 320px;
            height: 54px;
            padding: 8px;
            font-family: system-ui, -apple-system, sans-serif;
            background: rgba(30, 30, 30, 0.95);
            border-radius: 8px;
          }
          input {
            width: 100%;
            height: 100%;
            padding: 12px;
            border: none;
            border-radius: 6px;
            background: rgba(50, 50, 50, 0.8);
            color: #fff;
            font-size: 14px;
            outline: none;
          }
          input:focus {
            background: rgba(60, 60, 60, 0.9);
          }
        </style>
      </head>
      <body>
        <input type="text" placeholder="Ask Claude..." autofocus />
        <script>
          const input = document.querySelector('input');
          input.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
              window.close();
            }
          });
        </script>
      </body>
      </html>
    `));

    quickWin.show();
    quickWin.focus();

    // Close when focus is lost
    quickWin.on('blur', () => {
      quickWin.close();
    });
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
