//using GETTTEXT_PACKAGE_CONTENT;
const string GETTEXT_PACKAGE2 = Config.GETTEXT_PACKAGE;
extern int boardsize;
extern int tilesize;
extern int offset[6];
extern Gtk.Widget drawarea;
extern Gdk.Pixbuf? pb_bground;
extern Gdk.Pixbuf? pb_tileset;
extern Gdk.Pixbuf? pb_tileset_raw;
extern Gdk.Pixbuf? pb_bground_raw;
//extern Theme theme[];
int[,] gboard;

namespace Gfx{
    public int get_column (int xpos) {
        /* Derive column from pixel position */
        int c = xpos / tilesize;
        if (c > 6)
            c = 6;
        if (c < 0)
            c = 0;

        return c;
    }

    public void draw_tile (int r, int c) {
	    drawarea.queue_draw_area(c*tilesize, r*tilesize, tilesize, tilesize);
    }

    public void draw_all () {
        drawarea.queue_draw_area(0, 0, boardsize, boardsize);
    }

    bool change_theme () {
        if (!gfx_load_pixmaps ())
            return false;

        gfx_refresh_pixmaps ();
        draw_all ();
        return true;
    }

    void resize (Gtk.Widget w) {
        int width, height;

        width = w.get_allocated_width ();
        height = w.get_allocated_height ();

        boardsize = int.min (width, height);
        tilesize = boardsize / 7;

        offset[Tile.PLAYER1] = 0;
        offset[Tile.PLAYER2] = tilesize;
        offset[Tile.CLEAR] = tilesize * 2;
        offset[Tile.CLEAR_CURSOR] = tilesize * 3;
        offset[Tile.PLAYER1_CURSOR] = tilesize * 4;
        offset[Tile.PLAYER2_CURSOR] = tilesize * 5;

        gfx_refresh_pixmaps ();
        draw_all ();
    }

    void expose (Cairo.Context cr) {
        int r, c;

        /* draw the background */
        cr.save();
        Gdk.cairo_set_source_pixbuf(cr, pb_bground, 0, 0);
        cr.rectangle(0, 0, boardsize, boardsize);
        cr.paint();
        cr.restore();

        for (r = 0; r < 7; r++) {
            for (c = 0; c < 7; c++) {
                gfx_paint_tile (cr, r, c);
            }
        }

        draw_grid (cr);
    }

    void draw_grid (Cairo.Context cr) {
        const double dashes[] = { 4.0, 4.0 };
        int i;
        Gdk.RGBA color = Gdk.RGBA();

        color.parse(theme[p.theme_id].grid_color);
        Gdk.cairo_set_source_rgba (cr, color);
        cr.set_operator (Cairo.Operator.SOURCE);
        cr.set_line_width (1);
        cr.set_line_cap (Cairo.LineCap.BUTT);
        cr.set_line_join (Cairo.LineJoin.MITER);
        cr.set_dash (dashes, 0);

        /* draw the grid on the background pixmap */
        for (i = 1; i < 7; i++) {
            cr.move_to (i * tilesize + 0.5, 0);
            cr.line_to (i * tilesize + 0.5, boardsize);
            cr.move_to (0, i * tilesize + 0.5);
            cr.line_to (boardsize, i * tilesize + 0.5);
        }
        cr.stroke();

        /* Draw separator line at the top */
        cr.set_dash(null, 0);
        cr.move_to(0, tilesize+0.5);
        cr.line_to(boardsize, tilesize +0.5);

        cr.stroke();
    }

    void load_error (string fname) {
        Gtk.MessageDialog dialog;

        dialog = new Gtk.MessageDialog(window, Gtk.DialogFlags.MODAL,
            Gtk.MessageType.WARNING, Gtk.ButtonsType.CLOSE,
        dgettext(Config.GETTEXT_PACKAGE, "Unable to load image:\n%s"), fname);

        dialog.run();
        dialog.destroy();
    }

    void paint_tile (Cairo.Context cr, int r, int c) {
        int x = c * tilesize;
        int y = r * tilesize;
        int tile = gboard[r,c];
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
        //gdk_cairo_set_source_pixbuf (cr, pb_tileset, x - os, y);
        cr.rectangle (x, y, tilesize, tilesize);

        cr.clip();
        cr.paint();
        cr.restore();
    }

    void refresh_pixmaps () {
        /* scale the pixbufs */
        if (pb_tileset != null)
            pb_tileset.unref();
        if (pb_bground != null)
            g_object_unref (pb_bground);

        pb_tileset = pb_tileset_raw.scale_simple (tilesize * 6, tilesize, Gdk.InterpType.BILINEAR);
        pb_bground = pb_bground_raw.scale_simple (boardsize, boardsize, Gdk.InterpType.BILINEAR);
    }

}
