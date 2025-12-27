{ lib
, config
, inputs
, system
, namespace
, pkgs
, ...
}:
let
  inherit (lib) mkMerge mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.sysbar.quickshell;
in
{
  options.${namespace}.desktop.addons.sysbar.quickshell = {
    enable = mkBoolOpt false "Whether to enable Quickshell in the desktop environment";
    premade = mkOpt (types.nullOr types.str) null "Declare the name of a prebuilt quickshell configuration to use";
  };

  config = mkMerge [
    {
      assertions = [
        {
          assertion = cfg.premade != null -> cfg.enable;
          message = "spirenix: `premade` is set to `${cfg.premade}`, but `enable` is false. You must set `enable = true` to use premade configs.";
        }
      ];
    }
    (mkIf (cfg.enable && cfg.premade == null) {
      home.packages = [
        inputs.quickshell.packages.${system}.default
        # Ensure Qt6 Wayland support is available
        pkgs.kdePackages.qtwayland
      ];

      # Install template shell configuration
      xdg.configFile."quickshell/shell.qml".source = ./shell.qml;

      # Desktop entry for xdg-desktop-portal integration
      xdg.dataFile."applications/org.quickshell.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Quickshell
        Comment=QtQuick-based Wayland compositor shell
        Exec=quickshell
        Icon=application-x-executable
        Terminal=false
        Categories=System;
        NoDisplay=true
      '';
    })
    (mkIf (cfg.premade == "noctalia-shell") {
      programs.noctalia-shell = {
        enable = true;
        systemd.enable = true;
        settings = {
          bar = {
            position = "left";
            monitors = [ ];
            density = "default";
            transparent = false;
            showOutline = false;
            showCapsule = true;
            capsuleOpacity = 1;
            floating = false;
            marginVertical = 0.25;
            marginHorizontal = 0.25;
            outerCorners = true;
            exclusive = true;
            widgets = {
              left = [
                {
                  id = "SystemMonitor";
                  diskPath = "/";
                  showCpuTemp = true;
                  showCpuUsage = true;
                  showDiskUsage = false;
                  showGpuTemp = true;
                  showMemorAsPercent = false;
                  showMemoryUsage = true;
                  showNetworkStats = false;
                  usePrimaryColor = false;
                }
                {
                  id = "MediaMini";
                  hideMode = "hidden";
                  hideWhenIdle = false;
                  maxWidth = 145;
                  scrollingMode = "hover";
                  showAlbumArt = true;
                  showArtistFirst = true;
                  showVisualizer = true;
                  visualizerType = "linear";
                  useFixedWidth = false;
                }
                {
                  id = "VPN";
                  displayMode = "onhover";
                }
              ];
              center = [
                # {
                #   id = "Taskbar";
                #   colorizeIcons = false;
                #   iconScale = 1;
                #   maxTaskbarWidth = 40;
                #   onlyActiveWorkspaces = true;
                #   onlySameOutput = true;
                #   showPinnedApps = true;
                #   showTitle = false;
                #   smartWidth = true;
                #   titleWidth = 120;
                # }
                {
                  id = "Workspace";
                  colorizeIcons = false;
                  enableScrollWheel = true;
                  hideUnoccupied = false;
                  followFocusedScreen = false;
                  labelMode = "icon";
                  showApplications = true;
                  showLabelsOnlyWhenOccupied = true;
                }
              ];
              right = [
                {
                  hideMode = "alwaysExpanded";
                  icon = "rocket";
                  id = "CustomButton";
                  leftClickExec = "qs -c noctalia-shell ipc call launcher toggle";
                  leftClickUpdateText = false;
                  maxTextLength = {
                    horizontal = 10;
                    vertical = 10;
                  };
                  middleClickExec = "";
                  middleClickUpdateText = false;
                  parseJson = false;
                  rightClickExec = "";
                  rightClickUpdateText = false;
                  showIcon = true;
                  textCollapse = "";
                  textCommand = "";
                  textIntervalMs = 3000;
                  textStream = false;
                  wheelDownExec = "";
                  wheelDownUpdateText = false;
                  wheelExec = "";
                  wheelMode = "unified";
                  wheelUpExec = "";
                  wheelUpUpdateText = false;
                  wheelUpdateText = false;
                }
                {
                  id = "Tray";
                  blacklist = [ ];
                  colorizeIcons = false;
                  drawerEnabled = true;
                  hidePassive = false;
                  pinned = [ ];
                }
                {
                  id = "NotificationHistory";
                  hideWhenZero = true;
                  showUnreadBadge = true;
                }
                {
                  id = "Volume";
                  displayMode = "onhover";
                }
                {
                  id = "Clock";
                  formatHorizontal = "HH:mm ddd, MMM dd";
                  formatVertical = "HH mm - ddd dd";
                  useCustomFont = false;
                  customFont = "";
                  usePrimaryColor = false;
                }
                {
                  id = "ControlCenter";
                  icon = "";
                  customIconPath = "";
                  enableColorization = false;
                  colorizeSystemIcon = "none";
                  colorizeDistroLogo = false;
                  useDistroLogo = true;
                }
              ];
            };
          };
          general = {
            avatarImage = "${config.home.homeDirectory}/Pictures/profile.png";
            dimmerOpacity = 0.2;
            showScreenCorners = false;
            forceBlackScreenCorners = false;
            scaleRatio = 1.25;
            radiusRatio = 1;
            iRadiusRatio = 1;
            boxRadiusRatio = 1;
            screenRadiusRatio = 1;
            animationSpeed = 1;
            animationDisabled = false;
            compactLockScreen = false;
            lockOnSuspend = true;
            showSessionButtonsOnLockScreen = true;
            showHibernateOnLockScreen = false;
            enableShadows = true;
            shadowDirection = "bottom_right";
            shadowOffsetX = 2;
            shadowOffsetY = 3;
            language = "";
            allowPanelsOnScreenWithoutBar = true;
          };
          ui = {
            fontDefault = config.${namespace}.desktop.styling.core.fonts.sansSerif.name;
            fontFixed = config.${namespace}.desktop.styling.core.fonts.monospace.name;
            fontDefaultScale = 1;
            fontFixedScale = 1;
            tooltipsEnabled = true;
            panelBackgroundOpacity = 0.85;
            panelsAttachedToBar = true;
            settingsPanelMode = "attached";
          };
          location = {
            name = "Ann Arbor";
            weatherEnabled = true;
            weatherShowEffects = true;
            useFahrenheit = true;
            use12hourFormat = true;
            showWeekNumberInCalendar = false;
            showCalendarEvents = true;
            showCalendarWeather = true;
            analogClockInCalendar = false;
            firstDayOfWeek = -1;
          };
          calendar = {
            cards = [
              {
                enabled = true;
                id = "calendar-header-card";
              }
              {
                enabled = true;
                id = "calendar-month-card";
              }
              {
                enabled = true;
                id = "timer-card";
              }
              {
                enabled = true;
                id = "weather-card";
              }
            ];
          };
          screenRecorder = {
            directory = "";
            frameRate = 60;
            audioCodec = "opus";
            videoCodec = "h264";
            quality = "very_high";
            colorRange = "limited";
            showCursor = true;
            audioSource = "default_output";
            videoSource = "portal";
          };
          wallpaper = {
            enabled = false;
            overviewEnabled = false;
            directory = "${config.home.homeDirectory}/Pictures/wallpapers";
            monitorDirectories = [ ];
            enableMultiMonitorDirectories = false;
            recursiveSearch = true;
            setWallpaperOnAllMonitors = true;
            fillMode = "fill";
            fillColor = "#000000";
            randomEnabled = false;
            randomIntervalSec = 300;
            transitionDuration = 1500;
            transitionType = "random";
            transitionEdgeSmoothness = 0.05;
            panelPosition = "follow_bar";
            hideWallpaperFilenames = false;
            useWallhaven = false;
            wallhavenQuery = "";
            wallhavenSorting = "relevance";
            wallhavenOrder = "desc";
            wallhavenCategories = "111";
            wallhavenPurity = "100";
            wallhavenRatios = "";
            wallhavenResolutionMode = "atleast";
            wallhavenResolutionWidth = "7680";
            wallhavenResolutionHeight = "2160";
          };
          appLauncher = {
            enableClipboardHistory = false;
            enableClipPreview = true;
            position = "center";
            pinnedExecs = [ ];
            useApp2Unit = false;
            sortByMostUsed = true;
            terminalCommand = "ghostty -e";
            customLaunchPrefixEnabled = false;
            customLaunchPrefix = "";
            viewMode = "list";
            showCategories = true;
            iconMode = "tabler";
          };
          controlCenter = {
            position = "close_to_bar_button";
            shortcuts = {
              left = [
                {
                  id = "WiFi";
                }
                {
                  id = "Bluetooth";
                }
                {
                  id = "ScreenRecorder";
                }
                {
                  id = "WallpaperSelector";
                }
              ];
              right = [
                {
                  id = "Notifications";
                }
                {
                  id = "PowerProfile";
                }
                {
                  id = "KeepAwake";
                }
                {
                  id = "NightLight";
                }
              ];
            };
            cards = [
              {
                enabled = true;
                id = "profile-card";
              }
              {
                enabled = true;
                id = "shortcuts-card";
              }
              {
                enabled = true;
                id = "audio-card";
              }
              {
                enabled = false;
                id = "brightness-card";
              }
              {
                enabled = true;
                id = "weather-card";
              }
              {
                enabled = true;
                id = "media-sysmon-card";
              }
            ];
          };
          systemMonitor = {
            cpuWarningThreshold = 80;
            cpuCriticalThreshold = 90;
            tempWarningThreshold = 80;
            tempCriticalThreshold = 90;
            gpuWarningThreshold = 80;
            gpuCriticalThreshold = 90;
            memWarningThreshold = 80;
            memCriticalThreshold = 90;
            diskWarningThreshold = 80;
            diskCriticalThreshold = 90;
            cpuPollingInterval = 3000;
            tempPollingInterval = 3000;
            gpuPollingInterval = 3000;
            enableNvidiaGpu = false;
            memPollingInterval = 3000;
            diskPollingInterval = 3000;
            networkPollingInterval = 3000;
            useCustomColors = false;
            warningColor = "";
            criticalColor = "";
          };
          dock = {
            enabled = true;
            displayMode = "auto_hide";
            backgroundOpacity = 1;
            floatingRatio = 1;
            size = 1;
            onlySameOutput = true;
            monitors = [ ];
            pinnedApps = [ ];
            colorizeIcons = false;
            pinnedStatic = false;
            inactiveIndicators = false;
            deadOpacity = 0.6;
            animationSpeed = 1;
          };
          network = {
            wifiEnabled = false;
          };
          sessionMenu = {
            enableCountdown = true;
            countdownDuration = 10000;
            position = "center";
            showHeader = true;
            largeButtonsStyle = false;
            powerOptions = [
              {
                action = "lock";
                enabled = true;
              }
              {
                action = "suspend";
                enabled = true;
              }
              {
                action = "hibernate";
                enabled = false;
              }
              {
                action = "reboot";
                enabled = true;
              }
              {
                action = "logout";
                enabled = true;
              }
              {
                action = "shutdown";
                enabled = true;
              }
            ];
          };
          notifications = {
            enabled = true;
            monitors = [ ];
            location = "bottom_left";
            overlayLayer = true;
            backgroundOpacity = 0.85;
            respectExpireTimeout = false;
            lowUrgencyDuration = 3;
            normalUrgencyDuration = 8;
            criticalUrgencyDuration = 15;
            enableKeyboardLayoutToast = true;
            sounds = {
              enabled = false;
              volume = 0.5;
              separateSounds = false;
              criticalSoundFile = "";
              normalSoundFile = "";
              lowSoundFile = "";
              excludedApps = "";
            };
          };
          osd = {
            enabled = true;
            location = "top_left";
            autoHideMs = 2000;
            overlayLayer = true;
            backgroundOpacity = 1;
            enabledTypes = [
              0
              1
              2
              4
            ];
            monitors = [ ];
          };
          audio = {
            volumeStep = 2;
            volumeOverdrive = false;
            cavaFrameRate = 30;
            visualizerType = "linear";
            mprisBlacklist = [ ];
            preferredPlayer = "";
            externalMixer = "pwvucontrol || pavucontrol";
          };
          brightness = {
            brightnessStep = 5;
            enforceMinimum = true;
            enableDdcSupport = false;
          };
          colorSchemes = {
            useWallpaperColors = true;
            predefinedScheme = "Noctalia (default)";
            darkMode = true;
            schedulingMode = "off";
            manualSunrise = "06:30";
            manualSunset = "18:30";
            matugenSchemeType = "scheme-fidelityt";
            generateTemplatesForPredefined = true;
          };
          templates = {
            gtk = false;
            qt = false;
            kcolorscheme = false;
            alacritty = false;
            kitty = false;
            ghostty = false;
            foot = false;
            wezterm = false;
            fuzzel = false;
            discord = false;
            pywalfox = false;
            vicinae = false;
            walker = false;
            code = false;
            spicetify = false;
            telegram = false;
            cava = false;
            yazi = false;
            emacs = false;
            niri = false;
            mango = false;
            zed = false;
            enableUserTemplates = false;
          };
          nightLight = {
            enabled = false;
            forced = false;
            autoSchedule = true;
            nightTemp = "4000";
            dayTemp = "6500";
            manualSunrise = "06:30";
            manualSunset = "18:30";
          };
          hooks = {
            enabled = false;
            wallpaperChange = "";
            darkModeChange = "";
            screenLock = "";
            screenUnlock = "";
            performanceModeEnabled = "";
            performanceModeDisabled = "";
          };
          desktopWidgets = {
            enabled = false;
            editMode = false;
            gridSnap = false;
            monitorWidgets = [ ];
          };
        };
      };
    })
  ];
}
