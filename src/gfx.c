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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */



#include <config.h>

#include <glib.h>
#include <glib/gi18n.h>
#include <gtk/gtk.h>

#include "main.h"
#include "theme.h"
#include "prefs.h"
#include "gfx.h"


extern Prefs p;
extern Theme theme[];
extern gint gboard[7][7];
extern GtkWidget *window;
extern GtkWidget *drawarea;

gint boardsize = 0;
gint tilesize = 0;
gint offset[6];

/* unscaled pixbufs */
GdkPixbuf *pb_tileset_raw = NULL;
GdkPixbuf *pb_bground_raw = NULL;

/* scaled pixbufs */
GdkPixbuf *pb_tileset = NULL;
GdkPixbuf *pb_bground = NULL;

void
gfx_free (void)
{
  if (pb_tileset_raw != NULL) {
    g_object_unref (pb_tileset_raw);
    pb_tileset = NULL;
  }
  if (pb_bground_raw != NULL) {
    g_object_unref (pb_bground_raw);
    pb_bground = NULL;
  }
  if (pb_tileset != NULL) {
    g_object_unref (pb_tileset);
    pb_tileset = NULL;
  }
  if (pb_bground != NULL) {
    g_object_unref (pb_bground);
    pb_bground = NULL;
  }
}

gboolean
gfx_load_pixmaps (void)
{
  gchar *fname;
  GdkPixbuf *pb_tileset_tmp;
  GdkPixbuf *pb_bground_tmp = NULL;

  /* Try the theme pixmaps, fallback to the default and then give up */
  while (TRUE) {
    fname = g_build_filename (DATA_DIRECTORY, theme[p.theme_id].fname_tileset, NULL);
    pb_tileset_tmp = gdk_pixbuf_new_from_file (fname, NULL);
    if (pb_tileset_tmp == NULL) {
      if (p.theme_id != 0) {
	p.theme_id = 0;
	g_free (fname);
	continue;
      } else {
	gfx_load_error (fname);
	g_free (fname);
	return FALSE;
      }
    }

    g_free (fname);
    break;
  }

  if (pb_tileset_raw)
    g_object_unref (pb_tileset_raw);

  pb_tileset_raw = pb_tileset_tmp;

  if (theme[p.theme_id].fname_bground != NULL) {
    fname = g_build_filename (DATA_DIRECTORY, theme[p.theme_id].fname_bground, NULL);
    pb_bground_tmp = gdk_pixbuf_new_from_file (fname, NULL);
    if (pb_bground_tmp == NULL) {
      gfx_load_error (fname);
      g_object_unref (pb_tileset_tmp);
      g_free (fname);
      return FALSE;
    }
    g_free (fname);
  }

  if (pb_bground_raw)
    g_object_unref (pb_bground_raw);

  /* If a separate background image wasn't supplied,
   * derive the background image from the tile set
   */
  if (pb_bground_tmp != NULL) {
    pb_bground_raw = pb_bground_tmp;
  } else {
    gint tilesize_raw;
    gint i, j;

    tilesize_raw = gdk_pixbuf_get_height (pb_tileset_raw);

    pb_bground_raw = gdk_pixbuf_new (GDK_COLORSPACE_RGB, TRUE, 8,
				     tilesize_raw * 7, tilesize_raw * 7);
    for (i = 0; i < 7; i++) {
      gdk_pixbuf_copy_area (pb_tileset_raw,
			    tilesize_raw * 3, 0,
			    tilesize_raw, tilesize_raw,
			    pb_bground_raw, i * tilesize_raw, 0);
      for (j = 1; j < 7; j++) {
	gdk_pixbuf_copy_area (pb_tileset_raw,
			      tilesize_raw * 2, 0,
			      tilesize_raw, tilesize_raw,
			      pb_bground_raw,
			      i * tilesize_raw, j * tilesize_raw);
      }
    }
  }

  return TRUE;
}
