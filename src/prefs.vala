/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
   This file is part of GNOME Four-in-a-row.

   Copyright © 2018 Jacob Humphrey

   GNOME Four-in-a-row is free software: you can redistribute it and/or
   modify it under the terms of the GNU General Public License as published
   by the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   GNOME Four-in-a-row is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along
   with GNOME Four-in-a-row.  If not, see <https://www.gnu.org/licenses/>.
*/

private class Prefs : Object
{
    internal Settings settings;

    [CCode (notify = true)]  internal int theme_id       { internal get; internal set; }

    internal Level level [2];
    [CCode (notify = false)] internal int keypress_drop  { internal get; internal set; }
    [CCode (notify = false)] internal int keypress_right { internal get; internal set; }
    [CCode (notify = false)] internal int keypress_left  { internal get; internal set; }

    private static Once<Prefs> _instance;
    [CCode (notify = false)] internal static Prefs instance { internal get {
        return _instance.once(() => { return new Prefs (); });
    }}

    internal Prefs ()
    {
        settings = new GLib.Settings ("org.gnome.Four-in-a-row");
        level [PlayerID.PLAYER1] = Level.HUMAN; /* Human. Always human. */
        level [PlayerID.PLAYER2] = (Level) settings.get_int ("opponent");

        settings.bind ("theme-id",  this, "theme-id",       SettingsBindFlags.DEFAULT);
        settings.bind ("key-drop",  this, "keypress_drop",  SettingsBindFlags.DEFAULT);
        settings.bind ("key-right", this, "keypress_right", SettingsBindFlags.DEFAULT);
        settings.bind ("key-left",  this, "keypress_left",  SettingsBindFlags.DEFAULT);

        level [PlayerID.PLAYER1] = sane_player_level (level [PlayerID.PLAYER1]);
        level [PlayerID.PLAYER2] = sane_player_level (level [PlayerID.PLAYER2]);
    }

    internal int get_n_human_players ()
    {
        if (level [PlayerID.PLAYER1] != Level.HUMAN && level [PlayerID.PLAYER2] != Level.HUMAN)
            assert_not_reached ();
        if (level [PlayerID.PLAYER1] != Level.HUMAN || level [PlayerID.PLAYER2] != Level.HUMAN)
            return 1;
        else
            return 2;
    }

    private static Level sane_player_level (Level val)
    {
        if (val < Level.HUMAN)
            return Level.HUMAN;
        if (val > Level.STRONG)
            return Level.STRONG;
        return val;
    }
}
