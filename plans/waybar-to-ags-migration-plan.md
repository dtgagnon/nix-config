# Waybar to AGS Migration Plan

_Created: 2025-05-03_

This document outlines a comprehensive plan to convert the Hyprland bar from Waybar to AGS (Aylur's GTK Shell), replicating the current appearance and functionality while adhering to current best practices.

## 1. Current Status Analysis

### Waybar Configuration
The current waybar setup uses a "top-isolated-islands-centeredWorkspaces" layout with:
- **Left section**: Utilities, hardware monitoring, audio controls
- **Center section**: Split workspaces (odds/evens) with custom icons
- **Right section**: Notifications, system tray, calendar, clock

### Existing AGS Structure
There is an existing `/modules/home/desktop/addons/ags/bar` structure with a Nix module setup for AGS, but the implementation needs to be started from scratch using current best practices.

## 2. Implementation Plan

### 2.1 Structure for AGS Configuration

```
nixos/modules/home/desktop/addons/ags/bar/
├── default.nix        # Already exists
└── src/
    ├── config.ts     # Main config entry point
    ├── lib/          # Utility functions
    ├── modules/      # Individual widget modules
    │   ├── workspaces.ts
    │   ├── clock.ts
    │   ├── calendar.ts
    │   ├── system.ts   # CPU, memory, temp
    │   ├── network.ts
    │   └── audio.ts
    ├── widgets/     # Widget composition
    │   ├── left.ts     # Left section modules
    │   ├── center.ts   # Center section modules
    │   └── right.ts    # Right section modules
    ├── types/       # TypeScript type definitions
    │   └── index.ts    # Exported types and interfaces
    └── sass/
        ├── index.scss
        └── _variables.scss
```

### 2.2 Detailed Implementation Tasks

1. **Core Configuration**
   - Create base `config.ts` to initialize the bar
   - Setup proper TypeScript module structure with type definitions
   - Create utility functions for formatting and icons

2. **Workspace Module**
   - Implement Hyprland workspace monitoring via IPC
   - Create the split odd/even workspace display
   - Implement the same icon set as current waybar
   - Ensure proper workspace navigation on click

3. **System Information Modules**
   - Create CPU usage monitor with percentage display
   - Implement memory usage widget with GB formatting
   - Develop temperature monitor with critical threshold warning
   - Build network widget with connection type indication

4. **Date and Time Modules**
   - Clock with custom format matching waybar (`%I:%M<small>%p</small>`)
   - Calendar widget with month view and interactive navigation
   - Match styling and formatting from waybar

5. **Audio Module**
   - PulseAudio/PipeWire integration
   - Volume percentage display
   - Device type indication with proper icons
   - Mute state handling

6. **Additional Widgets**
   - System tray implementation
   - Notification module
   - Custom exit button
   - Music player integration

7. **Styling**
   - Create SCSS files to match current waybar styling
   - Implement proper font configuration
   - Design modular component styling with variables
   - Ensure consistent spacing and alignment

### 2.3 Technical Implementation Notes

#### Core Bar Setup
```typescript
// config.ts
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import App from 'resource:///com/github/Aylur/ags/app.js';
import { Left } from './widgets/left';
import { Center } from './widgets/center';
import { Right } from './widgets/right';
import { BarConfig } from './types';
import './sass/index.scss';

const Bar = (): Widget => Widget.Window({
  name: 'bar',
  anchor: ['top', 'left', 'right'],
  exclusive: true,
  child: Widget.CenterBox({
    startWidget: Left(),
    centerWidget: Center(),
    endWidget: Right(),
  }),
});

const config: BarConfig = {
  style: './css/index.css',
  windows: [Bar()],
};

export default config;
```

#### Workspace Implementation
```typescript
// modules/workspaces.ts
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';
import { spanWrapIcon } from '../lib/formatting';
import { WorkspaceInfo } from '../types';

/**
 * Get the appropriate icon for a workspace based on its ID
 */
const getIconForWorkspace = (id: number): string => {
  // Implementation details here
  return ''; // Placeholder
};

export const OddWorkspaces = (): Widget => {
  const workspaceButton = (id: number): Widget => Widget.Button({
    onClicked: () => Hyprland.sendMessage(`dispatch workspace ${id}`),
    child: Widget.Label({
      label: spanWrapIcon(getIconForWorkspace(id)),
    }),
    className: Hyprland.active.workspace.bind().transform((ws: WorkspaceInfo) => 
      ws.id === id ? 'workspace-button active' : 'workspace-button'),
  });

  return Widget.Box({
    className: 'workspaces odds',
    children: [1, 3, 5, 7, 9].map(workspaceButton),
  });
};

// Similar implementation for EvenWorkspaces
```

## 3. Nix Integration

### 3.1 Flake Configuration

The development environment will be managed through the existing Nix flake with TypeScript support:

```nix
# In flake.nix
inputs = {
  # ... existing inputs
  ags.url = "github:Aylur/ags";
};

outputs = { self, nixpkgs, ags, ... }: {
  # ... existing outputs
  devShells.${system}.default = pkgs.mkShell {
    buildInputs = with pkgs; [
      nodejs
      nodePackages.typescript
      nodePackages.typescript-language-server
      ags.packages.${system}.default
    ];
  };
};
```

### 3.2 Development Environment

The development environment will use direnv to automatically load the Nix flake environment:

```shell
# .envrc in the ags development directory
use flake
# TypeScript environment will be loaded from the flake
```

### 3.3 Module Configuration

The existing module will be updated to support the new implementation:

```nix
# Updated default.nix
{
  options.${namespace}.desktop.addons.ags.bar = {
    enable = mkBoolOpt false "AGS Bar";
    package = mkOpt types.package inputs.ags.packages.${system}.default "The package to use for AGS";
    # Add additional configuration options as needed
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    spirenix = {
      desktop.hyprland.extraConfig = {
        exec-once = [ "${getExe cfg.package} --config ${bar}/config.ts" ];
      };
    };
  };
}
```

## 4. TypeScript Setup

1. **TypeScript Configuration**
   - Create `tsconfig.json` file in the project root
   - Configure module resolution for AGS imports
   - Setup type checking and compilation options

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "node",
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true,
    "strict": true,
    "noImplicitAny": true,
    "outDir": "dist",
    "baseUrl": ".",
    "paths": {
      "resource:///com/github/Aylur/ags/*": ["./node_modules/@types/ags/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
```

2. **Types Directory Structure**
   - Create type definitions for all components
   - Define interfaces for widget properties
   - Add type declarations for AGS modules

```typescript
// types/index.ts
export interface BarConfig {
  style: string;
  windows: Array<any>; // Replace with proper type once available
}

export interface WorkspaceInfo {
  id: number;
  name: string;
  monitor: string;
  windows: number;
  // Add other properties as needed
}
```

## 5. Testing and Validation

1. **Component Testing**
   - Test each module independently
   - Verify proper data binding and updates
   - Ensure consistent styling with waybar

2. **Integration Testing**
   - Test the full bar with all components
   - Check for layout and spacing consistency
   - Verify proper event handling

3. **Visual Comparison**
   - Side-by-side comparison with current waybar
   - Check for any styling or layout differences
   - Ensure font rendering is consistent

## 5. Migration Plan

1. **Development Phase**
   - Implement all components according to plan
   - Test thoroughly in isolation

2. **Integration Phase**
   - Update the Nix module to include new components
   - Test with Hyprland

3. **Deployment**
   - Update system configuration to switch from waybar to AGS
   - Enable the new bar module and disable waybar

```nix
# Example configuration update
{
  spirenix.desktop.addons = {
    waybar.enable = false;
    ags.bar.enable = true;
  };
}
```

## 6. Future Enhancements

- Add animations and transitions
- Implement additional customization options
- Create themes support for easy styling changes
- Add configuration options for module positioning

---

This plan provides a structured approach to migrate from Waybar to AGS while maintaining the current look and feel, with room for future improvements and customizations.
