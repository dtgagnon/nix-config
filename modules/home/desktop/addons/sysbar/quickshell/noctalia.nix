{ lib
, config
, inputs
, system
, namespace
, ...
}:
let
  inherit (lib) mkIf mkOverride;
  cfg = config.${namespace}.desktop.addons.sysbar.quickshell;
  stylixEnabled = config.stylix.enable;
in
{
  config = mkIf (cfg.premade == "noctalia-shell") {
    programs.noctalia-shell = {
      enable = true;
      systemd.enable = true;
      package = inputs.noctalia.packages.${system}.default.overrideAttrs (oldAttrs: {
        postPatch =
          (oldAttrs.postPatch or "")
          + ''
            # Pass button name to settings panel toggle so it opens near the ControlCenter button
            substituteInPlace Modules/Bar/Widgets/ControlCenter.qml \
              --replace-fail 'panel.toggle();' \
                             'panel.toggle(null, "ControlCenter");'
          '';
      });
      settings = {
        bar = {
          position = "left";
          monitors = [ ];
          density = "spacious";
          transparent = false;
          showOutline = false;
          showCapsule = true;
          capsuleOpacity = mkIf (!stylixEnabled) 1;
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
          fontDefault = mkIf (!stylixEnabled) config.${namespace}.desktop.styling.core.fonts.sansSerif.name;
          fontFixed = mkIf (!stylixEnabled) config.${namespace}.desktop.styling.core.fonts.monospace.name;
          fontDefaultScale = 1;
          fontFixedScale = 1;
          tooltipsEnabled = true;
          panelBackgroundOpacity = mkIf (!stylixEnabled) 0.85;
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
          enabled = true;
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
          hideWallpaperFilenames = true;
          useWallhaven = true;
          wallhavenQuery = "";
          wallhavenSorting = "relevance";
          wallhavenOrder = "desc";
          wallhavenCategories = "111";
          wallhavenPurity = "111";
          wallhavenRatios = "32x9";
          wallhavenResolutionMode = "atleast";
          wallhavenResolutionWidth = "5120";
          wallhavenResolutionHeight = "1440";
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
          backgroundOpacity = mkIf (!stylixEnabled) 1;
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
          backgroundOpacity = mkIf (!stylixEnabled) 0.85;
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
          location = "bottom_left";
          autoHideMs = 2000;
          overlayLayer = true;
          backgroundOpacity = mkIf (!stylixEnabled) 1;
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


    # Override lock-related settings to use noctalia-shell lockscreen
    ${namespace} = {
      desktop.addons.hyprlock.enable = mkOverride 90 false;
      desktop.hyprland.extraKeybinds."$lock" = mkOverride 90 "noctalia-shell ipc call lockScreen lock";
    };
    services.hypridle.settings.general.lock_cmd = mkOverride 90 "noctalia-shell ipc call lockScreen lock";
  };
}
