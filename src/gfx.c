/* -*- mode:C; indent-tabs-mode:t; tab-width:8; c-basic-offset:8; -*- */

/* gfx.c
 *
 * Four-in-a-row for GNOME
 * (C) 2000 - 2004
 * Authors: Timothy Musson <trmusson@ihug.co.nz>
 *
 * This game is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
 * USA
 */



#include "config.h"
#include <gnome.h>
#include "main.h"
#include "theme.h"
#include "prefs.h"
#include "gfx.h"


extern Prefs      p;
extern Theme      theme[];
extern gint       gboard[7][7];
extern GtkWidget *app;
extern GtkWidget *drawarea;

static gint       width, height;
static gint       tilew, tileh;
static gint       offset[6];
static GdkPixbuf *pb_tileset = NULL;
static GdkPixbuf *pb_bground = NULL;
static GdkPixmap *pm_display = NULL;
static GdkPixmap *pm_bground = NULL;
GdkGC     *gc = NULL;



void
gfx_free (void)
{
	if (pb_tileset != NULL) {
		g_object_unref (pb_tileset);
		pb_tileset = NULL;
	}
	if (pb_bground != NULL) {
		g_object_unref (pb_bground);
		pb_bground = NULL;
	}
	if (pm_bground != NULL) {
		g_object_unref (pm_bground);
		pm_bground = NULL;
	}
	if (pm_display != NULL) {
		g_object_unref (pm_display);
		pm_display = NULL;
	}
}



gint
gfx_get_column (gint xpos)
{
	/* Derive column from pixel position */
	gint c = xpos / tilew;
	if (c > 6) c = 6;
	return c;
}



void
gfx_draw_tile (gint r, gint c, gboolean refresh)
{
	gint x = c * tilew;
	gint y = r * tileh;
	gint tile = gboard[r][c];
	gint os = 0;

	switch (tile) {
	case TILE_PLAYER1:
		os = offset[TILE_PLAYER1];
		if (y == 0) os = offset[TILE_PLAYER1_CURSOR];
		break;
	case TILE_PLAYER2:
		os = offset[TILE_PLAYER2];
		if (y == 0) os = offset[TILE_PLAYER2_CURSOR];
		break;
	default:
		break;
	}

	gdk_draw_drawable (pm_display, gc, pm_bground, x, y, x, y, tilew, tileh);

	if (tile != TILE_CLEAR) {
		gdk_pixbuf_render_to_drawable_alpha (pb_tileset, pm_display,
		  os, 0, x, y, tilew, tileh, GDK_PIXBUF_ALPHA_BILEVEL, 128,
		  GDK_RGB_DITHER_NORMAL, 0, 0);
	}

	if (refresh) {
		gtk_widget_queue_draw_area (drawarea, x, y, tilew, tileh);
	}
}


void
gfx_draw_all (gboolean refresh)
{
	gint r, c;

	for (r = 0; r < 7; r++) {
		for (c = 0; c < 7; c++) {
			gfx_draw_tile (r, c, FALSE);
		}
	}

	if (refresh) {
		gtk_widget_queue_draw_area (drawarea, 0, 0, width, height);
	}
}



void
gfx_expose (GdkRectangle *area)
{
	gdk_draw_drawable (drawarea->window, gc, pm_display,
	                   area->x, area->y, area->x, area->y,
	                   area->width, area->height);
}



void
gfx_draw_grid (void)
{
	GdkColormap *cmap;
	GdkColor color;
	gint i;

	if (theme[p.theme_id].grid_rgb == NULL) return;

	if (!gdk_color_parse (theme[p.theme_id].grid_rgb, &color)) {
		gdk_color_parse ("#727F8C", &color);
	}

	cmap = gtk_widget_get_colormap (drawarea);

	gdk_colormap_alloc_color (cmap, &color, FALSE, TRUE);
	gdk_gc_set_foreground (gc, &color);

	gdk_gc_set_line_attributes (gc, 0, theme[p.theme_id].grid_style,
	                            GDK_CAP_BUTT, GDK_JOIN_MITER);

	for (i = tilew; i < width; i = i + tilew) {
		gdk_draw_line (pm_bground, gc, i, 0, i, height);
	}
	for (i = tileh; i < width; i = i + tileh) {
		gdk_draw_line (pm_bground, gc, 0, i, width, i);
	}
	gdk_colormap_free_colors (cmap, &color, 1);
	g_object_unref (cmap);
}



static void
gfx_load_error (const gchar *fname)
{
	GtkWidget *dialog;

	dialog = gtk_message_dialog_new (GTK_WINDOW(app),
	                                 GTK_DIALOG_MODAL,
	                                 GTK_MESSAGE_WARNING,
	                                 GTK_BUTTONS_CLOSE,
	                                 _("Unable to load image:\n%s"), fname);

	gtk_dialog_run (GTK_DIALOG(dialog));
	gtk_widget_destroy (dialog);
}



gboolean
gfx_load (gint id)
{
	GdkPixbuf *pb_tileset_tmp;
	GdkPixbuf *pb_bground_tmp = NULL;
	gchar *dname;
	gchar *fname;

	dname = gnome_program_locate_file (NULL, GNOME_FILE_DOMAIN_APP_PIXMAP,
	                                   APPNAME, FALSE, NULL);

	fname = g_strdup_printf ("%s" G_DIR_SEPARATOR_S "%s", dname,
	                         theme[id].fname_tileset);

	pb_tileset_tmp = gdk_pixbuf_new_from_file (fname, NULL);
	if (pb_tileset_tmp == NULL) {
		gfx_load_error (fname);
		g_free (dname);
		g_free (fname);
		return FALSE;
	}
	g_free (fname);

	if (theme[id].fname_bground != NULL) {
		fname = g_strdup_printf ("%s" G_DIR_SEPARATOR_S "%s", dname,
		                         theme[id].fname_bground);
		pb_bground_tmp = gdk_pixbuf_new_from_file (fname, NULL);
		if (pb_bground_tmp == NULL) {
			gfx_load_error (fname);
			g_object_unref (pb_tileset_tmp);
			g_free (dname);
			g_free (fname);
			return FALSE;
		}
		g_free (fname);
	}
	g_free (dname);

	gfx_free ();
	p.theme_id = id;

	pb_tileset = pb_tileset_tmp;

	tilew = gdk_pixbuf_get_width (pb_tileset) / 6;
	tileh = gdk_pixbuf_get_height (pb_tileset);

	width = tilew * 7;
	height = tileh * 7;

	offset[TILE_PLAYER1]        = 0;
	offset[TILE_PLAYER2]        = tilew;
	offset[TILE_CLEAR]          = tilew * 2;
	offset[TILE_CLEAR_CURSOR]   = tilew * 3;
	offset[TILE_PLAYER1_CURSOR] = tilew * 4;
	offset[TILE_PLAYER2_CURSOR] = tilew * 5;

	if (pb_bground_tmp != NULL) {

		/* a separate background image was supplied */

		pb_bground = gdk_pixbuf_scale_simple (pb_bground_tmp, width, height, GDK_INTERP_BILINEAR);
		gdk_pixbuf_unref (pb_bground_tmp);
	}
	else {

		/* derive the background image from the tile set */

		gint i, j;

		pb_bground = gdk_pixbuf_new (GDK_COLORSPACE_RGB, TRUE, 8, width, height);
		for (i = 0; i < 7; i++) {
			gdk_pixbuf_copy_area (pb_tileset, offset[TILE_CLEAR_CURSOR], 0, tilew, tileh, pb_bground, i * tilew, 0);
			for (j = 1; j < 7; j++) {
				gdk_pixbuf_copy_area (pb_tileset, offset[TILE_CLEAR], 0, tilew, tileh, pb_bground, i * tilew, j * tileh);
			}
		}
	}

	pm_display = gdk_pixmap_new (app->window, width, height, -1);
	pm_bground = gdk_pixmap_new (app->window, width, height, -1);

	gdk_pixbuf_render_to_drawable (pb_bground, pm_bground, gc, 0, 0, 0, 0,
	                               width, height, GDK_RGB_DITHER_NORMAL, 0, 0);

	gtk_widget_set_size_request (GTK_WIDGET(drawarea), width, height);

	gfx_draw_grid ();
	gfx_draw_all (TRUE);

	scorebox_update (); /* update visible player descriptions */
	prompt_player ();

	return TRUE;
}

