/*
 * gnect gfx.c
 *
 */



#include <gtk/gtk.h>
#include <gdk-pixbuf/gdk-pixbuf.h>

#include "config.h"
#include "main.h"
#include "gfx.h"
#include "gui.h"
#include "gnect.h"
#include "prefs.h"


#define DRAW_AREA_WIDTH       (tile_width * N_COLS)
#define DRAW_AREA_HEIGHT      (tile_height * N_ROWS)

#define ANIM_SPEED_DROP       15
#define ANIM_SPEED_SUCK       10
#define ANIM_SPEED_MOVE       15
#define ANIM_SPEED_WIPE       15
#define ANIM_SPEED_BLINK      100



extern gint      debugging;
extern Gnect     gnect;
extern Prefs     prefs;
extern Theme     *theme_current;
extern GtkWidget *draw_area;
extern GtkWidget *app;


static GdkPixbuf *pixbuf_background = NULL; /* original background image, scaled to window size */
static GdkPixbuf *pixbuf_tileset    = NULL; /* tile set image */
static GdkPixmap *pixmap_background = NULL; /* image of current background (with or without grid) */
static GdkPixmap *pixmap_display    = NULL; /* image of current board state */

static gint tile_offset[6];

gint tile_width;
gint tile_height;


Anim anim;


enum {
	ANIM_DROP = 1,
	ANIM_MOVE_LEFT,
	ANIM_MOVE_RIGHT,
	ANIM_SUCK,
	ANIM_BLINK_WINNER,
	ANIM_BLINK_COUNTER,
	ANIM_WIPE_1,
	ANIM_WIPE_2,
	ANIM_WIPE_3,
	ANIM_WIPE_4
};



void
gfx_expose (GdkRectangle *area)
{
	gdk_draw_drawable (draw_area->window, draw_area->style->black_gc,
					   pixmap_display,
					   area->x, area->y,
					   area->x, area->y,
					   area->width, area->height);
}



void
gfx_free (void)
{
	DEBUG_PRINT(1, "gfx_free\n");

	if (pixbuf_background) {
		gdk_pixbuf_unref (pixbuf_background);
		pixbuf_background = NULL;
	}
	if (pixbuf_tileset) {
		gdk_pixbuf_unref (pixbuf_tileset);
		pixbuf_tileset = NULL;
	}
	if (pixmap_background) {
		gdk_drawable_unref (pixmap_background);
		pixmap_background = NULL;
	}
	if (pixmap_display) {
		gdk_drawable_unref (pixmap_display);
		pixmap_display = NULL;
	}
}



void
gfx_draw_tile (gint row, gint col, gint tile_selector, gboolean do_refresh)
{
	gint x = col * tile_width;
	gint y = row * tile_height;
	gint offset = 0;


	switch (tile_selector) {

	case TILE_PLAYER_1 :
		if (y) offset = tile_offset[TILE_PLAYER_1];
		else offset = tile_offset[TILE_PLAYER_1_CURSOR];
		break;

	case TILE_PLAYER_2 :
		if (y) offset = tile_offset[TILE_PLAYER_2];
		else offset = tile_offset[TILE_PLAYER_2_CURSOR];
		break;

	default :
		break;

	}


	/* draw this cell's background */

	gdk_draw_drawable (pixmap_display, draw_area->style->black_gc,
					   pixmap_background, x, y, x, y,
					   tile_width, tile_height);


	if (tile_selector != TILE_CLEAR) {

		/* draw a player's counter */

		gdk_pixbuf_render_to_drawable_alpha (pixbuf_tileset, pixmap_display,
											 offset, 0, x, y, tile_width, tile_height,
											 GDK_PIXBUF_ALPHA_BILEVEL, 128,
											 GDK_RGB_DITHER_NORMAL, 0, 0);
	}


	if (do_refresh) {

		/* copy to draw_area */

		gdk_draw_drawable (draw_area->window, draw_area->style->black_gc, pixmap_display,
						   x, y, x, y, tile_width, tile_height);

	}
}



static void
gfx_draw_all_tiles (void)
{
	gint row, col;


	DEBUG_PRINT(1, "gfx_draw_all_tiles\n");
	for (row = 0; row < N_ROWS; row++) {
		for (col = 0; col < N_COLS; col++) {
			gfx_draw_tile (row, col, TILE_AT(row, col), FALSE);
		}
	}
}



void
gfx_redraw (gboolean do_refresh)
{
	DEBUG_PRINT(1, "gfx_redraw\n");
	gfx_draw_all_tiles ();
	if (do_refresh) gtk_widget_draw (draw_area, NULL);
}



static gint
gfx_timeout_animate (gpointer data)
{
	Anim *this_anim = (Anim *)data;


	switch (this_anim->action) {
	case ANIM_DROP :
	case ANIM_WIPE_3 :
	case ANIM_WIPE_4 :
		if (this_anim->row1) gfx_draw_tile (this_anim->row1, this_anim->col1, TILE_CLEAR, TRUE);
		this_anim->row1 = this_anim->row1 + 1;
		gfx_draw_tile (this_anim->row1, this_anim->col1, this_anim->player, TRUE);
		break;
	case ANIM_SUCK :
	case ANIM_WIPE_1 :
		gfx_draw_tile (this_anim->row1, this_anim->col1, TILE_CLEAR, TRUE);
		this_anim->row1 = this_anim->row1 - 1;
		if (this_anim->row1) {
			gfx_draw_tile (this_anim->row1, this_anim->col1, this_anim->player, TRUE);
		}
		break;
	case ANIM_MOVE_LEFT :
		gfx_draw_tile (this_anim->row1, this_anim->col1, TILE_CLEAR, TRUE);
		this_anim->col1 = this_anim->col1 - 1;
		gfx_draw_tile (this_anim->row1, this_anim->col1, this_anim->player, TRUE);
		break;
	case ANIM_MOVE_RIGHT :
		gfx_draw_tile (this_anim->row1, this_anim->col1, TILE_CLEAR, TRUE);
		this_anim->col1 = this_anim->col1 + 1;
		gfx_draw_tile (this_anim->row1, this_anim->col1, this_anim->player, TRUE);
		break;
	case ANIM_WIPE_2 :
		gfx_draw_tile (this_anim->row1, this_anim->col1, TILE_CLEAR, TRUE);
		this_anim->row1 = this_anim->row1 + 1;
		if (this_anim->row1 < N_ROWS) {
			gfx_draw_tile (this_anim->row1, this_anim->col1, this_anim->player, TRUE);
		}
		break;
	case ANIM_BLINK_COUNTER :
		if (this_anim->row2) {
			gfx_draw_tile (this_anim->row1, this_anim->col1, TILE_CLEAR, TRUE);
		}
		else {
			gfx_draw_tile (this_anim->row1, this_anim->col1, this_anim->player, TRUE);
		}
		this_anim->row2 = !this_anim->row2;
		break;
	default:
		break;
	}

	this_anim->count = this_anim->count - 1;

	if (this_anim->count < 1) {
		this_anim->id = 0;
		return FALSE;
	}
	return TRUE;
}



gint
gfx_drop_counter (gint col)
{
	/*
	 * Drop current_player's counter into column col,
	 * returning the row it landed in
	 */


	gint row = 1;


	while (row < N_ROWS-1 && gnect.board_state[CELL_AT(row + 1, col)] == TILE_CLEAR) {
		row++;
	}
	gnect.board_state[CELL_AT(row, col)] = gnect.current_player;

	if (prefs.do_animate) {

		anim.player = gnect.current_player;
		anim.action = ANIM_DROP;
		anim.row1   = 0;
		anim.col1   = col;
		anim.row2   = 0;
		anim.col2   = 0;
		anim.count  = row;
		anim.id     = gtk_timeout_add (ANIM_SPEED_DROP, (GtkFunction)gfx_timeout_animate, (gpointer)&anim);

		while (anim.id) gtk_main_iteration ();

	}
	else {

		gfx_draw_tile (row, col, gnect.current_player, TRUE);

	}

	return row;
}



void
gfx_move_cursor (gint col)
{
	/*
	 * Move current_player's cursor to col
	 */


	if (prefs.do_animate && col != gnect.cursor_col) {

		if (col < gnect.cursor_col) {
			anim.action = ANIM_MOVE_LEFT;
			anim.count = gnect.cursor_col - col;
		}
		else {
			anim.action = ANIM_MOVE_RIGHT;
			anim.count = col - gnect.cursor_col;
		}

		anim.player = gnect.current_player;
		anim.row1   = 0;
		anim.col1   = gnect.cursor_col;
		anim.row2   = 0;
		anim.col2   = 0;
		anim.id     = gtk_timeout_add (ANIM_SPEED_MOVE, (GtkFunction)gfx_timeout_animate, (gpointer)&anim);

		while (anim.id) gtk_main_iteration ();

		gnect.board_state[CELL_AT(0, gnect.cursor_col)] = TILE_CLEAR;

		gnect.cursor_col = col;

		gnect.board_state[CELL_AT(0, gnect.cursor_col)] = gnect.current_player;

	}
	else {

		gnect.board_state[CELL_AT(0, gnect.cursor_col)] = TILE_CLEAR;
		gfx_draw_tile(0, gnect.cursor_col, TILE_CLEAR, TRUE);

		gnect.cursor_col = col;

		gnect.board_state[CELL_AT(0, gnect.cursor_col)] = gnect.current_player;
		gfx_draw_tile (0, gnect.cursor_col, gnect.current_player, TRUE);

	}
}



void
gfx_suck_counter (gint col, gboolean is_wipe)
{
	/*
	 * Remove topmost counter from column
	 */

	gint row;


	row = gnect_get_top_used_row (col);
	if (row >= N_COLS) {
		return;
	}

	if (prefs.do_animate && row < N_COLS) {

		if (is_wipe) {
			anim.action = ANIM_SUCK;
		}
		else {
			anim.action = ANIM_WIPE_1;
		}

		anim.player = TILE_AT(row, col);
		anim.row1   = row;
		anim.col1   = col;
		anim.row2   = 0;
		anim.col2   = 0;
		anim.count  = row;
		anim.id     = gtk_timeout_add (ANIM_SPEED_SUCK, (GtkFunction)gfx_timeout_animate, (gpointer)&anim);

		while (anim.id) gtk_main_iteration ();

	}
	else {

		gfx_draw_tile (row, col, TILE_CLEAR, TRUE);

	}

	gnect.board_state[CELL_AT(row, col)] = TILE_CLEAR;
}



void
gfx_blink_counter (gint n_blinks, gint player, gint row, gint col)
{
	if (prefs.do_animate) {

		anim.player = player;
		anim.action = ANIM_BLINK_COUNTER;
		anim.row1   = row;
		anim.col1   = col;
		anim.row2   = FALSE;
		anim.col2   = 0;
		anim.count  = n_blinks * 2;
		anim.id     = gtk_timeout_add (ANIM_SPEED_BLINK, (GtkFunction)gfx_timeout_animate, (gpointer)&anim);

		while (anim.id) gtk_main_iteration ();
	}
}



static void
gfx_draw_line (gint r1, gint c1, gint r2, gint c2, gint tile)
{
	gint d_row    = 0;
	gint d_col    = 0;
	gboolean done = FALSE;


	if (r1 < r2) d_row = 1;
	else if (r1 > r2) d_row = -1;

	if (c1 < c2) d_col = 1;
	else if (c1 > c2) d_col = -1;

	while (!done) {

		done = (r1 == r2 && c1 == c2);

		gfx_draw_tile (r1, c1, tile, TRUE);

		if (r1 != r2) r1 += d_row;
		if (c1 != c2) c1 += d_col;

	}
}



static gint
gfx_timeout_blink_line (gpointer data)
{
	Anim *this_anim = (Anim *)data;
	static gint tile = -1;


	if (tile == TILE_CLEAR) {
		tile = this_anim->player;
	}
	else {
		tile = TILE_CLEAR;
	}

	gfx_draw_line (this_anim->row1, this_anim->col1, this_anim->row2, this_anim->col2, tile);

	this_anim->count = this_anim->count - 1;

	if (this_anim->count < 1 && tile != TILE_CLEAR) {
		tile = -1;
		this_anim->id = 0;
		return FALSE;
	}
	return TRUE;
}



static void
gfx_blink_line (gint n_blinks, gint r1, gint c1, gint r2, gint c2)
{
	anim.player = gnect.winner;
	anim.row1   = r1;
	anim.col1   = c1;
	anim.row2   = r2;
	anim.col2   = c2;
	anim.count  = n_blinks * 2;
	anim.id     = gtk_timeout_add (ANIM_SPEED_BLINK, (GtkFunction)gfx_timeout_blink_line, (gpointer)&anim);

	while (anim.id) gtk_main_iteration ();
}



void
gfx_blink_winner (gint n_blinks)
{
	/*
	 * Indicate all winning lines by blinking them on and off
	 */

	gint r1, c1, r2, c2;


	if (!prefs.do_animate || gnect.winner == -1) return;

	if (gnect_is_line_horizontal (gnect.winner, gnect.row, gnect.col, LINE_LENGTH, &r1, &c1, &r2, &c2)) {
		gfx_blink_line (n_blinks, r1, c1, r2, c2);
	}
	if (gnect_is_line_diagonal1 (gnect.winner, gnect.row, gnect.col, LINE_LENGTH, &r1, &c1, &r2, &c2)) {
		gfx_blink_line (n_blinks, r1, c1, r2, c2);
	}
	if (gnect_is_line_vertical (gnect.winner, gnect.row, gnect.col, LINE_LENGTH, &r1, &c1, &r2, &c2)) {
		gfx_blink_line (n_blinks, r1, c1, r2, c2);
	}
	if (gnect_is_line_diagonal2 (gnect.winner, gnect.row, gnect.col, LINE_LENGTH, &r1, &c1, &r2, &c2)) {
		gfx_blink_line (n_blinks, r1, c1, r2, c2);
	}

}



void
gfx_wipe_board (void)
{
	/*
	 * Pick a wipe effect at random to clear the display
	 */

	gint row, col, d;


	if (!prefs.do_animate || !prefs.do_wipes || gnect.veleng_str[2] == '\0') return;

	gui_set_hint_sensitive (FALSE);
	gui_set_undo_sensitive (FALSE);
	gui_set_new_sensitive (FALSE);

	col = 0;

	if ( (d = gnect_get_random_num (2)) == 2 ) {
		d = -1;
		col = N_COLS - 1;
	}

	switch (gnect_get_random_num (4)) {

	case 1 :
		while (gnect_undo_move(TRUE));
		break;

	case 2 :
		while (col > -1 && col < N_COLS) {

			row = gnect_get_top_used_row (col);

			anim.player = TILE_AT(row, col);
			anim.action = ANIM_WIPE_2;
			anim.row1   = row;
			anim.col1   = col;
			anim.row2   = 0;
			anim.col2   = 0;
			anim.count  = N_ROWS - row;
			anim.id     = gtk_timeout_add (ANIM_SPEED_WIPE, (GtkFunction)gfx_timeout_animate, (gpointer)&anim);

			while (anim.id) gtk_main_iteration ();

			col += d;

		}
		break;

	case 3 :
		while (col > -1 && col < N_COLS) {

			while ( (row = gnect_get_bottom_used_row (col)) ) {

				anim.player = TILE_AT(row, col);
				anim.action = ANIM_WIPE_3;
				anim.row1   = row;
				anim.col1   = col;
				anim.row2   = 0;
				anim.col2   = 0;
				anim.count  = N_ROWS - row;

				gnect.board_state[CELL_AT(row, col)] = TILE_CLEAR;

				anim.id     = gtk_timeout_add (ANIM_SPEED_WIPE, (GtkFunction)gfx_timeout_animate, (gpointer)&anim);

				while (anim.id) gtk_main_iteration ();

			}

			col += d;

		}
		break;

	case 4 :
		for (d = 0; d < N_COLS * N_COLS; d++) {

			col = gnect_get_random_num (N_COLS) - 1;

			while ( (row = gnect_get_bottom_used_row (col)) ) {

				anim.player = TILE_AT(row, col);
				anim.action = ANIM_WIPE_4;
				anim.row1   = row;
				anim.col1   = col;
				anim.row2   = 0;
				anim.col2   = 0;
				anim.count  = N_ROWS - row;

				gnect.board_state[CELL_AT(row, col)] = TILE_CLEAR;

				anim.id     = gtk_timeout_add (ANIM_SPEED_WIPE, (GtkFunction)gfx_timeout_animate, (gpointer)&anim);

				while (anim.id) gtk_main_iteration ();

			}

		}
		break;

	default :
		break;

	}

	gui_set_new_sensitive (TRUE);
}



static void
gfx_draw_grid (Theme *theme)
{
	GdkColormap *cmap;
	GdkGC *gc;
	GdkColor colour;
	gint x, y;


	if (!prefs.do_grids || !theme->gridRGB) return;

	DEBUG_PRINT(1, "gfx_draw_grid (%s)\n", theme->gridRGB);

	if (!gdk_color_parse (theme->gridRGB, &colour)) {
		WARNING_PRINT("gfx_draw_grid: bad RGB value (%s)\n", theme->gridRGB);
		return;
	}


	cmap = gtk_widget_get_colormap (draw_area);

	gc = gdk_gc_new (pixmap_display);

	gdk_color_alloc (cmap, &colour);
	gdk_gc_set_foreground (gc, &colour);

	for (x = tile_width; x < DRAW_AREA_WIDTH; x = x + tile_width) {
		gdk_draw_line (pixmap_background, gc, x, 0, x, DRAW_AREA_HEIGHT);
	}
	for (y = tile_height; y < DRAW_AREA_HEIGHT; y = y + tile_height) {
		gdk_draw_line (pixmap_background, gc, 0, y, DRAW_AREA_WIDTH, y);
	}

	gdk_gc_unref (gc);
}



void
gfx_toggle_grid (Theme *theme, gboolean do_grid)
{
	if (!theme->gridRGB) return;

	if (do_grid) {
		gfx_draw_grid (theme);
	}
	else {
		gdk_pixbuf_render_to_drawable (pixbuf_background, pixmap_background,
									   app->style->fg_gc[GTK_STATE_NORMAL],
									   0, 0, 0, 0, DRAW_AREA_WIDTH, DRAW_AREA_HEIGHT,
									   GDK_RGB_DITHER_NORMAL, 0, 0);
	}
	gfx_redraw (TRUE);
}



gboolean
gfx_load (Theme *theme, const gchar *fname_tileset, const gchar *fname_background)
{
	GdkPixbuf *pixbuf_tileset_tmp;
	GdkPixbuf *pixbuf_background_tmp;
	gint old_width = DRAW_AREA_WIDTH;
	gint old_height = DRAW_AREA_HEIGHT;


	DEBUG_PRINT(1, "gfx_load\n\ttile set:   %s\n\tbackground: %s\n", fname_tileset, fname_background);

	if ( !(pixbuf_tileset_tmp = gdk_pixbuf_new_from_file (fname_tileset, NULL)) ) {
		WARNING_PRINT("couldn't load tileset image (%s)\n", fname_tileset);
		return FALSE;
	}

	gfx_free ();

	pixbuf_tileset = pixbuf_tileset_tmp;

	tile_width  = gdk_pixbuf_get_width(pixbuf_tileset) / 6;
	tile_height = gdk_pixbuf_get_height(pixbuf_tileset);

	/* get a pixel offset for each tile in the set */
	tile_offset[TILE_PLAYER_1]        = 0;
	tile_offset[TILE_PLAYER_2]        = tile_width;
	tile_offset[TILE_CLEAR]           = tile_width * 2;
	tile_offset[TILE_CLEAR_CURSOR]    = tile_width * 3;
	tile_offset[TILE_PLAYER_1_CURSOR] = tile_width * 4;
	tile_offset[TILE_PLAYER_2_CURSOR] = tile_width * 5;


	if (fname_background) {

		/* get background image */

		if ( !(pixbuf_background_tmp = gdk_pixbuf_new_from_file (fname_background, NULL)) ) {
			WARNING_PRINT("couldn't load background image (%s)\n", fname_background);
		}
		else {

			/* scale background to match tile set */
			pixbuf_background = gdk_pixbuf_scale_simple (pixbuf_background_tmp,
														 DRAW_AREA_WIDTH, DRAW_AREA_HEIGHT,
														 GDK_INTERP_BILINEAR);
			gdk_pixbuf_unref (pixbuf_background_tmp);

		}

	}
	if (!pixbuf_background) {

		/* no background image, so build one using the tileset's 3rd
		 * (TILE_CLEAR) and 4th (TILE_CLEAR_CURSOR) tiles
		 */

		gint i, j;

		pixbuf_background = gdk_pixbuf_new (GDK_COLORSPACE_RGB, TRUE, 8, DRAW_AREA_WIDTH, DRAW_AREA_HEIGHT);

		for (i = 0; i < N_COLS; i++) {
			gdk_pixbuf_copy_area (pixbuf_tileset,
								  tile_offset[TILE_CLEAR_CURSOR], 0,
								  tile_width, tile_height,
								  pixbuf_background,
								  i * tile_width, 0);
		}

		for (i = 0; i < N_COLS; i++) {
			for (j = 1; j < N_ROWS; j++) {

				gdk_pixbuf_copy_area (pixbuf_tileset,
									  tile_offset[TILE_CLEAR], 0,
									  tile_width, tile_height,
									  pixbuf_background,
									  i * tile_width, j * tile_height);
			}
		}
	}

	pixmap_display = gdk_pixmap_new (app->window, DRAW_AREA_WIDTH, DRAW_AREA_HEIGHT, -1);
	pixmap_background = gdk_pixmap_new (app->window, DRAW_AREA_WIDTH, DRAW_AREA_HEIGHT, -1);

	gdk_pixbuf_render_to_drawable (pixbuf_background, pixmap_background,
								   app->style->fg_gc[GTK_STATE_NORMAL],
								   0, 0, 0, 0, DRAW_AREA_WIDTH, DRAW_AREA_HEIGHT,
								   GDK_RGB_DITHER_NORMAL, 0, 0);

	gfx_draw_grid (theme);



	/* update draw_area */

	if (DRAW_AREA_WIDTH != old_width || DRAW_AREA_HEIGHT != old_height) {
		gtk_widget_hide (draw_area);
		gtk_widget_set_usize (GTK_WIDGET(draw_area), DRAW_AREA_WIDTH, DRAW_AREA_HEIGHT);
	}

	gtk_widget_draw (draw_area, NULL);
	gfx_redraw (TRUE);

	if (DRAW_AREA_WIDTH != old_width || DRAW_AREA_HEIGHT != old_height) {
		gtk_widget_show (draw_area);
	}

	return TRUE;
}
