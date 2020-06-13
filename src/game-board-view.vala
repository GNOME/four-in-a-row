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

    [CCode (notify = false)] public Board        game_board    { private get; protected construct; }
    [CCode (notify = false)] public ThemeManager theme_manager { private get; protected construct; }

    internal GameBoardView (Board game_board, ThemeManager theme_manager)
    {
        Object (game_board: game_board, theme_manager: theme_manager);
    }

    construct
    {
        events = Gdk.EventMask.EXPOSURE_MASK
               | Gdk.EventMask.BUTTON_PRESS_MASK
               | Gdk.EventMask.BUTTON_RELEASE_MASK;
        theme_manager.theme_changed.connect (refresh_pixmaps);

        init_mouse ();
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
        tile_size = size / game_board.size;
        board_size = tile_size * game_board.size;
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
        for (uint8 row = 0; row < /* BOARD_ROWS_PLUS_ONE */ game_board.size; row++)
            for (uint8 col = 0; col < /* BOARD_COLUMNS */ game_board.size; col++)
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
        Player tile = game_board [row, col];
        if (tile == Player.NOBODY && row != 0)
            return;

        int os = 0;
        if (row == 0)
            switch (tile)
            {
                case Player.HUMAN   : os = offset [Tile.PLAYER1_CURSOR]; break;
                case Player.OPPONENT: os = offset [Tile.PLAYER2_CURSOR]; break;
                case Player.NOBODY  : os = offset [Tile.CLEAR_CURSOR];   break;
            }
        else
            switch (tile)
            {
                case Player.HUMAN   : os = offset [Tile.PLAYER1]; break;
                case Player.OPPONENT: os = offset [Tile.PLAYER2]; break;
                case Player.NOBODY  : assert_not_reached ();
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

        color.parse (theme_manager.get_grid_color ());
        Gdk.cairo_set_source_rgba (cr, color);
        cr.set_operator (Cairo.Operator.SOURCE);
        cr.set_line_width (1.0);
        cr.set_line_cap (Cairo.LineCap.BUTT);
        cr.set_line_join (Cairo.LineJoin.MITER);
        cr.set_dash (dashes, /* offset */ 0.0);

        /* draw the grid on the background pixmap */
        for (uint8 i = 1; i < /* BOARD_SIZE */ game_board.size; i++)
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

    /* scaled pixbufs */
    private Gdk.Pixbuf pb_tileset;
    private Gdk.Pixbuf pb_bground;

    private void refresh_pixmaps ()
    {
        if (tile_size == 0) // happens at game start
            return;

        Gdk.Pixbuf? tmp_pixbuf;

        tmp_pixbuf = theme_manager.pb_tileset_raw.scale_simple (tile_size * 6, tile_size, Gdk.InterpType.BILINEAR);
        if (tmp_pixbuf == null)
            assert_not_reached ();
        pb_tileset = (!) tmp_pixbuf;

        tmp_pixbuf = theme_manager.pb_bground_raw.scale_simple (board_size, board_size, Gdk.InterpType.BILINEAR);
        if (tmp_pixbuf == null)
            assert_not_reached ();
        pb_bground = (!) tmp_pixbuf;

        queue_draw ();
    }

    /*\
    * * mouse play
    \*/

    private Gtk.GestureMultiPress click_controller;     // for keeping in memory

    private inline void init_mouse ()
    {
        click_controller = new Gtk.GestureMultiPress (this);
        click_controller.set_button (/* all buttons */ 0);
        click_controller.pressed.connect (on_click);
    }

    /**
     * column_clicked:
     *
     * emitted when a column on the game board is clicked
     *
     * @column:
     *
     * Which column was clicked on
     */
    internal signal bool column_clicked (uint8 column);

    private inline void on_click (Gtk.GestureMultiPress _click_controller, int n_press, double event_x, double event_y)
    {
        uint button = _click_controller.get_current_button ();
        if (button != Gdk.BUTTON_PRIMARY && button != Gdk.BUTTON_SECONDARY)
            return;

        Gdk.Event? event = Gtk.get_current_event ();
        if (event == null && ((!) event).type != Gdk.EventType.BUTTON_PRESS)
            assert_not_reached ();

        int x;
        int y;
        Gdk.Window? window = get_window ();
        if (window == null)
            assert_not_reached ();
        ((!) window).get_device_position (((Gdk.EventButton) (!) event).device, out x, out y, null);

        uint8 col;
        if (get_column (x, y, out col))
            column_clicked (col);
    }

    private inline bool get_column (int x, int y, out uint8 col)
    {
        int _col = (x - board_x) / tile_size;
        if (x < board_x || y < board_y || _col < 0 || _col > /* BOARD_COLUMNS_MINUS_ONE */ game_board.size - 1)
        {
            col = 0;
            return false;
        }
        col = (uint8) _col;

        int row = (y - board_y) / tile_size;
        if (row < 0 || row > /* BOARD_ROWS */ game_board.size - 1)
            return false;

        return true;
    }
}
