//using GETTTEXT_PACKAGE_CONTENT;
const string GETTEXT_PACKAGE2 = Config.GETTEXT_PACKAGE;
Gtk.Widget drawarea;
//extern Theme theme[];
int[,] gboard;
int boardsize = 0;
int tilesize = 0;
int offset[6];

namespace Gfx{
	/* unscaled pixbufs */
	Gdk.Pixbuf pb_tileset_raw;
	Gdk.Pixbuf pb_bground_raw;

	/* scaled pixbufs */
	Gdk.Pixbuf pb_tileset;
	Gdk.Pixbuf pb_bground;

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
		if (!Gfx.load_pixmaps ())
			return false;

		Gfx.refresh_pixmaps ();
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

		Gfx.refresh_pixmaps ();
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
				Gfx.paint_tile (cr, r, c);
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
	Gdk.cairo_set_source_pixbuf (cr, pb_tileset, x - os, y);
	cr.rectangle (x, y, tilesize, tilesize);

	cr.clip();
	cr.paint();
	cr.restore();
    }

	void refresh_pixmaps () {
		/* scale the pixbufs */
		pb_tileset = pb_tileset_raw.scale_simple (tilesize * 6, tilesize, Gdk.InterpType.BILINEAR);
		pb_bground = pb_bground_raw.scale_simple (boardsize, boardsize, Gdk.InterpType.BILINEAR);
	}



bool load_pixmaps ()
{
	string fname;
	Gdk.Pixbuf pb_tileset_tmp;
	Gdk.Pixbuf pb_bground_tmp = null;

	/* Try the theme pixmaps, fallback to the default and then give up */
	while (true) {
		fname = Path.build_filename (Config.DATA_DIRECTORY, theme[p.theme_id].fname_tileset, null);
		try {
			pb_tileset_tmp = new Gdk.Pixbuf.from_file (fname);
		} catch (Error e) {
			if (p.theme_id != 0) {
				p.theme_id = 0;
				continue;
			} else {
				Gfx.load_error (fname);
				return false;
			}
		}
		break;
	}

	pb_tileset_raw = pb_tileset_tmp;

	if (theme[p.theme_id].fname_bground != null) {
		fname = Path.build_filename (Config.DATA_DIRECTORY, theme[p.theme_id].fname_bground, null);
		try {
			pb_bground_tmp = new Gdk.Pixbuf.from_file (fname);
		} catch (Error e) {
			Gfx.load_error (fname);
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

		pb_bground_raw = new Gdk.Pixbuf (Gdk.Colorspace.RGB, true, 8,
			tilesize_raw * 7, tilesize_raw * 7);
		for (i = 0; i < 7; i++) {
			pb_tileset_raw.copy_area (tilesize_raw * 3, 0,
				tilesize_raw, tilesize_raw,
				pb_bground_raw, i * tilesize_raw, 0);
			for (j = 1; j < 7; j++) {
				pb_tileset_raw.copy_area (
					tilesize_raw * 2, 0,
					tilesize_raw, tilesize_raw,
					pb_bground_raw,
					i * tilesize_raw, j * tilesize_raw);
			}
		}
	}

	return true;
}

	void free ()
	{
		if (pb_tileset_raw != null) {
			pb_tileset_raw.unref();
			pb_tileset_raw = null;
		}
		if (pb_bground_raw != null) {
			pb_bground_raw.unref();
			pb_bground_raw = null;
		}
		if (pb_tileset != null) {
			pb_tileset.unref();
			pb_tileset = null;
		}
		if (pb_bground != null) {
			pb_bground.unref();
			pb_bground = null;
		}
	}

}
