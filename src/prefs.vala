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

private class Prefs : Object {
    private const int DEFAULT_THEME_ID = 0;

    [CCode (notify = false)] internal bool do_sound{ internal get; internal set;}

    private int _theme_id;
    [CCode (notify = true)] internal int theme_id {
        get{
            return sane_theme_id(_theme_id);
        }
        set{
            _theme_id = sane_theme_id(value);
        }
    }

    internal Level level[2];
    [CCode (notify = false)] internal int keypress_drop  { internal get; internal set; }
    [CCode (notify = false)] internal int keypress_right { internal get; internal set; }
    [CCode (notify = false)] internal int keypress_left  { internal get; internal set; }
    internal Settings settings;

    private static Once<Prefs> _instance;
    [CCode (notify = false)] internal static Prefs instance { internal get {
        return _instance.once(() => { return new Prefs(); });
    }}

    internal Prefs() {
        settings = new GLib.Settings("org.gnome.Four-in-a-row");
        level[PlayerID.PLAYER1] = Level.HUMAN; /* Human. Always human. */
        level[PlayerID.PLAYER2] = (Level) settings.get_int("opponent");
        theme_id = settings.get_int("theme-id");

        settings.changed ["theme-id"].connect(theme_id_changed_cb);
        settings.bind("sound", this, "do_sound", SettingsBindFlags.DEFAULT);
        settings.bind("theme-id", this, "theme-id", SettingsBindFlags.DEFAULT);
        settings.bind("key-drop", this, "keypress_drop", SettingsBindFlags.DEFAULT);
        settings.bind("key-right", this, "keypress_right", SettingsBindFlags.DEFAULT);
        settings.bind("key-left", this, "keypress_left", SettingsBindFlags.DEFAULT);

        level[PlayerID.PLAYER1] = sane_player_level(level[PlayerID.PLAYER1]);
        level[PlayerID.PLAYER2] = sane_player_level(level[PlayerID.PLAYER2]);
        theme_id = sane_theme_id(theme_id);
    }

    private static int sane_theme_id(int val) {
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
    internal signal void theme_changed(int theme_id);

    private inline void theme_id_changed_cb (string key) {
        int val = sane_theme_id(settings.get_int("theme-id"));
        if (val != theme_id)
            theme_id = val;
        theme_changed(theme_id);
    }

    internal int get_n_human_players() {
        if (level[PlayerID.PLAYER1] != Level.HUMAN && level[PlayerID.PLAYER2] != Level.HUMAN)
            return 0;
        if (level[PlayerID.PLAYER1] != Level.HUMAN || level[PlayerID.PLAYER2] != Level.HUMAN)
            return 1;
        return 2;
    }

    internal inline void on_toggle_sound(Gtk.ToggleButton t) {
        do_sound = t.get_active();
    }

    private static Level sane_player_level(Level val) {
        if (val < Level.HUMAN)
            return Level.HUMAN;
        if (val > Level.STRONG)
            return Level.STRONG;
        return val;
    }
}
