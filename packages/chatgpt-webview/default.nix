{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  pname = "chatgpt-webview";
  version = "1.0";

  # Inline C source
  src = pkgs.runCommand "source" {} ''
    mkdir -p $out
    cat > $out/simple-webview.c <<EOF
    #include <gtk4/gtk.h>
    #include <webkitgtk_6_0/webkitgtk.h>

    int main(int argc, char *argv[]) {
        gtk_init(&argc, &argv);

        GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
        GtkWidget *webview = webkit_web_view_new();

        gtk_window_set_title(GTK_WINDOW(window), "ChatGPT WebView");
        gtk_window_set_default_size(GTK_WINDOW(window), 800, 600);

        webkit_web_view_load_uri(WEBKIT_WEB_VIEW(webview), "https://chatgpt.com");
        gtk_container_add(GTK_CONTAINER(window), webview);

        g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
        gtk_widget_show_all(window);

        gtk_main();
        return 0;
    }
    EOF
  '';

  buildInputs = [ pkgs.gtk4.dev pkgs.webkitgtk_6_0 ];
  nativeBuildInputs = [ pkgs.pkg-config ];

  buildPhase = ''
    gcc -o simple-webview $src/simple-webview.c \
      `pkg-config --cflags --libs gtk4 webkitgtk-6.0`
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv simple-webview $out/bin/chatgpt-webview
  '';

  meta = with pkgs.lib; {
    description = "Minimal webview application using WebKitGTK";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}