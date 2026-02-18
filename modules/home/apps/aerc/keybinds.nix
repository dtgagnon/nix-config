# Keybindings configuration for aerc
{ cfg, config, pkgs, namespace }:
let
  notmuch = "${pkgs.notmuch}/bin/notmuch";
  fzf = "${pkgs.fzf}/bin/fzf";
  mailCfg = config.${namespace}.services.mail;
  mailDir = "${config.home.homeDirectory}/${mailCfg.mailDir}";
in
''
  # Global keybindings
  [messages]
  q = :quit<Enter>

  j = :next<Enter>
  <Down> = :next<Enter>
  <C-d> = :next 50%<Enter>
  <C-f> = :next 100%<Enter>
  <PgDn> = :next 100%<Enter>

  k = :prev<Enter>
  <Up> = :prev<Enter>
  <C-u> = :prev 50%<Enter>
  <C-b> = :prev 100%<Enter>
  <PgUp> = :prev 100%<Enter>

  g = :select 0<Enter>
  G = :select -1<Enter>

  J = :next-folder<Enter>
  K = :prev-folder<Enter>
  H = :collapse-folder<Enter>
  L = :expand-folder<Enter>

  v = :mark -t<Enter>
  V = :mark -v<Enter>
  <space> = :mark -t<Enter>

  mr = :read<Enter>
  mu = :unread<Enter>
  mi = :flag -t<Enter>

  T = :toggle-threads<Enter>

  <Enter> = :view<Enter>
  l = :view<Enter>
  d = :prompt 'Really delete this message?' 'delete-message'<Enter>
  D = :delete<Enter>
  A = :archive flat<Enter>

  C = :compose<Enter>
  rr = :reply -a<Enter>
  rq = :reply -aq<Enter>
  Rr = :reply<Enter>
  Rq = :reply -q<Enter>

  c = :cf<space>
  $ = :term<Enter>
  ! = :term<Enter>
  | = :pipe<space>

  / = :search<space>
  \ = :filter<space>
  n = :next-result<Enter>
  N = :prev-result<Enter>
  <Esc> = :clear<Enter>

  t = :menu -c '${notmuch} search --output=tags "*" | grep -Ev "^(attachment|encrypted|signed|replied|passed)$" | sort -u' -e '${fzf} --reverse --border --preview="${notmuch} count tag:{}" --preview-label="Message count" --prompt="Tag: "' search tag:<Enter>
  F = :menu -c 'grep -shv "^#" ${mailDir}/.notmuch/querymap-* | cut -d= -f1 | sort -u' -e '${fzf} --reverse --border --prompt="Folder: "' 'cf '<Enter>

  s = :split<Enter>
  S = :vsplit<Enter>

  <A-h> = :prev-tab<Enter>
  <A-l> = :next-tab<Enter>

  [messages:folder=Drafts]
  <Enter> = :recall<Enter>

  [view]
  / = :toggle-key-passthrough<Enter>/
  q = :close<Enter>
  h = :close<Enter>
  | = :pipe<space>

  f = :forward<Enter>
  rr = :reply -a<Enter>
  rq = :reply -aq<Enter>
  Rr = :reply<Enter>
  Rq = :reply -q<Enter>

  H = :toggle-headers<Enter>
  <C-k> = :prev-part<Enter>
  <C-j> = :next-part<Enter>
  J = :next<Enter>
  K = :prev<Enter>
  S = :save<space>
  | = :pipe<space>
  D = :delete<Enter>
  A = :archive flat<Enter>

  <C-l> = :open-link<space>

  o = :open<Enter>
  O = :open -a<Enter>

  <A-h> = :prev-tab<Enter>
  <A-l> = :next-tab<Enter>

  [view::passthrough]
  $noinherit = true
  $ex = <C-x>
  <Esc> = :toggle-key-passthrough<Enter>

  [compose]
  $noinherit = true
  $ex = <C-x>
  <C-k> = :prev-field<Enter>
  <C-j> = :next-field<Enter>
  <A-p> = :switch-account -p<Enter>
  <A-n> = :switch-account -n<Enter>
  <tab> = :next-field<Enter>
  <backtab> = :prev-field<Enter>
  <C-p> = :prev-tab<Enter>
  <C-n> = :next-tab<Enter>
  <A-h> = :prev-tab<Enter>
  <A-l> = :next-tab<Enter>

  [compose::editor]
  $noinherit = true
  $ex = <C-x>
  <C-k> = :prev-field<Enter>
  <C-j> = :next-field<Enter>
  <C-p> = :prev-tab<Enter>
  <C-n> = :next-tab<Enter>
  <A-h> = :prev-tab<Enter>
  <A-l> = :next-tab<Enter>

  [compose::review]
  y = :send<Enter>
  n = :abort<Enter>
  v = :preview<Enter>
  p = :postpone<Enter>
  q = :choose -o d discard :abort -o p postpone :postpone<Enter>
  e = :edit<Enter>
  a = :attach<space>
  d = :detach<space>

  <A-h> = :prev-tab<Enter>
  <A-l> = :next-tab<Enter>

  [terminal]
  $noinherit = true
  $ex = <C-x>
  <C-p> = :prev-tab<Enter>
  <C-n> = :next-tab<Enter>
  <A-h> = :prev-tab<Enter>
  <A-l> = :next-tab<Enter>

  ${cfg.extraBinds}
''
