# Git Migration Plan — GitHub → Forgejo (git.spirenet.link)

## Strategy

- **Forgejo** becomes the primary remote for all owned repos (private + public)
- **GitHub** stays as a mirror for public/open-source repos (visibility, community)
- **Forks** stay on GitHub only (needed for upstream PRs)
- **Local-only repos** get pushed to Forgejo

## Repo Inventory

### Private Repos — Move to Forgejo (primary), remove from GitHub or keep as backup

| Repo | GitHub URL | Local Path | Last Pushed |
|------|-----------|------------|-------------|
| nix-secrets | https://github.com/dtgagnon/nix-secrets | ~/nix-config/nix-secrets | 2026-03-04 |
| yell | https://github.com/dtgagnon/yell | ~/proj/CODE/yell | 2026-03-03 |
| web-portfolio | https://github.com/dtgagnon/web-portfolio | — | 2026-03-03 |
| eterna-design | https://github.com/dtgagnon/eterna-design | — | 2026-03-03 |
| dtg-engineering | https://github.com/dtgagnon/dtg-engineering | — | 2026-03-03 |
| spirenet-dashboard | https://github.com/dtgagnon/spirenet-dashboard | — | 2026-02-26 |
| odooAdds | https://github.com/dtgagnon/odooAdds | ~/proj/CODE/odoo-addons | 2026-02-13 |
| n8n-nix-overlay | https://github.com/dtgagnon/n8n-nix-overlay | ~/proj/AUTOMATE/n8n | 2026-01-02 |
| keeb-share | https://github.com/dtgagnon/keeb-share | — | 2025-11-18 |
| spectacle | https://github.com/dtgagnon/spectacle | ~/proj/CODE/spectacle | 2025-11-08 |
| md-coach | https://github.com/dtgagnon/md-coach | — | 2025-11-07 |
| ergofit | https://github.com/dtgagnon/ergofit | ~/proj/CODE/ergofit | 2025-08-12 |
| dtg-books | https://github.com/dtgagnon/dtg-books | — | 2025-07-22 |
| jobbit | https://github.com/dtgagnon/jobbit | ~/proj/CODE/jobbit | 2025-07-02 |
| jupyter-notebooks | https://github.com/dtgagnon/jupyter-notebooks | — | 2025-01-03 |
| tale_time_web | https://github.com/dtgagnon/tale_time_web | — | 2023-08-07 |

### Public Repos — Move to Forgejo (primary), mirror back to GitHub

| Repo | GitHub URL | Local Path | Last Pushed |
|------|-----------|------------|-------------|
| nix-config | https://github.com/dtgagnon/nix-config | ~/nix-config/nixos | 2026-03-02 |
| nixvim | https://github.com/dtgagnon/nixvim | ~/nix-config/nixvim | 2026-02-23 |
| rybbix | https://github.com/dtgagnon/rybbix | — | 2026-02-16 |
| emma | https://github.com/dtgagnon/emma | ~/proj/AUTOMATE/email-agent | 2026-02-16 |
| nix-bookshelf | https://github.com/dtgagnon/nix-bookshelf | — | 2026-02-09 |
| nix-on-droid | https://github.com/dtgagnon/nix-on-droid | — | 2026-01-13 |
| spective | https://github.com/dtgagnon/spective | — | 2026-01-04 |
| dtgagnon (profile) | https://github.com/dtgagnon/dtgagnon | — | 2025-12-16 |
| nixpile | https://github.com/dtgagnon/nixpile | ~/nix-config/nixpile | 2025-10-07 |
| odoo_gantt | https://github.com/dtgagnon/odoo_gantt | — | 2025-10-03 |
| hass-nix | https://github.com/dtgagnon/hass-nix | ~/nix-config/hass-nix | 2025-07-20 |
| terminAIl | https://github.com/dtgagnon/terminAIl | — | 2025-06-03 |
| time-tracker-webapp | https://github.com/dtgagnon/time-tracker-webapp | — | 2025-01-14 |
| nixpkgs-windsurf | https://github.com/dtgagnon/nixpkgs-windsurf | — | 2024-12-11 |
| bias-detector-app | https://github.com/dtgagnon/bias-detector-app | ~/proj/CODE/bias-detective | 2024-11-24 |
| td-clone | https://github.com/dtgagnon/td-clone | — | 2025-11-10 |
| note-app | https://github.com/dtgagnon/note-app | — | 2023-05-12 |

### Forks — Stay on GitHub only (no migration)

| Repo | Description | Last Pushed |
|------|-------------|-------------|
| nixpkgs | Nix Packages collection & NixOS | 2025-10-09 |
| snowfall-lib | Nix Flakes framework | 2025-12-03 |
| Weylus | Tablet as graphic tablet | 2025-11-18 |
| activitywatch | Time tracker | 2025-11-08 |
| crawl4ai | LLM web crawler | 2025-06-29 |
| nixsim | Sim Studio agent workflow | 2025-06-28 |
| plane.nix | Nix package for Plane | 2025-06-24 |
| plane | Project management | 2025-06-23 |
| direct-file | Direct File | 2025-06-05 |
| server-tools | Odoo admin tools | 2025-12-07 |
| super-productivity | Todo/time tracking | 2025-08-07 |
| phrasesync | Obsidian plugin | 2025-08-21 |
| hyprdvd | DVD screensaver | 2025-10-13 |
| S4_Slicer | Non-planar slicer | 2025-04-19 |
| DIY-Sim-Racing-FFB-Pedal | Sim racing pedal | 2025-02-01 |
| schemes | Tinted theming color schemes | 2025-01-14 |
| SLS4All.Compact | SLS 3D printing | 2024-12-20 |
| SLS4All.Compact.InstallScripts | SLS install scripts | 2024-11-12 |

### Local-Only Repos — Push to Forgejo (new remotes)

| Repo | Local Path |
|------|-----------|
| vscan | ~/proj/CODE/vscan |
| bookie | ~/proj/CODE/bookie |
| insurance_calculations | ~/proj/CODE/insurance_calculations |
| dtge-email-digest | ~/proj/AUTOMATE/dtge-email-digest |
| dashboard | ~/proj/AUTOMATE/dashboard |
| Watchtower | ~/Apps/Watchtower |

## Migration Steps (per repo)

### For repos with existing GitHub remotes:
```bash
# 1. Create repo on Forgejo (via web UI or API)
# 2. Add Forgejo as new remote
git remote add forgejo git@git.spirenet.link:<org>/<repo>.git
# 3. Push all branches and tags
git push forgejo --all
git push forgejo --tags
# 4. (Optional) Rename remotes so Forgejo is "origin"
git remote rename origin github
git remote rename forgejo origin
```

### For local-only repos:
```bash
# 1. Create repo on Forgejo
# 2. Add as origin
git remote add origin git@git.spirenet.link:<org>/<repo>.git
# 3. Push
git push -u origin --all
git push origin --tags
```

### For GitHub mirroring (public repos):
Forgejo supports push mirrors natively:
- Repo Settings → Mirror Settings → Add Push Mirror → `https://github.com/dtgagnon/<repo>.git`
- Uses a GitHub personal access token for auth
- Automatically syncs on push

## Flake Input Updates

After migration, update flake inputs that reference GitHub:
- `nix-secrets` → `git+ssh://git@git.spirenet.link/dtgagnon/nix-secrets`
- `spirenet-dashboard` → `git+ssh://git@git.spirenet.link/dtgagnon/spirenet-dashboard`
- Any other private flake inputs

## Counts

| Category | Count |
|----------|-------|
| Move to Forgejo (private) | 16 |
| Move to Forgejo (public, mirror to GH) | 17 |
| Stay on GitHub (forks) | 17 |
| New Forgejo repos (local-only) | 6 |
| **Total repos on Forgejo** | **39** |
