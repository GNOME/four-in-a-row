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

private class GameBoardView : Gtk.DrawingArea
{
    private enum Tile {
        PLAYER1,
        PLAYER2,
        CLEAR,
        CLEAR_CURSOR,
        PLAYER1_CURSOR,
        PLAYER2_CURSOR;
    }

    [CCode (notify = false)] public Board game_board { private get; protected construct; }

    private int _theme_id = 0;
    [CCode (notify = false)] public int theme_id
    {
        private get { return _theme_id; }
        internal construct set
        {
            _theme_id = value;
            change_theme ();
        }
    }

    internal GameBoardView (Board game_board, int theme_id)
    {
        Object (game_board: game_board, theme_id: theme_id);
    }

    construct
    {
        events = Gdk.EventMask.EXPOSURE_MASK
               | Gdk.EventMask.BUTTON_PRESS_MASK
               | Gdk.EventMask.BUTTON_RELEASE_MASK;
        load_pixmaps ();
    }

    /*\
    * * drawing variables
    \*/

    private int board_size = 0;
    private int tile_size = 0;
    private int offset [6];
    private int board_x;
    private int board_y;

    internal inline void draw_tile (int row, int col)
    {
        queue_draw_area (/* start */ col * tile_size + board_x,
                                     row * tile_size + board_y,
                         /* size  */ tile_size,
                                     tile_size);
    }

    protected override bool configure_event (Gdk.EventConfigure e)
    {
        int allocated_width  = get_allocated_width ();
        int allocated_height = get_allocated_height ();
        int size = int.min (allocated_width, allocated_height);
        tile_size = size / BOARD_SIZE;
        board_size = tile_size * BOARD_SIZE;
        board_x = (allocated_width  - board_size) / 2;
        board_y = (allocated_height - board_size) / 2;

        offset [Tile.PLAYER1]        = 0;
        offset [Tile.PLAYER2]        = tile_size;
        offset [Tile.CLEAR]          = tile_size * 2;
        offset [Tile.CLEAR_CURSOR]   = tile_size * 3;
        offset [Tile.PLAYER1_CURSOR] = tile_size * 4;
        offset [Tile.PLAYER2_CURSOR] = tile_size * 5;

        refresh_pixmaps ();
        return true;
    }

    /*\
    * * drawing
    \*/

    protected override bool draw (Cairo.Context cr)
    {
        /* background */
        cr.save ();
        cr.translate (board_x, board_y);
        Gdk.cairo_set_source_pixbuf (cr, pb_bground, 0.0, 0.0);
        cr.rectangle (0.0, 0.0, board_size, board_size);
        cr.paint ();
        cr.restore ();

        /* tiles */
        for (uint8 row = 0; row < BOARD_ROWS_PLUS_ONE; row++)
            for (uint8 col = 0; col < BOARD_COLUMNS; col++)
                paint_tile (cr, row, col);

        /* grid */
        cr.save ();
        cr.translate (board_x, board_y);
        draw_grid (cr);
        cr.restore ();

        return false;
    }

    private inline void paint_tile (Cairo.Context cr, uint8 row, uint8 col)
    {
        PlayerID tile = game_board [row, col];
        if (tile == PlayerID.NOBODY && row != 0)
            return;

        int os = 0;
        if (row == 0)
            switch (tile)
            {
                case PlayerID.HUMAN   : os = offset [Tile.PLAYER1_CURSOR]; break;
                case PlayerID.OPPONENT: os = offset [Tile.PLAYER2_CURSOR]; break;
                case PlayerID.NOBODY  : os = offset [Tile.CLEAR_CURSOR];   break;
            }
        else
            switch (tile)
            {
                case PlayerID.HUMAN   : os = offset [Tile.PLAYER1]; break;
                case PlayerID.OPPONENT: os = offset [Tile.PLAYER2]; break;
                case PlayerID.NOBODY  : assert_not_reached ();
            }

        cr.save ();
        int x = col * tile_size + board_x;
        int y = row * tile_size + board_y;
        Gdk.cairo_set_source_pixbuf (cr, pb_tileset, x - os, y);
        cr.rectangle (x, y, tile_size, tile_size);

        cr.clip ();
        cr.paint ();
        cr.restore ();
    }

    private inline void draw_grid (Cairo.Context cr)
    {
        const double dashes [] = { 4.0, 4.0 };
        Gdk.RGBA color = Gdk.RGBA ();

        color.parse (theme [theme_id].grid_color);
        Gdk.cairo_set_source_rgba (cr, color);
        cr.set_operator (Cairo.Operator.SOURCE);
        cr.set_line_width (1.0);
        cr.set_line_cap (Cairo.LineCap.BUTT);
        cr.set_line_join (Cairo.LineJoin.MITER);
        cr.set_dash (dashes, /* offset */ 0.0);

        /* draw the grid on the background pixmap */
        for (uint8 i = 1; i < BOARD_SIZE; i++)
        {
            double line_offset = i * tile_size + 0.5;
            // vertical lines
            cr.move_to (line_offset, 0.0        );
            cr.line_to (line_offset, board_size );
            // horizontal lines
            cr.move_to (0.0        , line_offset);
            cr.line_to (board_size , line_offset);
        }
        cr.stroke ();

        /* Draw separator line at the top */
        cr.set_dash (null, /* offset */ 0.0);
        cr.move_to (0.0, tile_size + 0.5);
        cr.line_to (board_size, tile_size + 0.5);

        cr.stroke ();
    }

    /*\
    * * pixmaps
    \*/

    /* unscaled pixbufs */
    private Gdk.Pixbuf pb_tileset_raw;
    private Gdk.Pixbuf pb_bground_raw;

    /* scaled pixbufs */
    private Gdk.Pixbuf pb_tileset;
    private Gdk.Pixbuf pb_bground;

    private inline void change_theme ()
    {
        load_pixmaps ();
        refresh_pixmaps ();
    }

    private void refresh_pixmaps ()
    {
        if (tile_size == 0) // happens at game start
            return;

        Gdk.Pixbuf? tmp_pixbuf;

        tmp_pixbuf = pb_tileset_raw.scale_simple (tile_size * 6, tile_size, Gdk.InterpType.BILINEAR);
        if (tmp_pixbuf == null)
            assert_not_reached ();
        pb_tileset = (!) tmp_pixbuf;

        tmp_pixbuf = pb_bground_raw.scale_simple (board_size, board_size, Gdk.InterpType.BILINEAR);
        if (tmp_pixbuf == null)
            assert_not_reached ();
        pb_bground = (!) tmp_pixbuf;

        queue_draw ();
    }

    private void load_pixmaps ()
    {
        load_image (theme [theme_id].fname_tileset, out pb_tileset_raw);

        if (theme [theme_id].fname_bground != null)
            load_image ((!) theme [theme_id].fname_bground, out pb_bground_raw);
        else
            create_background ();
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
        int raw_tile_size = pb_tileset_raw.get_height ();

        pb_bground_raw = new Gdk.Pixbuf (Gdk.Colorspace.RGB, /* alpha */ true, /* bits per sample */ 8, raw_tile_size * BOARD_COLUMNS, raw_tile_size * BOARD_ROWS_PLUS_ONE);
        for (int i = 0; i < BOARD_COLUMNS; i++)
        {
            pb_tileset_raw.copy_area (raw_tile_size * 3, 0,
                                      raw_tile_size, raw_tile_size,
                                      pb_bground_raw,
                                      i * raw_tile_size, 0);

            for (int j = 1; j < BOARD_ROWS_PLUS_ONE; j++)
                pb_tileset_raw.copy_area (raw_tile_size * 2, 0,
                                          raw_tile_size, raw_tile_size,
                                          pb_bground_raw,
                                          i * raw_tile_size, j * raw_tile_size);
        }
    }

    /*\
    * * mouse play
    \*/

    /**
     * column_clicked:
     *
     * emited when a column on the game board is clicked
     *
     * @column:
     *
     * Which column was clicked on
     */
    internal signal bool column_clicked (uint8 column);

    protected override bool button_press_event (Gdk.EventButton e)
    {
        int x;
        int y;
        Gdk.Window? window = get_window ();
        if (window == null)
            assert_not_reached ();
        ((!) window).get_device_position (e.device, out x, out y, null);

        uint8 col;
        if (get_column (x, y, out col))
            return column_clicked (col);
        else
            return false;
    }

    private inline bool get_column (int x, int y, out uint8 col)
    {
        int _col = (x - board_x) / tile_size;
        if (x < board_x || y < board_y || _col < 0 || _col > BOARD_COLUMNS_MINUS_ONE)
        {
            col = 0;
            return false;
        }
        col = (uint8) _col;

        int row = (y - board_y) / tile_size;
        if (row < 0 || row > BOARD_ROWS)
            return false;

        return true;
    }
}
