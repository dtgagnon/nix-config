<div align="center"><img src="assets/nixos-logo.png" width="300px"></div>
<h1 align="center">dtgagnon ❄️ NixOS Public Configuration</h1>

<div align="center">

![stars](https://img.shields.io/github/stars/TheMaxMur/NixOS-Configuration?label=Stars&color=F5A97F&labelColor=303446&style=flat&logo=starship&logoColor=F5A97F)
![nixos](https://img.shields.io/badge/NixOS-unstable-blue.svg?style=flat&logo=nixos&logoColor=CAD3F5&colorA=24273A&colorB=8aadf4)
![flake check](https://img.shields.io/static/v1?label=Nix%20Flake&message=Check&style=flat&logo=nixos&colorA=24273A&colorB=9173ff&logoColor=CAD3F5)
![license](https://img.shields.io/static/v1.svg?style=flat&label=License&message=Unlicense&colorA=24273A&colorB=91d7e3&logo=unlicense&logoColor=91d7e3&)

</div>

## Table of contents

- [Features](#-features)
- [File structure](#-file-structure)
- [Desktop preview](#%EF%B8%8F-desktop-preview)
  - [Hyprland](#-hyprland)
  - [SwayFX](#-swayfx)
- [Software](#-software)
- [Hosts description](#%EF%B8%8F-hosts-description)
- [Keyboard](#%EF%B8%8F-keyboard)
- [Special thanks](#%EF%B8%8F-special-thanks)
- [Star history](#-star-history)

## ✨ Features 

- [X]❄️ Flakes -- for precise dependency management of the entire system.
- [X]🏡 Home Manager -- to configure all used software for the user.
- [ ]💽 Disko -- for declarative disk management: luks + lvm + btrfs.
- [ ]⚠️ Impermanence -- to remove junk files and directories that are not specified in the config.
- [ ]💈 Stylix -- to customize the theme for the entire system and the software you use.
- [ ]🍎 NixDarwin -- to declaratively customize MacOS.
- [ ]🔐 Lanzaboot -- to securely boot the system.
- [X]📁 Config file structure and modules with options.

## 📁 File structure

- [❄️ flake.nix](flake.nix) configuration entry point
- [1][👤🏡 Users & Homes](homes/) entry point for creating a home manager user
    - [🧩 modules](modules/home/) home manager modules 
- [♻️ overlays](overlays/) all overlays
- [📃 lib](lib/) helper functions for creating configurations
- [🖥️💾 systems + hw](systems/) machine (host) configs incl. hardware
    - [🧩 modules](modules/nixos/) machine modules
- [📄 templates](templates/) templates

## 🖼️ Desktop preview

### ⚡ Hyprland

![desktop0.png](assets/github/desktop0.png)

![desktop1.png](assets/github/desktop1.png)

![desktop2.png](assets/github/desktop2.png)

![desktop3.png](assets/github/desktop3.png)

### 💪 SwayFX

![swayfx0.png](assets/github/swayfx/image0.png)

![swayfx1.png](assets/github/swayfx/image1.png)

![swayfx2.png](assets/github/swayfx/image2.png)

## 📘 Software

 - OS - [**`NixOS`**](https://nixos.org/)
 - WM - [**`Hyprland`**](https://hyprland.org/) or [**`SwayFX`**](https://github.com/WillPower3309/swayfx)
 - Theme - [**`N/A`**]()
 - Wallpapers - [**`N/A`**]()
 - Editor - [**`Neovim`**](https://neovim.io/)
 - Bar - [**`Waybar`**](https://github.com/Alexays/Waybar)
 - Terminal - [**`Windows Terminal`**](https://)
 - Shell - [**`Zsh`**](https://)
 - Promt - [**`Starship`**](https://starship.rs/)
 - Filemanager - [**`Yazi`**](https://github.com/sxyazi/yazi)

## 🖥️ Hosts description

| Hostname | Board | CPU | RAM | GPU | OS | State |
| --- | --- | --- | --- | --- | --- | --- |
| pcbox | X299 AORUS Ultra Gaming Pro-CF | i7-7800X | 64GB | Sapphire AMD Radeon RX 7600 XT PULSE | NixOS | OK |
| nbox | Asus ZenBook 2024 Oled | Ultra7 155h | 32GB | Integrated Intel Arc (?) | NixOS | OK |
| rasp | Raspberry Pi 4 | Broadcom BCM2711 | 4GB | Broadcom VideoCore VI | NixOS | OK |
| macbox | Mac Mini M1 | Apple Silicon M1 | 8GB | Apple M1 8-Core GPU | MacOS | ? |

## ⌨️ Keyboard

I use corne split with a modified [miryoku](https://github.com/manna-harbour/miryoku) layout. This is one of the most affordable and easy options for an ergonomic keyboard. 

- WS Heavy Tactile switches
- Blank white PBT Cherry keycaps
- KBDFANS switch pads
- Tape mod
- O-rings
- Jincomso wrist rest 

<details><summary>Layer 0 Main</summary>

![layer-0.png](assets/keyboard/layer-0.png)

</details>

<details><summary>Layer 1 Media</summary>

![layer-1.png](assets/keyboard/layer-1.png)

</details>

<details><summary>Layer 2 Nav</summary>

![layer-2.png](assets/keyboard/layer-2.png)

</details>

<details><summary>Layer 3 Mouse</summary>

![layer-3.png](assets/keyboard/layer-3.png)

</details>

<details><summary>Layer 4 Sym</summary>

![layer-4.png](assets/keyboard/layer-4.png)

</details>

<details><summary>Layer 5 Num</summary>

![layer-5.png](assets/keyboard/layer-5.png)

</details>

<details><summary>Layer 6 Fun</summary>

![layer-6.png](assets/keyboard/layer-6.png)

</details>

## ❤️ Special thanks

[TheMaxMur](https://github.com/TheMaxMur)