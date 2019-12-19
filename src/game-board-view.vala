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

private class GameBoardView : Gtk.DrawingArea {
    private int board_size = 0;
    private int tile_size = 0;
    private int offset[6];
    /* unscaled pixbufs */
    private Gdk.Pixbuf pb_tileset_raw;
    private Gdk.Pixbuf pb_bground_raw;
    /* scaled pixbufs */
    private Gdk.Pixbuf pb_tileset;
    private Gdk.Pixbuf pb_bground;
    private Board game_board;

    internal GameBoardView(Board game_board) {
        halign = Gtk.Align.FILL;
        valign = Gtk.Align.FILL;

        events = Gdk.EventMask.EXPOSURE_MASK
               | Gdk.EventMask.BUTTON_PRESS_MASK
               | Gdk.EventMask.BUTTON_RELEASE_MASK;
        Prefs.instance.notify ["theme-id"].connect(() => change_theme());
        load_pixmaps();
        this.game_board = game_board;
    }

    internal inline void draw_tile(int r, int c) {
        queue_draw_area(c*tile_size + board_x, r*tile_size + board_y, tile_size, tile_size);
    }

    private int board_x;
    private int board_y;
    protected override bool configure_event(Gdk.EventConfigure e) {
        int allocated_width  = get_allocated_width ();
        int allocated_height = get_allocated_height ();
        int size = int.min (allocated_width, allocated_height);
        tile_size = size / 7;
        board_size = tile_size * 7;
        board_x = (allocated_width  - board_size) / 2;
        board_y = (allocated_height - board_size) / 2;

        offset[Tile.PLAYER1] = 0;
        offset[Tile.PLAYER2] = tile_size;
        offset[Tile.CLEAR] = tile_size * 2;
        offset[Tile.CLEAR_CURSOR] = tile_size * 3;
        offset[Tile.PLAYER1_CURSOR] = tile_size * 4;
        offset[Tile.PLAYER2_CURSOR] = tile_size * 5;

        refresh_pixmaps();
        queue_draw();
        return true;
    }

    private inline bool change_theme() {
        if (!load_pixmaps())
            return false;

        refresh_pixmaps();
        queue_draw();
        return true;
    }

    protected override bool draw(Cairo.Context cr) {
        int r, c;

        /* draw the background */
        cr.save();
        cr.translate(board_x, board_y);
        Gdk.cairo_set_source_pixbuf(cr, pb_bground, 0, 0);
        cr.rectangle(0, 0, board_size, board_size);
        cr.paint();
        cr.restore();

        for (r = 0; r < 7; r++) {
            for (c = 0; c < 7; c++) {
                paint_tile(cr, r, c);
            }
        }

        cr.save();
        cr.translate(board_x, board_y);
        draw_grid(cr);
        cr.restore();
        return false;
    }

    private inline void draw_grid(Cairo.Context cr) {
        const double dashes[] = { 4.0, 4.0 };
        int i;
        Gdk.RGBA color = Gdk.RGBA();

        color.parse(theme[Prefs.instance.theme_id].grid_color);
        Gdk.cairo_set_source_rgba(cr, color);
        cr.set_operator(Cairo.Operator.SOURCE);
        cr.set_line_width(1);
        cr.set_line_cap(Cairo.LineCap.BUTT);
        cr.set_line_join(Cairo.LineJoin.MITER);
        cr.set_dash(dashes, 0);

        /* draw the grid on the background pixmap */
        for (i = 1; i < 7; i++) {
            cr.move_to(i * tile_size + 0.5, 0);
            cr.line_to(i * tile_size + 0.5, board_size);
            cr.move_to(0, i * tile_size + 0.5);
            cr.line_to(board_size, i * tile_size + 0.5);
        }
        cr.stroke();

        /* Draw separator line at the top */
        cr.set_dash(null, 0);
        cr.move_to(0, tile_size + 0.5);
        cr.line_to(board_size, tile_size + 0.5);

        cr.stroke();
    }

    private void load_error(string fname) {
        Gtk.MessageDialog dialog;

        dialog = new Gtk.MessageDialog(get_window() as Gtk.Window, Gtk.DialogFlags.MODAL,
            Gtk.MessageType.WARNING, Gtk.ButtonsType.CLOSE,
        dgettext(GETTEXT_PACKAGE, "Unable to load image:\n%s"), fname);

        dialog.run();
        dialog.destroy();
    }

    private inline void paint_tile(Cairo.Context cr, int r, int c) {
        int x = c * tile_size + board_x;
        int y = r * tile_size + board_y;
        int tile = game_board [r, c];
        int os = 0;

        if (tile == Tile.CLEAR && r != 0)
            return;

        switch (tile) {
        case Tile.PLAYER1:
            if (r == 0)
                os = offset[Tile.PLAYER1_CURSOR];
            else
                os = offset[Tile.PLAYER1];
            break;
        case Tile.PLAYER2:
            if (r == 0)
                os = offset[Tile.PLAYER2_CURSOR];
            else
                os = offset[Tile.PLAYER2];
            break;
        case Tile.CLEAR:
            if (r == 0)
                os = offset[Tile.CLEAR_CURSOR];
            else
                os = offset[Tile.CLEAR];
            break;
        }

        cr.save();
        Gdk.cairo_set_source_pixbuf(cr, pb_tileset, x - os, y);
        cr.rectangle(x, y, tile_size, tile_size);

        cr.clip();
        cr.paint();
        cr.restore();
    }

    internal void refresh_pixmaps() {
        /* scale the pixbufs */
        Gdk.Pixbuf? pb_tileset_tmp = pb_tileset_raw.scale_simple(tile_size * 6, tile_size, Gdk.InterpType.BILINEAR);
        Gdk.Pixbuf? pb_bground_tmp = pb_bground_raw.scale_simple(board_size, board_size, Gdk.InterpType.BILINEAR);
        if (pb_tileset_tmp == null || pb_bground_tmp == null)
            assert_not_reached ();
        pb_tileset = (!) pb_tileset_tmp;
        pb_bground = (!) pb_bground_tmp;
    }

    private bool load_pixmaps() {
        string fname;
        Gdk.Pixbuf pb_tileset_tmp;
        Gdk.Pixbuf? pb_bground_tmp = null;

        /* Try the theme pixmaps, fallback to the default and then give up */
        while (true) {
            fname = "/org/gnome/Four-in-a-row/images/" + theme[Prefs.instance.theme_id].fname_tileset;
            try {
                pb_tileset_tmp = new Gdk.Pixbuf.from_resource(fname);
            } catch (Error e) {
                if (Prefs.instance.theme_id == 0)
                    load_error(fname);
                else
                    Prefs.instance.theme_id = 0;
                return false;
            }
            break;
        }

        pb_tileset_raw = pb_tileset_tmp;

        if (theme[Prefs.instance.theme_id].fname_bground != null) {
            fname = "/org/gnome/Four-in-a-row/images/" + ((!) theme[Prefs.instance.theme_id].fname_bground);
            try {
                pb_bground_tmp = new Gdk.Pixbuf.from_resource(fname);
            } catch (Error e) {
                load_error(fname);
                return false;
            }
        }

        /* If a separate background image wasn't supplied,
        * derive the background image from the tile set
        */
        if (pb_bground_tmp != null) {
            pb_bground_raw = (!) pb_bground_tmp;
        } else {
            int raw_tile_size;
            int i, j;

            raw_tile_size = pb_tileset_raw.get_height();

            pb_bground_raw = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8,
                raw_tile_size * 7, raw_tile_size * 7);
            for (i = 0; i < 7; i++) {
                pb_tileset_raw.copy_area(raw_tile_size * 3, 0,
                    raw_tile_size, raw_tile_size,
                    pb_bground_raw, i * raw_tile_size, 0);
                for (j = 1; j < 7; j++) {
                    pb_tileset_raw.copy_area(
                        raw_tile_size * 2, 0,
                        raw_tile_size, raw_tile_size,
                        pb_bground_raw,
                        i * raw_tile_size, j * raw_tile_size);
                }
            }
        }

        return true;
    }

    /**
     * column_clicked:
     *
     * emited when a column on the game board is clicked
     *
     * @column:
     *
     * Which column was clicked on
     */
    internal signal bool column_clicked(int column);

    protected override bool button_press_event(Gdk.EventButton e) {
        int x;
        int y;
        Gdk.Window? window = get_window();
        if (window == null)
            assert_not_reached ();
        ((!) window).get_device_position(e.device, out x, out y, null);

        int col;
        if (get_column(x, y, out col))
            return column_clicked(col);
        else
            return false;
    }
    private inline bool get_column(int x, int y, out int col) {
        col = (x - board_x) / tile_size;
        if (x < board_x || y < board_y || col < 0 || col > 6)
            return false;

        int row = (y - board_y) / tile_size;
        if (row < 0 || row > 6)
            return false;

        return true;
    }
}
