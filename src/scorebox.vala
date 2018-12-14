
/*
 * Needed to force vala to include headers in the correct order.
 * See https://gitlab.gnome.org/GNOME/vala/issues/98
 */
const string scorebox_gettext_package = Config.GETTEXT_PACKAGE;

class Scorebox : Gtk.Dialog {
    Gtk.Label[] label_name;
    Gtk.Label label_score[3];
    public FourInARow application;

    static Once<Scorebox> _instance;
    public static Scorebox instance {
        get {
            return _instance.once(() => {
                var scorebox = new Scorebox();
                //scorebox.show_all();
                scorebox.update();
                return scorebox;
            });
        }
    }

    Scorebox() {
        Object(title: _("Scores"),
               //parent: window,
               use_header_bar: 1,
               destroy_with_parent: true,
               resizable: false,
               border_width: 5);
        get_content_area().spacing = 2;

        Gtk.Grid grid, grid2;

        label_name = new Gtk.Label[3];
        label_score = new Gtk.Label[3];

        grid = new Gtk.Grid();
        grid.halign = Gtk.Align.CENTER;
        grid.row_spacing = 6;
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.border_width = 5;

        get_content_area().pack_start(grid);

        grid2 = new Gtk.Grid();
        grid.add(grid2);
        grid2.column_spacing = 6;

        label_name[PlayerID.PLAYER1] = new Gtk.Label(null);
        grid2.attach(label_name[PlayerID.PLAYER1], 0, 0, 1, 1);
        label_name[PlayerID.PLAYER1].xalign = 0;
        label_name[PlayerID.PLAYER1].yalign = 0.5f;

        label_score[PlayerID.PLAYER1] = new Gtk.Label(null);
        grid2.attach(label_score[PlayerID.PLAYER1], 1, 0, 1, 1);
        label_score[PlayerID.PLAYER1].xalign = 0;
        label_score[PlayerID.PLAYER1].yalign = 0.5f;

        label_name[PlayerID.PLAYER2] = new Gtk.Label(null);
        grid2.attach(label_name[PlayerID.PLAYER2], 0, 1, 1, 1);
        label_name[PlayerID.PLAYER2].xalign = 0;
        label_name[PlayerID.PLAYER2].yalign = 0.5f;

        label_score[PlayerID.PLAYER2] = new Gtk.Label(null);
        grid2.attach(label_score[PlayerID.PLAYER2], 1, 0, 1, 1);
        label_score[PlayerID.PLAYER2].set_xalign(0);
        label_score[PlayerID.PLAYER2].set_yalign(0.5f);

        label_name[PlayerID.NOBODY] = new Gtk.Label(_("Drawn:"));
        grid2.attach(label_name[PlayerID.NOBODY], 0, 2, 1, 1);
        label_name[PlayerID.NOBODY].set_xalign(0);
        label_name[PlayerID.NOBODY].set_yalign(0.5f);

        label_score[PlayerID.NOBODY] = new Gtk.Label(null);
        grid2.attach(label_score[PlayerID.NOBODY], 1, 0, 1, 1);
        label_score[PlayerID.NOBODY].set_xalign(0);
        label_score[PlayerID.NOBODY].set_yalign(0.5f);
        grid.show_all();

        application = global::application;
    }

    public void update() {
        if (p.get_n_human_players() == 1) {
            if (p.level[PlayerID.PLAYER1] == Level.HUMAN) {
                label_score[PlayerID.PLAYER1].set_text(_("You:"));
                label_score[PlayerID.PLAYER2].label = _("Me:");
            } else {
                label_score[PlayerID.PLAYER2].set_text(_("You:"));
                label_score[PlayerID.PLAYER1].label = _("Me:");
            }
        } else {
            label_name[PlayerID.PLAYER1].label = theme_get_player(PlayerID.PLAYER1);
            label_name[PlayerID.PLAYER2].label = theme_get_player(PlayerID.PLAYER2);
        }

        label_score[PlayerID.PLAYER1].label = (string)global::application.score[PlayerID.PLAYER1];
        label_score[PlayerID.PLAYER2].label = (string)application.score[PlayerID.PLAYER2];
        label_score[PlayerID.NOBODY].label = (string)application.score[PlayerID.NOBODY];

    }

    public void reset() {
        application.score[PlayerID.PLAYER1] = 0;
        application.score[PlayerID.PLAYER2] = 0;
        application.score[PlayerID.NOBODY] = 0;
        update();
    }
}
