/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* prefs.vala
 *
 * Four-in-a-row for GNOME
 * Copyright © 2018 Jacob Humphrey
 *
 * This game is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

struct Prefs {
    bool do_sound;
    int theme_id;
    Level level[2];
    int keypress[3];
}

Settings settings;
Gtk.Dialog? prefsbox = null;
Gtk.ComboBox combobox;
Gtk.ComboBoxText combobox_theme;
Gtk.CheckButton checkbutton_sound;
/*
 * Needed to force vala to include headers in the correct order.
 * See https://gitlab.gnome.org/GNOME/vala/issues/98
 */
const string GETTEXT_PACKAGE_CONTENT = Config.GETTEXT_PACKAGE;
Prefs p;

const uint DEFAULT_KEY_LEFT = Gdk.Key.Left;
const uint DEFAULT_KEY_RIGHT = Gdk.Key.Right;
const uint DEFAULT_KEY_DROP = Gdk.Key.Down;
const int DEFAULT_THEME_ID = 0;


static int sane_theme_id (int val) {
    if (val < 0 || val >= theme.length)
    return DEFAULT_THEME_ID;
    return val;
}

public int sane_player_level (int val) {
    if (val < Level.HUMAN)
        return Level.HUMAN;
    if (val > Level.STRONG)
        return Level.STRONG;
    return val;
}

public void on_select_theme (Gtk.ComboBox combo) {
    int id = combo.get_active ();
    settings.set_int ("theme-id", id);
}

public void on_toggle_sound (Gtk.ToggleButton t) {
    p.do_sound = t.get_active ();
    settings.set_boolean ("sound", t.get_active());
}

void prefs_init () {
    p.do_sound = settings.get_boolean ("sound");
    p.level[PlayerID.PLAYER1] = Level.HUMAN;	        /* Human. Always human. */
    p.level[PlayerID.PLAYER2] = (Level) settings.get_int ("opponent");
    p.keypress[Move.LEFT] = settings.get_int ("key-left");
    p.keypress[Move.RIGHT] = settings.get_int ("key-right");
    p.keypress[Move.DROP] = settings.get_int ("key-drop");
    p.theme_id = settings.get_int ("theme-id");

    settings.changed.connect(settings_changed_cb);

    p.level[PlayerID.PLAYER1] = (Level) sane_player_level (p.level[PlayerID.PLAYER1]);
    p.level[PlayerID.PLAYER2] = (Level) sane_player_level (p.level[PlayerID.PLAYER2]);
    p.theme_id = sane_theme_id (p.theme_id);
}

public void settings_changed_cb (string key) {
    if (key == "sound") {
        p.do_sound = settings.get_boolean ("sound");
        ((Gtk.ToggleButton)checkbutton_sound).set_active (p.do_sound);
    } else if (key == "key-left") {
        p.keypress[Move.LEFT] = settings.get_int ( "key-left");
    } else if (key == "key-right") {
        p.keypress[Move.RIGHT] = settings.get_int ( "key-right");
    } else if (key == "key-drop") {
        p.keypress[Move.DROP] = settings.get_int ( "key-drop");
    } else if (key == "theme-id") {
        int val = sane_theme_id (settings.get_int ("theme-id"));
        if (val != p.theme_id) {
            p.theme_id = val;
            if (!Gfx.change_theme ())
                return;
        if (prefsbox == null)
            return;
        combobox_theme.set_active (p.theme_id);
        }
    }
}

public void on_select_opponent (Gtk.ComboBox w) {
    Gtk.TreeIter iter;
    int value;

    w.get_active_iter (out iter);
    w.get_model().get (iter, 1, out value);

    p.level[PlayerID.PLAYER2] = (Level)value;
    settings.set_int ("opponent", value);
    scorebox_reset ();
    who_starts = PlayerID.PLAYER2;		/* This gets reversed in game_reset. */
    game_reset ();
}

public void prefsbox_open () {
    Gtk.Notebook notebook;
    Gtk.Grid grid;
    GamesControlsList controls_list;
    Gtk.Label label;
    Gtk.CellRendererText renderer;
    Gtk.ListStore model;
    Gtk.TreeIter iter;
    // gint i;

    if (prefsbox != null) {
        prefsbox.present ();
        return;
    }

    prefsbox = new Gtk.Dialog.with_buttons (_("Preferences"),
                        window,
                        Gtk.DialogFlags.DESTROY_WITH_PARENT);

    prefsbox.set_border_width(5);
    prefsbox.get_content_area().set_spacing(2);

    notebook = new Gtk.Notebook();
    notebook.set_border_width(5);
    prefsbox.get_content_area().pack_start(notebook, true, true, 0);

    /* game tab */

    grid = new Gtk.Grid();
    grid.set_row_spacing(6);
    grid.set_column_spacing(12);
    grid.set_border_width(12);

    label = new Gtk.Label(_("Game"));
    notebook.append_page(grid, label);

    label = new Gtk.Label(_("Opponent:"));
    label.set_hexpand(true);
    grid.attach(label,0,0 ,1, 1);

    combobox = new Gtk.ComboBox();
    renderer = new Gtk.CellRendererText();
    combobox.pack_start(renderer, true);
    combobox.add_attribute(renderer, "text", 0);
    model = new Gtk.ListStore(2, typeof(string), typeof(int));
    combobox.set_model(model);
    model.append(out iter);
    model.set(iter, 0, _("Human"), 1, Level.HUMAN);
    if (p.level[PlayerID.PLAYER2] == Level.HUMAN)
        combobox.set_active_iter(iter);
    model.append(out iter);
    model.set(iter, 0, _("Level one"), 1, Level.WEAK);
    if (p.level[PlayerID.PLAYER2] == Level.WEAK)
        combobox.set_active_iter(iter);
    model.append(out iter);
    model.set(iter, 0, _("Level two"), 1, Level.MEDIUM);
    if (p.level[PlayerID.PLAYER2] == Level.MEDIUM)
        combobox.set_active_iter(iter);
    model.append(out iter);
    model.set(iter, 0, _("Level thre"), 1, Level.STRONG);
    if (p.level[PlayerID.PLAYER2] == Level.STRONG)
        combobox.set_active_iter(iter);

    combobox.changed.connect(on_select_opponent);
    grid.attach(combobox, 1, 0, 1, 1);

    label = new Gtk.Label.with_mnemonic(_("_Theme:"));
    label.set_xalign((float)0.0);
    label.set_yalign((float)0.5);
    grid.attach(label, 0, 1, 1, 1);

    combobox_theme = new Gtk.ComboBoxText();
    for (int i = 0; i < theme.length; i++) {
        combobox_theme.append_text(_(theme_get_title(i)));
    }
    label.set_mnemonic_widget(combobox_theme);
    grid.attach(combobox_theme, 1, 1, 1, 1);

    checkbutton_sound = new Gtk.CheckButton.with_mnemonic(_("E_nable sounds"));
    grid.attach(checkbutton_sound, 0, 2, 2, 1);

    /* keyboard tab */

    label = new Gtk.Label.with_mnemonic (_("Keyboard Controls"));

    controls_list = new GamesControlsList(settings);
    controls_list.add_controls("key-left", _("Move left"), DEFAULT_KEY_LEFT,
                   "key-right", _("Move right"), DEFAULT_KEY_RIGHT,
                   "key-drop", _("Drop marble"), DEFAULT_KEY_DROP);
    controls_list.border_width = 12;
    notebook.append_page(controls_list, label);

    /* fill in initial values */

    combobox_theme.set_active(p.theme_id);
    checkbutton_sound.set_active(p.do_sound);

    /* connect signals */

    //prefsbox.response.connect(on_dialog_close);
    // g_signal_connect (prefsbox, "response", G_CALLBACK (on_dialog_close),
        //     &prefsbox);

    combobox_theme.changed.connect(on_select_theme);

    checkbutton_sound.toggled.connect(on_toggle_sound);

    prefsbox.show_all();
}
