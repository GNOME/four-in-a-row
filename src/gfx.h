/*
 * gnect gfx.h
 *
 */



#ifndef _GNECT_GFX_H_
#define _GNECT_GFX_H_


#include <gdk/gdk.h>
#include "theme.h"


typedef struct _Anim Anim;

struct _Anim {
	gint  player;
	gint  action;
	gint  row1;
	gint  col1;
	gint  row2;
	gint  col2;
	gint  count;
	guint id;
};



void     gfx_free(void);
gboolean gfx_load(Theme *theme, const gchar *fname_tileset, const gchar *fname_background);
void     gfx_expose(GdkRectangle *area);
void     gfx_redraw(gboolean do_refresh);
void     gfx_toggle_grid(Theme *theme, gboolean do_grid);
void     gfx_move_cursor(gint col);
gint     gfx_drop_counter(gint col);
void     gfx_suck_counter(gint col, gboolean is_wipe);
void     gfx_blink_counter(gint n_blinks, gint player, gint row, gint col);
void     gfx_blink_winner(gint n_blinks);
void     gfx_wipe_board(void);


#endif
