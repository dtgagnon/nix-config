{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "chatgpt-webview";
  version = "1.0";
  src = pkgs.runCommand "dummy-src" {} ''
    mkdir -p $out
    cat > $out/main.c <<EOF
    #include <gtk/gtk.h>
    #include <webkit6/webkit6.h>

    static void activate(GtkApplication *app, gpointer user_data) {
        GtkWidget *window = gtk_application_window_new(app);
        gtk_window_set_default_size(GTK_WINDOW(window), 800, 600);
        gtk_window_set_title(GTK_WINDOW(window), "ChatGPT Webview");

        WebKitWebView *webview = WEBKIT_WEB_VIEW(webkit_web_view_new());
        gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(webview));

        webkit_web_view_load_uri(webview, "https://chatgpt.com");

        gtk_widget_show_all(window);
    }

    int main(int argc, char **argv) {
        GtkApplication *app = gtk_application_new("com.chatgpt.webview", G_APPLICATION_FLAGS_NONE);
        g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);
        int status = g_application_run(G_APPLICATION(app), argc, argv);
        g_object_unref(app);
        return status;
    }
    EOF
  '';

  nativeBuildInputs = [ pkgs.pkg-config ];
  buildInputs = [
    pkgs.gtk3
    pkgs.webkitgtk_6_0
  ];

  installPhase = ''
    mkdir -p $out/bin
    gcc -o $out/bin/chatgpt-webview $src/main.c \
      $(pkg-config --cflags --libs gtk+-3.0 webkitgtk-6.0)
    chmod +x $out/bin/chatgpt-webview
  '';

  meta = with pkgs.lib; {
    description = "Lightweight webview application to open ChatGPT in a window using WebKitGTK 6.0";
    homepage = "https://chatgpt.com";
  };
}