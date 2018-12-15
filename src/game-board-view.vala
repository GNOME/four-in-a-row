/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* game-board-view.vala
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

class GameBoardView : Gtk.DrawingArea {
    int boardsize = 0;
    int tilesize = 0;
    int offset[6];
    /* unscaled pixbufs */
    Gdk.Pixbuf pb_tileset_raw;
    Gdk.Pixbuf pb_bground_raw;
    /* scaled pixbufs */
    Gdk.Pixbuf pb_tileset;
    Gdk.Pixbuf pb_bground;
    //public Gtk.DrawingArea drawarea;

    static Once<GameBoardView> _instance;
    public static GameBoardView instance {
        get {
            return _instance.once(() => {return new GameBoardView();});
        }
    }

    public GameBoardView() {
        Object();
        /* set a min size to avoid pathological behavior of gtk when scaling down */
        set_size_request(350, 350);
        halign = Gtk.Align.FILL;
        valign = Gtk.Align.FILL;

        events = Gdk.EventMask.EXPOSURE_MASK |
                          Gdk.EventMask.BUTTON_PRESS_MASK |
                          Gdk.EventMask.BUTTON_RELEASE_MASK;
    }

    public int get_column(int xpos) {
        /* Derive column from pixel position */
        int c = xpos / tilesize;
        if (c > 6)
            c = 6;
        if (c < 0)
            c = 0;

        return c;
    }

    public void draw_tile(int r, int c) {
        queue_draw_area(c*tilesize, r*tilesize, tilesize, tilesize);
    }

    public void draw_all() {
        queue_draw_area(0, 0, boardsize, boardsize);
    }

    protected override bool configure_event(Gdk.EventConfigure e) {
        int width, height;

        width = get_allocated_width();
        height = get_allocated_height();

        boardsize = int.min(width, height);
        tilesize = boardsize / 7;

        offset[Tile.PLAYER1] = 0;
        offset[Tile.PLAYER2] = tilesize;
        offset[Tile.CLEAR] = tilesize * 2;
        offset[Tile.CLEAR_CURSOR] = tilesize * 3;
        offset[Tile.PLAYER1_CURSOR] = tilesize * 4;
        offset[Tile.PLAYER2_CURSOR] = tilesize * 5;

        refresh_pixmaps();
        draw_all();
        return true;
    }

     public bool change_theme() {
        if (!load_pixmaps())
            return false;

        refresh_pixmaps();
        instance.draw_all();
        return true;
    }

    protected override bool draw(Cairo.Context cr) {
        int r, c;

        /* draw the background */
        cr.save();
        Gdk.cairo_set_source_pixbuf(cr, pb_bground, 0, 0);
        cr.rectangle(0, 0, boardsize, boardsize);
        cr.paint();
        cr.restore();

        for (r = 0; r < 7; r++) {
            for (c = 0; c < 7; c++) {
                paint_tile(cr, r, c);
            }
        }

        draw_grid(cr);
        return false;
    }

    void draw_grid(Cairo.Context cr) {
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
            cr.move_to(i * tilesize + 0.5, 0);
            cr.line_to(i * tilesize + 0.5, boardsize);
            cr.move_to(0, i * tilesize + 0.5);
            cr.line_to(boardsize, i * tilesize + 0.5);
        }
        cr.stroke();

        /* Draw separator line at the top */
        cr.set_dash(null, 0);
        cr.move_to(0, tilesize+0.5);
        cr.line_to(boardsize, tilesize +0.5);

        cr.stroke();
    }

    void load_error(string fname) {
        Gtk.MessageDialog dialog;

        dialog = new Gtk.MessageDialog(window, Gtk.DialogFlags.MODAL,
            Gtk.MessageType.WARNING, Gtk.ButtonsType.CLOSE,
        dgettext(Config.GETTEXT_PACKAGE, "Unable to load image:\n%s"), fname);

        dialog.run();
        dialog.destroy();
    }

    void paint_tile(Cairo.Context cr, int r, int c) {
        int x = c * tilesize;
        int y = r * tilesize;
        int tile = Board.instance.get(r, c);
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
        cr.rectangle(x, y, tilesize, tilesize);

        cr.clip();
        cr.paint();
        cr.restore();
    }

    public void refresh_pixmaps() {
        /* scale the pixbufs */
        pb_tileset = pb_tileset_raw.scale_simple(tilesize * 6, tilesize, Gdk.InterpType.BILINEAR);
        pb_bground = pb_bground_raw.scale_simple(boardsize, boardsize, Gdk.InterpType.BILINEAR);
    }

    public bool load_pixmaps() {
        string fname;
        Gdk.Pixbuf pb_tileset_tmp;
        Gdk.Pixbuf pb_bground_tmp = null;

        /* Try the theme pixmaps, fallback to the default and then give up */
        while (true) {
            fname = Path.build_filename(Config.DATA_DIRECTORY, theme[Prefs.instance.theme_id].fname_tileset, null);
            try {
                pb_tileset_tmp = new Gdk.Pixbuf.from_file(fname);
            } catch (Error e) {
                if (Prefs.instance.theme_id != 0) {
                    Prefs.instance.theme_id = 0;
                    continue;
                } else {
                    load_error(fname);
                    return false;
                }
            }
            break;
        }

        pb_tileset_raw = pb_tileset_tmp;

        if (theme[Prefs.instance.theme_id].fname_bground != null) {
            fname = Path.build_filename(Config.DATA_DIRECTORY, theme[Prefs.instance.theme_id].fname_bground, null);
            try {
                pb_bground_tmp = new Gdk.Pixbuf.from_file(fname);
            } catch (Error e) {
                load_error(fname);
                return false;
            }
        }

        /* If a separate background image wasn't supplied,
        * derive the background image from the tile set
        */
        if (pb_bground_tmp != null) {
            pb_bground_raw = pb_bground_tmp;
        } else {
            int tilesize_raw;
            int i, j;

            tilesize_raw = pb_tileset_raw.get_height();

            pb_bground_raw = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8,
                tilesize_raw * 7, tilesize_raw * 7);
            for (i = 0; i < 7; i++) {
                pb_tileset_raw.copy_area(tilesize_raw * 3, 0,
                    tilesize_raw, tilesize_raw,
                    pb_bground_raw, i * tilesize_raw, 0);
                for (j = 1; j < 7; j++) {
                    pb_tileset_raw.copy_area(
                        tilesize_raw * 2, 0,
                        tilesize_raw, tilesize_raw,
                        pb_bground_raw,
                        i * tilesize_raw, j * tilesize_raw);
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
    public signal bool column_clicked(int column);

    protected override bool button_press_event(Gdk.EventButton e) {
        int x;
        get_window().get_device_position(e.device, out x, null, null);
        return column_clicked(get_column(x));
    }

}


