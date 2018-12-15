/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* prefs.vala
 *
 * Copyright © 2018 Jacob Humphrey
 *
 * This file is part of GNOME Four-in-a-row.
 *
 * GNOME Four-in-a-row is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * GNOME Four-in-a-row is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with GNOME Four-in-a-row. If not, see <http://www.gnu.org/licenses/>.
 */

class Prefs {
    bool _do_sound;
    public bool do_sound {
        get {
            return settings.get_boolean("sound");
        }
        private set {
            settings.set_boolean("sound", value);
        }
    }
    public int theme_id;
    public Level level[2];
    public int keypress[3];

    public Prefs() {
        level[PlayerID.PLAYER1] = Level.HUMAN; /* Human. Always human. */
        level[PlayerID.PLAYER2] = (Level) settings.get_int("opponent");
        keypress[Move.LEFT] = settings.get_int("key-left");
        keypress[Move.RIGHT] = settings.get_int("key-right");
        keypress[Move.DROP] = settings.get_int("key-drop");
        theme_id = settings.get_int("theme-id");

        settings.changed.connect(settings_changed_cb);

        level[PlayerID.PLAYER1] = sane_player_level(level[PlayerID.PLAYER1]);
        level[PlayerID.PLAYER2] = sane_player_level(level[PlayerID.PLAYER2]);
        theme_id = sane_theme_id(theme_id);
    }

    int sane_theme_id(int val) {
        if (val < 0 || val >= theme.length)
            return DEFAULT_THEME_ID;
            return val;
    }

    /**
     * theme_changed:
     *
     * emmited when the theme is changed
     *
     * @theme_id: The new theme_id
     */
    public signal void theme_changed(int theme_id);

    /**
     * sound_changed:
     *
     * emmited when the sound fx are enabled/disabled
     *
     * @sound: true if sound is enabled
     */
    public signal void sound_changed(bool sound);

    public void settings_changed_cb(string key) {
        if (key == "sound") {
            sound_changed(do_sound);
        } else if (key == "key-left") {
            keypress[Move.LEFT] = settings.get_int("key-left");
        } else if (key == "key-right") {
            keypress[Move.RIGHT] = settings.get_int("key-right");
        } else if (key == "key-drop") {
            keypress[Move.DROP] = settings.get_int("key-drop");
        } else if (key == "theme-id") {
            int val = sane_theme_id(settings.get_int("theme-id"));
            if (val != theme_id) {
                theme_id = val;
                if (!GameBoardView.instance.change_theme())
                    return;
                theme_changed(theme_id);
            }
        }
    }

    public int get_n_human_players() {
        if (level[PlayerID.PLAYER1] != Level.HUMAN && level[PlayerID.PLAYER2] != Level.HUMAN)
            return 0;
        if (level[PlayerID.PLAYER1] != Level.HUMAN || level[PlayerID.PLAYER2] != Level.HUMAN)
            return 1;
        return 2;
    }

    public void on_toggle_sound(Gtk.ToggleButton t) {
        p.do_sound = t.get_active();
    }

}

Settings settings;
PrefsBox? prefsbox = null;


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


public Level sane_player_level(Level val) {
    if (val < Level.HUMAN)
        return Level.HUMAN;
    if (val > Level.STRONG)
        return Level.STRONG;
    return val;
}

public void prefsbox_open() {
    Gtk.Grid grid;
    GamesControlsList controls_list;
    Gtk.Label label;
    Gtk.CellRendererText renderer;
    Gtk.ListStore model;
    Gtk.TreeIter iter;

    if (prefsbox != null) {
        prefsbox.present();
        return;
    }

    prefsbox = new PrefsBox(window);
    prefsbox.show_all();
}
