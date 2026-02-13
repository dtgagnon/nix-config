# Stylesets for aerc
# Provides stylix-based and default stylesets
{ config, cfg }:
let
  c = config.lib.stylix.colors.withHashtag;
  stylixEnabled = config.stylix.enable or false;

  # Stylix-driven base16 styleset
  stylixStyleset = ''
    *.default = true
    *.normal = true
    *.fg = ${c.base05}
    *.bg = ${c.base00}
    *.selected.bg = ${c.base02}
    *.selected.fg = ${c.base07}

    title.fg = ${c.base00}
    title.bg = ${c.base0D}
    title.bold = true

    header.fg = ${c.base0D}
    header.bold = true

    *error.fg = ${c.base08}
    *warning.fg = ${c.base0A}
    *success.fg = ${c.base0B}

    statusline_default.fg = ${c.base05}
    statusline_default.bg = ${c.base01}
    statusline_error.fg = ${c.base08}
    statusline_error.bg = ${c.base01}
    statusline_success.fg = ${c.base0B}
    statusline_success.bg = ${c.base01}

    msglist_default.fg = ${c.base05}
    msglist_unread.fg = ${c.base07}
    msglist_unread.bold = true
    msglist_read.fg = ${c.base04}
    msglist_deleted.fg = ${c.base03}
    msglist_marked.fg = ${c.base0E}
    msglist_marked.bg = ${c.base01}
    msglist_flagged.fg = ${c.base09}
    msglist_result.fg = ${c.base0A}
    msglist_answered.fg = ${c.base0C}
    msglist_pill.fg = ${c.base00}
    msglist_pill.bg = ${c.base0D}
    msglist_gutter.fg = ${c.base02}

    dirlist_default.fg = ${c.base05}
    dirlist_unread.fg = ${c.base07}
    dirlist_unread.bold = true
    dirlist_recent.fg = ${c.base0B}

    selector_focused.fg = ${c.base00}
    selector_focused.bg = ${c.base0D}
    selector_chooser.bold = true

    completion_default.fg = ${c.base05}
    completion_default.bg = ${c.base01}
    completion_pill.fg = ${c.base00}
    completion_pill.bg = ${c.base0D}

    tab.fg = ${c.base04}
    tab.bg = ${c.base01}
    tab.selected.fg = ${c.base07}
    tab.selected.bg = ${c.base02}

    border.fg = ${c.base02}

    spinner.fg = ${c.base0C}

    part_mimetype.fg = ${c.base03}
    part_filename.fg = ${c.base0A}
  '';

  # Fallback styleset when stylix is not enabled
  defaultStyleset = ''
    *.default = true
    *.normal = true

    title.reverse = true
    title.bold = true

    header.bold = true

    *error.fg = red
    *warning.fg = yellow
    *success.fg = green

    statusline*.default = true
    statusline*.reverse = true

    msglist_unread.bold = true
    msglist_deleted.fg = gray

    selector_focused.reverse = true
    selector_chooser.bold = true

    tab.reverse = true
    border.reverse = true

    part_mimetype.fg = gray
    part_filename.fg = yellow
  '';
in
{
  default = if stylixEnabled then stylixStyleset else defaultStyleset;
}
// cfg.stylesets
