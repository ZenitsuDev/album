public class Album.PreviewPage : Adw.Bin {
    public Gtk.Picture picture { get; set; }
    public Granite.HeaderLabel label { get; set; }
    public Gtk.Button halt_button { get; set; }
    private Gtk.Label meta_title;
    private Gtk.Label meta_size;
    private Gtk.Label meta_time;
    private Gtk.Label meta_date;
    private Gtk.Label meta_filepath;

    construct {
        var preview_halt_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        preview_halt_box.append (new Gtk.Image.from_icon_name ("go-previous-symbolic"));
        preview_halt_box.append (new Granite.HeaderLabel ("Return to Gallery"));

        halt_button = new Gtk.Button () {
            child = preview_halt_box
        };
        halt_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        label = new Granite.HeaderLabel ("");
        var lbl = (Gtk.Label) label.get_last_child ();
        lbl.ellipsize = Pango.EllipsizeMode.START;

        var preview_header = new Gtk.HeaderBar () {
            decoration_layout = "close:",
            title_widget = label,
            hexpand = true,
            valign = Gtk.Align.START
        };
        preview_header.pack_start (halt_button);
        preview_header.add_css_class ("titlebar");
        preview_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        preview_header.add_css_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);

        picture = new Gtk.Picture () {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            hexpand = true,
            vexpand = true,
        };

        var preview_grid = new Gtk.Grid () {
            margin_start = 20,
            margin_end = 20,
            margin_top = 20,
            margin_bottom = 20
        };
        preview_grid.attach (picture, 0, 0);

        var preview_view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        preview_view.append (preview_header);
        preview_view.append (preview_grid);
        preview_view.add_css_class (Granite.STYLE_CLASS_VIEW);

        var meta_header = new Gtk.HeaderBar () {
            decoration_layout = ":maximize",
            title_widget = new Gtk.Label ("") { visible = false },
            valign = Gtk.Align.START
        };
        meta_header.add_css_class ("titlebar");
        meta_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        meta_header.add_css_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);

        meta_title = new Gtk.Label ("") {
            wrap = true,
            wrap_mode = Pango.WrapMode.CHAR,
            max_width_chars = 10,
            margin_top = 10,
            margin_bottom = 20
        };
        meta_title.add_css_class (Granite.STYLE_CLASS_H2_LABEL);

        meta_size = new Gtk.Label ("") {
            xalign = -1,
            use_markup = true
        };

        meta_time = new Gtk.Label ("") {
            xalign = -1,
            use_markup = true
        };

        meta_date = new Gtk.Label ("") {
            xalign = -1,
            use_markup = true
        };

        meta_filepath = new Gtk.Label ("") {
            xalign = -1,
            use_markup = true,
            wrap = true,
            wrap_mode = Pango.WrapMode.CHAR,
            max_width_chars = 15,
            margin_top = 20
        };

        var meta_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            vexpand = true,
            margin_start = 6,
            margin_end = 6,
            margin_top = 6,
            margin_bottom = 6,
        };
        meta_box.append (meta_title);
        meta_box.append (meta_date);
        meta_box.append (meta_time);
        meta_box.append (meta_filepath);
        meta_box.append (meta_size);

        var meta_sidebar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            width_request = 250
        };
        meta_sidebar.append (meta_header);
        meta_sidebar.append (meta_box);
        meta_sidebar.add_css_class (Granite.STYLE_CLASS_SIDEBAR);

        var leaflet = new Adw.Leaflet () {
            transition_type = Adw.LeafletTransitionType.SLIDE,
            hexpand = true,
            vexpand = true
        };
        leaflet.append (preview_view);
        leaflet.append (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        leaflet.append (meta_sidebar);

        child = leaflet;
    }

    public void update_properties (File file, string time, string date, string size) {
        meta_title.label = file.get_basename ();
        meta_time.label = "<b>Time modified: </b>%s".printf (time);
        meta_date.label = "<b>Date modified: </b>%s".printf (date);
        meta_size.label = "<b>File Size: </b>%s".printf (size);
        meta_filepath.label = "<b>Path: </b>%s".printf (file.get_path ());
    }
}
