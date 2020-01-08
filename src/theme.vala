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

private class ThemeManager : Object
{
    internal signal void theme_changed ();
    private bool theme_set = false;
    private int _theme_id;
    [CCode (notify = false)] public int theme_id
    {
        private get  { if (!theme_set) assert_not_reached (); return _theme_id; }
        internal set { _theme_id = value; theme_set = true; load_pixmaps (); theme_changed (); }
    }

    [CCode (notify = false)] public uint8 board_size { private get; internal construct; }

    internal ThemeManager (uint8 size)
    {
        Object (board_size: size);
    }

    /*\
    * * getting theme strings
    \*/

    internal string get_player_turn (Player who)
    {
        if (who == Player.HUMAN)
            return theme [theme_id].player1_turn;
        else
            return theme [theme_id].player2_turn;
    }

    internal string get_player_win (Player who)
    {
        if (who == Player.HUMAN)
            return theme [theme_id].player1_win;
        else
            return theme [theme_id].player2_win;
    }

    internal string get_player (Player who, bool with_colon)
    {
        if (with_colon)
        {
            if (who == Player.HUMAN)
                return _(theme [theme_id].player1_with_colon);  // FIXME this gettext call feels horrible 2/5
            else
                return _(theme [theme_id].player2_with_colon);  // FIXME this gettext call feels horrible 3/5
        }
        else
        {
            if (who == Player.HUMAN)
                return _(theme [theme_id].player1);             // FIXME this gettext call feels horrible 4/5
            else
                return _(theme [theme_id].player2);             // FIXME this gettext call feels horrible 5/5
        }
    }

    internal string get_grid_color ()
    {
        return theme [theme_id].grid_color;
    }

    /*\
    * * loading or creating pixmaps
    \*/

    private bool pixmaps_loaded = false;
    [CCode (notify = false)] internal Gdk.Pixbuf pb_tileset_raw { internal get { if (!pixmaps_loaded) assert_not_reached (); return _pb_tileset_raw; }}
    [CCode (notify = false)] internal Gdk.Pixbuf pb_bground_raw { internal get { if (!pixmaps_loaded) assert_not_reached (); return _pb_bground_raw; }}

    private Gdk.Pixbuf _pb_tileset_raw;
    private Gdk.Pixbuf _pb_bground_raw;

    private void load_pixmaps ()
    {
        load_image (theme [theme_id].fname_tileset, out _pb_tileset_raw);

        if (theme [theme_id].fname_bground != null)
            load_image ((!) theme [theme_id].fname_bground, out _pb_bground_raw);
        else
            create_background ();

        pixmaps_loaded = true;
    }

    private static void load_image (string image_name, out Gdk.Pixbuf pixbuf)
    {
        string image_resource = "/org/gnome/Four-in-a-row/images/" + image_name;
        try
        {
            pixbuf = new Gdk.Pixbuf.from_resource (image_resource);
        }
        catch (Error e)
        {
            critical (e.message);
            assert_not_reached ();
        }
    }

    private inline void create_background ()
    {
        int raw_tile_size = _pb_tileset_raw.get_height ();

        _pb_bground_raw = new Gdk.Pixbuf (Gdk.Colorspace.RGB, /* alpha */ true, /* bits per sample */ 8, raw_tile_size * /* BOARD_COLUMNS */ board_size, raw_tile_size * /* BOARD_ROWS_PLUS_ONE */ board_size);
        for (int i = 0; i < /* BOARD_COLUMNS */ board_size; i++)
        {
            _pb_tileset_raw.copy_area (raw_tile_size * 3, 0,
                                       raw_tile_size, raw_tile_size,
                                       _pb_bground_raw,
                                       i * raw_tile_size, 0);

            for (int j = 1; j < /* BOARD_ROWS_PLUS_ONE */ board_size; j++)
                _pb_tileset_raw.copy_area (raw_tile_size * 2, 0,
                                           raw_tile_size, raw_tile_size,
                                           _pb_bground_raw,
                                           i * raw_tile_size, j * raw_tile_size);
        }
    }

    /*\
    * * themes
    \*/

    internal string [] get_themes ()
    {
        string [] themes = {};
        for (uint8 i = 0; i < theme.length; i++)
            themes += _(theme [i].title);  // FIXME this gettext call feels horrible 1/5
        return themes;
    }

    private struct Theme
    {
        public string title;
        public string fname_tileset;
        public string? fname_bground;
        public string grid_color;
        public string player1;
        public string player2;
        public string player1_with_colon;
        public string player2_with_colon;
        public string player1_win;
        public string player2_win;
        public string player1_turn;
        public string player2_turn;
    }

    private const Theme theme [] = {
        {
            /* Translators: name of a black-on-white theme, for helping people with visual misabilities */
            N_("High Contrast"),
            "tileset_50x50_hcontrast.svg",
            null,
            "#000000",
            N_("Circle"),           N_("Cross"),
            N_("Circle:"),          N_("Cross:"),
            N_("Circle wins!"),     N_("Cross wins!"),
            N_("Circle’s turn"),    N_("Cross’s turn")
        },
        {
            /* Translators: name of a white-on-black theme, for helping people with visual misabilities */
            N_("High Contrast Inverse"),
            "tileset_50x50_hcinverse.svg",
            null,
            "#FFFFFF",
            N_("Circle"),           N_("Cross"),
            N_("Circle:"),          N_("Cross:"),
            N_("Circle wins!"),     N_("Cross wins!"),
            N_("Circle’s turn"),    N_("Cross’s turn")
        },
        {
            /* Translators: name of a red-versus-green theme */
            N_("Red and Green Marbles"),
            "tileset_50x50_faenza-glines-icon1.svg",
            "bg_toplight.png",
            "#727F8C",
            N_("Red"),              N_("Green"),
            N_("Red:"),             N_("Green:"),
            N_("Red wins!"),        N_("Green wins!"),
            N_("Red’s turn"),       N_("Green’s turn")
        },
        {
            /* Translators: name of a blue-versus-red theme */
            N_("Blue and Red Marbles"),
            "tileset_50x50_faenza-glines-icon2.svg",
            "bg_toplight.png",
            "#727F8C",
            N_("Blue"),             N_("Red"),
            N_("Blue:"),            N_("Red:"),
            N_("Blue wins!"),       N_("Red wins!"),
            N_("Blue’s turn"),      N_("Red’s turn")
        },
        {
            /* Translators: name of a red-versus-green theme with drawing on the tiles */
            N_("Stars and Rings"),
            "tileset_50x50_faenza-gnect-icon.svg",
            "bg_toplight.png",
            "#727F8C",
            N_("Red"),              N_("Green"),
            N_("Red:"),             N_("Green:"),
            N_("Red wins!"),        N_("Green wins!"),
            N_("Red’s turn"),       N_("Green’s turn")
        }
    };
}
