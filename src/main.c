/* -*- mode:C; indent-tabs-mode:t; tab-width:8; c-basic-offset:8; -*- */

/* main.c
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
#include <gconf/gconf-client.h>
#include "connect4.h"
#include "main.h"
#include "theme.h"
#include "prefs.h"
#include "gfx.h"


#define SIZE_VSTR      53

#define SPEED_MOVE     25
#define SPEED_DROP     20
#define SPEED_BLINK    150

extern GConfClient *conf_client;
extern Prefs p;

GtkWidget *app;
GtkWidget *drawarea;
GtkWidget *appbar;
GtkWidget *scorebox = NULL;
GdkGC     *gc;

GtkWidget *label_name[3];
GtkWidget *label_score[3];

GnomeUIInfo game_menu_uiinfo[];
GnomeUIInfo settings_menu_uiinfo[];
GnomeUIInfo help_menu_uiinfo[];
GnomeUIInfo menubar_uiinfo[];
GnomeUIInfo toolbar[];

gchar     *fname_icon = NULL;

PlayerID  player;
PlayerID  winner;
PlayerID  who_starts;
gboolean  gameover;
gint      moves;
gint      score[3];
gint      column;
gint      column_moveto;
gint      row;
gint      row_dropto;
gint      timeout;

gint          gboard[7][7];
gchar         vstr[SIZE_VSTR];
gchar         vlevel[] = "0abc";
struct board *vboard;

typedef enum {
	ANIM_NONE,
	ANIM_MOVE,
	ANIM_DROP,
	ANIM_BLINK
} AnimID;

AnimID anim;

gint blink_r1, blink_c1;
gint blink_r2, blink_c2;
gint blink_t;
gint blink_n;
gboolean blink_on;


static void process_move (gint c);


static void
clear_board (void)
{
	gint r, c, i;

	for (r = 0; r < 7; r++) {
		for (c = 0; c < 7; c++) {
			gboard[r][c] = TILE_CLEAR;
		}
	}

	for (i = 0; i < SIZE_VSTR; i++) vstr[i] = '\0';

	vstr[0] = vlevel[LEVEL_WEAK];
	vstr[1] = '0';
	moves = 0;
}



static gint
first_empty_row (gint c)
{
	gint r = 1;

	while (r < 7 && gboard[r][c] == TILE_CLEAR) r++;
	return r - 1;
}



gint
get_random_int (gint n)
{
	/* Return a random integer in the range 1..n */
	return (gint) g_random_int_range (1, n + 1);
}



static gint
get_n_human_players (void)
{
	if (p.level[PLAYER1] != LEVEL_HUMAN && p.level[PLAYER2] != LEVEL_HUMAN) {
		return 0;
	}
	if (p.level[PLAYER1] != LEVEL_HUMAN || p.level[PLAYER2] != LEVEL_HUMAN) {
		return 1;
	}
	return 2;
}



static gboolean
is_player_human (void)
{
	if (player == PLAYER1) {
		return p.level[PLAYER1] == LEVEL_HUMAN;
	}
	return p.level[PLAYER2] == LEVEL_HUMAN;
}



static void
drop_marble (gint r, gint c)
{
	gint tile;

	if (player == PLAYER1) tile = TILE_PLAYER1;
	else tile = TILE_PLAYER2;

	gboard[r][c] = tile;
	gfx_draw_tile (r, c, TRUE);

	column = column_moveto = c;
	row = row_dropto = r;
}



static void
drop (void)
{
	gint tile;

	if (player == PLAYER1) tile = TILE_PLAYER1;
	else tile = TILE_PLAYER2;

	gboard[row][column] = TILE_CLEAR;
	gfx_draw_tile (row, column, TRUE);

	row++;
	gboard[row][column] = tile;
	gfx_draw_tile (row, column, TRUE);
}



static void
move_cursor (gint c)
{
	gboard[0][column] = TILE_CLEAR;
	gfx_draw_tile (0, column, TRUE);

	column = c;

	if (player == PLAYER1) gboard[0][c] = TILE_PLAYER1;
	else gboard[0][c] = TILE_PLAYER2;

	gfx_draw_tile (0, c, TRUE);

	column = column_moveto = c;
	row = row_dropto = 0;
}



static void
move (gint c)
{
	gboard[0][column] = TILE_CLEAR;
	gfx_draw_tile (0, column, TRUE);

	column = c;

	if (player == PLAYER1) gboard[0][c] = TILE_PLAYER1;
	else gboard[0][c] = TILE_PLAYER2;

	gfx_draw_tile (0, c, TRUE);
}



static void
draw_line (gint r1, gint c1, gint r2, gint c2, gint tile)
{
	/* draw a line of 'tile' from r1,c1 to r2,c2 */

	gboolean done = FALSE;
	gint d_row = 0;
	gint d_col = 0;

	if (r1 < r2) d_row = 1;
	else if (r1 > r2) d_row = -1;

	if (c1 < c2) d_col = 1;
	else if (c1 > c2) d_col = -1;

	do {
		done = (r1 == r2 && c1 == c2);
		gboard[r1][c1] = tile;
		gfx_draw_tile (r1, c1, TRUE);
		if (r1 != r2) r1 += d_row;
		if (c1 != c2) c1 += d_col;
	} while (!done);
}



static gboolean
on_animate (gpointer data)
{
	if (anim == ANIM_NONE) return FALSE;

	switch (anim) {
	case ANIM_NONE:
		break;
	case ANIM_MOVE:
		if (column < column_moveto) {
			move (column + 1);
		}
		else if (column > column_moveto) {
			move (column - 1);
		}
		else {
			anim = ANIM_NONE;
			timeout = 0;
			return FALSE;
		}
		break;
	case ANIM_DROP:
		if (row < row_dropto) {
			drop ();
		}
		else {
			anim = ANIM_NONE;
			timeout = 0;
			return FALSE;
		}
		break;
	case ANIM_BLINK:
		if (blink_on) draw_line (blink_r1, blink_c1, blink_r2, blink_c2, blink_t);
		else draw_line (blink_r1, blink_c1, blink_r2, blink_c2, TILE_CLEAR);
		blink_n--;
		if (blink_n <= 0 && blink_on) {
			anim = ANIM_NONE;
			timeout = 0;
			return FALSE;
		}
		blink_on = !blink_on;
		break;
	}
	return TRUE;
}



static void
blink_tile (gint r, gint c, gint t, gint n)
{
	if (timeout) return;
	blink_r1 = r; blink_c1 = c;
	blink_r2 = r; blink_c2 = c;
	blink_t = t;
	blink_n = n;
	blink_on = FALSE;
	anim = ANIM_BLINK;
	timeout = gtk_timeout_add (SPEED_BLINK, on_animate, NULL);
}



static void
swap_player (void)
{
	player = (player == PLAYER1) ? PLAYER2 : PLAYER1;
	move_cursor (column);
	prompt_player ();
}



static void
set_status (StatusID id, const gchar *s)
{
	switch (id) {
	case STATUS_CLEAR:
		gnome_appbar_clear_stack (GNOME_APPBAR(appbar));
		gnome_appbar_refresh (GNOME_APPBAR(appbar));
		return;
	case STATUS_FLASH:
		gnome_app_flash (GNOME_APP(app), s);
		return;
	case STATUS_SET:
		gnome_appbar_pop (GNOME_APPBAR(appbar));
		gnome_appbar_push (GNOME_APPBAR(appbar), s);
		break;
	}
}



static void
newgame_set_sensitive (gboolean sensitive)
{
	prefsbox_players_set_sensitive (gameover);
	gtk_widget_set_sensitive (game_menu_uiinfo[0].widget, sensitive);
	gtk_widget_set_sensitive (toolbar[0].widget, sensitive);
}



static void
undo_set_sensitive (gboolean sensitive)
{
	gtk_widget_set_sensitive (game_menu_uiinfo[2].widget, sensitive);
	gtk_widget_set_sensitive (toolbar[1].widget, sensitive);
}



static void
hint_set_sensitive (gboolean sensitive)
{
	gtk_widget_set_sensitive (game_menu_uiinfo[3].widget, sensitive);
	gtk_widget_set_sensitive (toolbar[2].widget, sensitive);
}



static void
stop_anim (void)
{
	if (timeout == 0) return;
	anim = ANIM_NONE;
	gtk_timeout_remove (timeout);
	timeout = 0;
}



static void
game_init (void)
{
	g_random_set_seed ((guint)time (NULL));
	vboard = veleng_init ();

	anim            = ANIM_NONE;
	gameover        = TRUE;
	player          = PLAYER1;
	winner          = NOBODY;
	score[PLAYER1]  = 0;
	score[PLAYER2]  = 0;
	score[NOBODY]   = 0;

	who_starts = (get_random_int (2) == 1) ? PLAYER1 : PLAYER2;

	clear_board ();
}



void
game_reset (gboolean start)
{
	stop_anim ();
	undo_set_sensitive (FALSE);
	hint_set_sensitive (FALSE);

	who_starts = (who_starts == PLAYER1) ? PLAYER2 : PLAYER1;
	player = who_starts;

	gameover      = TRUE;
	winner        = NOBODY;
	column        = 3;
	column_moveto = 3;
	row           = 0;
	row_dropto    = 0;

	clear_board ();
	set_status (STATUS_CLEAR, NULL);
	gfx_draw_all (TRUE);

	if (start) {
		move_cursor (column);
		gameover = FALSE;
		prompt_player ();
		if (!is_player_human ()) {
			if (player == PLAYER1) {
				vstr[0] = vlevel[p.level[PLAYER1]];
			}
			else {
				vstr[0] = vlevel[p.level[PLAYER2]];
			}
			process_move (playgame (vstr, vboard) - 1);
		}
	}
}



static void
game_free (void)
{
	veleng_free (vboard);
	gfx_free ();
	g_free (fname_icon);
}



static void
play_sound (SoundID id)
{
	if (!p.do_sound) return;

	switch (id) {
	case SOUND_DROP:
		gnome_triggers_do (NULL, NULL, APPNAME, "drop", NULL);
		break;
	case SOUND_I_WIN:
		gnome_triggers_do (NULL, NULL, APPNAME, "iwin", NULL);
		break;
	case SOUND_YOU_WIN:
		gnome_triggers_do (NULL, NULL, APPNAME, "youwin", NULL);
		break;
	case SOUND_PLAYER_WIN:
		gnome_triggers_do (NULL, NULL, APPNAME, "playerwin", NULL);
		break;
	case SOUND_DRAWN_GAME:
		gnome_triggers_do (NULL, NULL, APPNAME, "draw", NULL);
		break;
	case SOUND_COLUMN_FULL:
		gnome_triggers_do (NULL, NULL, APPNAME, "cantmove", NULL);
		break;
	}
}



static gboolean
on_delete_event (GtkWidget *w, GdkEventAny *a, gpointer data)
{
	stop_anim ();
	gtk_main_quit ();
	exit (0);
	return FALSE;
}



void
prompt_player (void)
{
	gint players = get_n_human_players ();
	gint human = is_player_human ();
	const gchar *who;
	gchar *str;

	newgame_set_sensitive (human || gameover);
	hint_set_sensitive (human && !gameover);

	switch (players) {
	case 0:
		undo_set_sensitive (FALSE);
		break;
	case 1:
		undo_set_sensitive ((human && moves > 1) || (!human && gameover));
		break;
	case 2:
		undo_set_sensitive (moves > 0);
		break;
	}

	if (gameover && winner == NOBODY) {
		if (score[NOBODY] == 0) {
			set_status (STATUS_CLEAR, NULL);
		}
		else {
			set_status (STATUS_SET, _("It's a draw!"));
		}
		return;
	}

	switch (players) {
	case 1:
		if (human) {
			if (gameover) set_status (STATUS_SET, _("You win!"));
			else set_status (STATUS_SET, _("Your move..."));
		}
		else {
			if (gameover) set_status (STATUS_SET, _("I win!"));
			else set_status (STATUS_SET, _("Thinking..."));
		}
		break;
	case 2:
	case 0:
		if (player == PLAYER1) who = _(theme_get_player(PLAYER1));
		else who = _(theme_get_player(PLAYER2));

		if (gameover) str = g_strdup_printf (_("%s wins!"), who);
		else str = g_strdup_printf (_("%s..."), who);

		set_status (STATUS_SET, str);
		g_free (str);
		break;
	}
}



static void
on_game_new (GtkMenuItem *m, gpointer data)
{
	stop_anim ();
	game_reset (TRUE);
}



static void
on_game_exit (GtkMenuItem *m, gpointer data)
{
	stop_anim ();
	gtk_main_quit ();
	exit (0);
}



static void
on_game_undo (GtkMenuItem *m, gpointer data)
{
	gint r, c;

	if (timeout) return;
	c = vstr[moves] - '0' - 1;
	r = first_empty_row (c) + 1;
	vstr[moves] = '0';
	vstr[moves + 1] = '\0';
	moves--;

	if (gameover) {
		score[winner]--;
		scorebox_update ();
		gameover = FALSE;
		prompt_player ();
	}
	else {
		swap_player ();
	}
	move_cursor (c);

	gboard[r][c] = TILE_CLEAR;
	gfx_draw_tile (r, c, TRUE);

	if (get_n_human_players () == 1 && !is_player_human ()) {
		if (moves > 0) {
			c = vstr[moves] - '0' - 1;
			r = first_empty_row (c) + 1;
			vstr[moves] = '0';
			vstr[moves + 1] = '\0';
			moves--;
			swap_player ();
			move_cursor (c);
			gboard[r][c] = TILE_CLEAR;
			gfx_draw_tile (r, c, TRUE);
		}
	}
}



static void
on_game_hint (GtkMenuItem *m, gpointer data)
{
	gchar *s;
	gint c;

	if (timeout) return;
	if (gameover) return;

	hint_set_sensitive (FALSE);
	undo_set_sensitive (FALSE);

	set_status (STATUS_FLASH, _("Thinking..."));

	vstr[0] = vlevel[LEVEL_STRONG];
	c = playgame (vstr, vboard) - 1;

	column_moveto = c;
	if (p.do_animate) {
		while (timeout) gtk_main_iteration ();
		anim = ANIM_MOVE;
		timeout = gtk_timeout_add (SPEED_MOVE, on_animate, NULL);
		while (timeout) gtk_main_iteration ();
	}
	else {
		move_cursor (column_moveto);
	}
	blink_tile (0, c, gboard[0][c], 6);

	s = g_strdup_printf (_("Hint: Column %d"), c + 1);
	set_status (STATUS_FLASH, s);
	g_free (s);

	while (timeout) gtk_main_iteration ();
	hint_set_sensitive (TRUE);
	undo_set_sensitive (moves > 0);
}



void
on_dialog_close (GtkWidget *w, int response_id, gpointer data)
{
	gtk_widget_hide (w);
}



void
scorebox_update (void)
{
	gchar *s;

	if (scorebox == NULL) return;

	if (get_n_human_players () == 1) {
		if (p.level[PLAYER1] == LEVEL_HUMAN) {
			gtk_label_set_text (GTK_LABEL(label_name[PLAYER1]), _("You"));
			gtk_label_set_text (GTK_LABEL(label_name[PLAYER2]), _("Me"));
		}
		else {
			gtk_label_set_text (GTK_LABEL(label_name[PLAYER1]), _("Me"));
			gtk_label_set_text (GTK_LABEL(label_name[PLAYER2]), _("You"));
		}
	}
	else {
		gtk_label_set_text (GTK_LABEL(label_name[PLAYER1]),
		                    _(theme_get_player (PLAYER1)));
		gtk_label_set_text (GTK_LABEL(label_name[PLAYER2]),
		                    _(theme_get_player (PLAYER2)));
	}

	s = g_strdup_printf ("%d", score[PLAYER1]);
	gtk_label_set_text (GTK_LABEL(label_score[PLAYER1]), s);
	g_free (s);

	s = g_strdup_printf ("%d", score[PLAYER2]);
	gtk_label_set_text (GTK_LABEL(label_score[PLAYER2]), s);
	g_free (s);

	s = g_strdup_printf ("%d", score[NOBODY]);
	gtk_label_set_text (GTK_LABEL(label_score[NOBODY]), s);
	g_free (s);
}



void
scorebox_reset (void)
{
	score[PLAYER1] = 0;
	score[PLAYER2] = 0;
	score[NOBODY]  = 0;
	scorebox_update ();
}



static void
on_game_scores (GtkMenuItem *m, gpointer data)
{
	GtkWidget *table, *vbox;

	if (scorebox != NULL) {
		gtk_window_present (GTK_WINDOW(scorebox));
		return;
	}

	scorebox = gtk_dialog_new_with_buttons (_("Scores"),
	                                        GTK_WINDOW(app),
	                                        GTK_DIALOG_DESTROY_WITH_PARENT,
	                                        GTK_STOCK_CLOSE,
	                                        GTK_RESPONSE_CLOSE,
	                                        NULL);

	g_signal_connect (GTK_OBJECT(scorebox), "destroy",
	                  GTK_SIGNAL_FUNC(gtk_widget_destroyed), &scorebox);

	vbox = gtk_vbox_new (FALSE, 0);
	gtk_container_set_border_width (GTK_CONTAINER (vbox), 12);
	gtk_box_pack_start (GTK_BOX(GTK_DIALOG(scorebox)->vbox), vbox, TRUE, TRUE, 0);

	if (fname_icon != NULL) {
		GtkWidget *icon = gtk_image_new_from_file (fname_icon);
		if (icon != NULL) {
			gtk_box_pack_start (GTK_BOX(vbox), icon, FALSE, FALSE, 6);
		}
	}

	table = gtk_table_new (3, 2, FALSE);
	gtk_box_pack_start (GTK_BOX(vbox), table, TRUE, TRUE, 0);
	gtk_container_set_border_width (GTK_CONTAINER(table), 5);
	gtk_table_set_col_spacings (GTK_TABLE(table), 10);
	gtk_table_set_col_spacings (GTK_TABLE(table), 6);

	label_name[PLAYER1] = gtk_label_new (NULL);
	gtk_table_attach (GTK_TABLE(table), label_name[PLAYER1], 0, 1, 0, 1,
	                  (GtkAttachOptions)(GTK_FILL), (GtkAttachOptions)0, 0, 0);
	gtk_misc_set_alignment (GTK_MISC(label_name[PLAYER1]), 0, 0.5);

	label_score[PLAYER1] = gtk_label_new (NULL);
	gtk_table_attach (GTK_TABLE(table), label_score[PLAYER1], 1, 2, 0, 1,
	                  (GtkAttachOptions)(GTK_EXPAND | GTK_FILL), (GtkAttachOptions)0, 0, 0);
	gtk_misc_set_alignment (GTK_MISC(label_score[PLAYER1]), 0, 0.5);

	label_name[PLAYER2] = gtk_label_new (NULL);
	gtk_table_attach (GTK_TABLE(table), label_name[PLAYER2], 0, 1, 1, 2,
	                  (GtkAttachOptions)(GTK_FILL), (GtkAttachOptions)0, 0, 0);
	gtk_misc_set_alignment (GTK_MISC(label_name[PLAYER2]), 0, 0.5);

	label_score[PLAYER2] = gtk_label_new (NULL);
	gtk_table_attach (GTK_TABLE(table), label_score[PLAYER2], 1, 2, 1, 2,
	                  (GtkAttachOptions)(GTK_EXPAND | GTK_FILL), (GtkAttachOptions)0, 0, 0);
	gtk_misc_set_alignment (GTK_MISC(label_score[PLAYER2]), 0, 0.5);

	label_name[NOBODY] = gtk_label_new (_("Drawn"));
	gtk_table_attach (GTK_TABLE(table), label_name[NOBODY], 0, 1, 2, 3,
	                  (GtkAttachOptions)(GTK_FILL), (GtkAttachOptions)0, 0, 0);
	gtk_misc_set_alignment (GTK_MISC(label_name[NOBODY]), 0, 0.5);

	label_score[NOBODY] = gtk_label_new (NULL);
	gtk_table_attach (GTK_TABLE(table), label_score[NOBODY], 1, 2, 2, 3,
	                  (GtkAttachOptions)(GTK_EXPAND | GTK_FILL), (GtkAttachOptions)0, 0, 0);
	gtk_misc_set_alignment (GTK_MISC(label_score[NOBODY]), 0, 0.5);

	g_signal_connect (GTK_DIALOG(scorebox), "response",
	                  GTK_SIGNAL_FUNC(on_dialog_close), NULL);

	gtk_widget_show_all (scorebox);

	scorebox_update ();
}



static void
on_help_about (GtkMenuItem *m, gpointer data)
{
	const gchar *authors[] = {"Gnect:",
	                          "  Tim Musson <trmusson@ihug.co.nz>",
	                          "  David Neary <bolsh@gimp.org>",
	                          "\nVelena Engine V1.07:",
	                          "  AI engine written by Giuliano Bertoletti",
	                          "  Based on the knowledged approach of Victor Allis",
	                          "  Copyright (C) 1996-97 ",
	                          "  Giuliano Bertoletti and GBE 32241 Software PR.",
	                          NULL};
	const gchar *documents[] = {NULL};
	const gchar *translator  = _("translator-credits");
	static GtkWidget *aboutbox;
	GdkPixbuf *icon;

	if (aboutbox != NULL) {
		gtk_window_present (GTK_WINDOW(aboutbox));
		return;
	}

	icon = gdk_pixbuf_new_from_file (fname_icon, NULL);
	aboutbox = gnome_about_new ("Gnect",
	                            VERSION,
	                            "(c) 1999-2002, The Authors",
	                            _("\"Four in a row\" for GNOME, with a computer player driven by Giuliano Bertoletti's Velena Engine."),
	                            authors,
	                            documents,
	                            strcmp (translator, "translator-credits") != 0 ? translator : NULL,
	                            icon);
	gtk_window_set_transient_for (GTK_WINDOW(aboutbox), GTK_WINDOW(app));
	if (icon != NULL) g_object_unref (icon);
	g_signal_connect (aboutbox, "destroy", GTK_SIGNAL_FUNC(gtk_widget_destroyed), &aboutbox);
	gtk_widget_show (aboutbox);
}



void
toolbar_changed (void)
{
	BonoboDockItem *gdi;

	gdi = gnome_app_get_dock_item_by_name (GNOME_APP(app), GNOME_APP_TOOLBAR_NAME);
	if (p.do_toolbar) {
		gtk_widget_show (GTK_WIDGET(gdi));
	}
	else {
		gtk_widget_hide (GTK_WIDGET(gdi));
		gtk_widget_queue_resize (app);
	}
}



static void
on_settings_toggle_toolbar (GtkMenuItem *m, gpointer user_data)
{
	p.do_toolbar = GTK_CHECK_MENU_ITEM(m)->active;
	toolbar_changed ();
	gconf_client_set_bool (conf_client, KEY_DO_TOOLBAR, p.do_toolbar, NULL);
}



static void
on_settings_toggle_sound (GtkMenuItem *m, gpointer user_data)
{
	p.do_sound = GTK_CHECK_MENU_ITEM(m)->active;
	gconf_client_set_bool (conf_client, KEY_DO_SOUND, p.do_sound, NULL);
}




static void
on_settings_preferences (GtkMenuItem *m, gpointer user_data)
{
	prefsbox_open ();
}



static gboolean
is_hline_at (PlayerID p, gint r, gint c, gint *r1, gint *c1, gint *r2, gint *c2)
{
	*r1 = *r2 = r;
	*c1 = *c2 = c;
	while (*c1 > 0 && gboard[r][*c1 - 1] == p) *c1 = *c1 - 1;
	while (*c2 < 6 && gboard[r][*c2 + 1] == p) *c2 = *c2 + 1;
	if (*c2 - *c1 >= 3) return TRUE;
	return FALSE;
}



static gboolean
is_vline_at (PlayerID p, gint r, gint c, gint *r1, gint *c1, gint *r2, gint *c2)
{
	*r1 = *r2 = r;
	*c1 = *c2 = c;
	while (*r1 > 1 && gboard[*r1 - 1][c] == p) *r1 = *r1 - 1;
	while (*r2 < 6 && gboard[*r2 + 1][c] == p) *r2 = *r2 + 1;
	if (*r2 - *r1 >= 3) return TRUE;
	return FALSE;
}



static gboolean
is_dline1_at (PlayerID p, gint r, gint c, gint *r1, gint *c1, gint *r2, gint *c2)
{
	/* upper left to lower right */
	*r1 = *r2 = r;
	*c1 = *c2 = c;
	while (*c1 > 0 && *r1 > 1 && gboard[*r1 - 1][*c1 - 1] == p) {*r1 = *r1 - 1; *c1 = *c1 - 1;}
	while (*c2 < 6 && *r2 < 6 && gboard[*r2 + 1][*c2 + 1] == p) {*r2 = *r2 + 1; *c2 = *c2 + 1;}
	if (*r2 - *r1 >= 3) return TRUE;
	return FALSE;
}



static gboolean
is_dline2_at (PlayerID p, gint r, gint c, gint *r1, gint *c1, gint *r2, gint *c2)
{
	/* upper right to lower left */
	*r1 = *r2 = r;
	*c1 = *c2 = c;
	while (*c1 < 6 && *r1 > 1 && gboard[*r1 - 1][*c1 + 1] == p) {*r1 = *r1 - 1; *c1 = *c1 + 1;}
	while (*c2 > 0 && *r2 < 6 && gboard[*r2 + 1][*c2 - 1] == p) {*r2 = *r2 + 1; *c2 = *c2 - 1;}
	if (*r2 - *r1 >= 3) return TRUE;
	return FALSE;
}



static gboolean
is_line_at (PlayerID p, gint r, gint c)
{
	gint r1, r2, c1, c2;

	return is_hline_at (p, r, c, &r1, &c1, &r2, &c2) ||
	       is_vline_at (p, r, c, &r1, &c1, &r2, &c2) ||
	       is_dline1_at (p, r, c, &r1, &c1, &r2, &c2) ||
	       is_dline2_at (p, r, c, &r1, &c1, &r2, &c2);
}



static void
blink_winner (gint n)
{
	/* blink the winner's line(s) n times */

	if (winner == NOBODY) return;

	blink_t = winner;
	if (is_hline_at (winner, row, column, &blink_r1, &blink_c1, &blink_r2, &blink_c2)) {
		anim = ANIM_BLINK;
		blink_on = FALSE;
		blink_n = n;
		timeout = gtk_timeout_add (SPEED_BLINK, on_animate, NULL);
		while (timeout) gtk_main_iteration ();
	}

	if (is_vline_at (winner, row, column, &blink_r1, &blink_c1, &blink_r2, &blink_c2)) {
		anim = ANIM_BLINK;
		blink_on = FALSE;
		blink_n = n;
		timeout = gtk_timeout_add (SPEED_BLINK, on_animate, NULL);
		while (timeout) gtk_main_iteration ();
	}

	if (is_dline1_at (winner, row, column, &blink_r1, &blink_c1, &blink_r2, &blink_c2)) {
		anim = ANIM_BLINK;
		blink_on = FALSE;
		blink_n = n;
		timeout = gtk_timeout_add (SPEED_BLINK, on_animate, NULL);
		while (timeout) gtk_main_iteration ();
	}

	if (is_dline2_at (winner, row, column, &blink_r1, &blink_c1, &blink_r2, &blink_c2)) {
		anim = ANIM_BLINK;
		blink_on = FALSE;
		blink_n = n;
		timeout = gtk_timeout_add (SPEED_BLINK, on_animate, NULL);
		while (timeout) gtk_main_iteration ();
	}
}



static void
check_game_state (void)
{
	if (is_line_at (player, row, column)) {
		gameover = TRUE;
		winner = player;
		switch (get_n_human_players ()) {
		case 1:
			if (is_player_human ()) {
				play_sound (SOUND_YOU_WIN);
			}
			else {
				play_sound (SOUND_I_WIN);
			}
			break;
		case 0:
		case 2:
			play_sound (SOUND_PLAYER_WIN);
			break;
		}
		blink_winner (6);
	}
	else if (moves == 42) {
		gameover = TRUE;
		winner = NOBODY;
		play_sound (SOUND_DRAWN_GAME);
	}
}



static void
process_move (gint c)
{
	gint r;

	if (timeout) return;

	if (!p.do_animate) {
		move_cursor (c);
		column_moveto = c;
	}
	else {
		column_moveto = c;
		anim = ANIM_MOVE;
		timeout = gtk_timeout_add (SPEED_MOVE, on_animate, NULL);
		while (timeout) gtk_main_iteration ();
	}

	r = first_empty_row (c);
	if (r > 0) {

		if (!p.do_animate) {
			drop_marble (r, c);
		}
		else {
			row = 0;
			row_dropto = r;
			anim = ANIM_DROP;
			timeout = gtk_timeout_add (SPEED_DROP, on_animate, NULL);
			while (timeout) gtk_main_iteration ();
		}

		play_sound (SOUND_DROP);

		vstr[++moves] = '1' + c;
		vstr[moves + 1] = '0';

		check_game_state ();

		if (gameover) {
			score[winner]++;
			scorebox_update ();
			prompt_player ();
		}
		else {
			swap_player ();
			if (!is_player_human ()) {
				if (player == PLAYER1) {
					vstr[0] = vlevel[p.level[PLAYER1]];
				}
				else {
					vstr[0] = vlevel[p.level[PLAYER2]];
				}
				c = playgame (vstr, vboard) - 1;
				if (c < 0) gameover = TRUE;
				process_move (c);
			}
		}
	}
	else {
		play_sound (SOUND_COLUMN_FULL);
	}
}



static gboolean
on_key_press (GtkWidget* w, GdkEventKey* e, gpointer data)
{
	if (timeout ||
	    (e->keyval != p.keypress[MOVE_LEFT] &&
	     e->keyval != p.keypress[MOVE_RIGHT] &&
	     e->keyval != p.keypress[MOVE_DROP])) {
		return FALSE;
	}

	if (gameover) {
		blink_winner (2);
		set_status (STATUS_FLASH, _("Select \"New game\" from the \"Game\" menu to begin."));
		return TRUE;
	}

	if (e->keyval == p.keypress[MOVE_LEFT] && column) {
		column_moveto--;
		move_cursor (column_moveto);
	}
	else if (e->keyval == p.keypress[MOVE_RIGHT] && column < 6) {
		column_moveto++;
		move_cursor (column_moveto);
	}
	else if (e->keyval == p.keypress[MOVE_DROP]) {
		process_move (column);
	}
	return TRUE;
}



static void
on_drawarea_event (GtkWidget *w, const GdkEvent *e)
{
	GdkEventExpose *expose;
	gint x, y;

	switch (e->type) {
	case GDK_EXPOSE:
		expose = (GdkEventExpose*)e;
		gfx_expose (&expose->area);
		break;
	case GDK_BUTTON_PRESS:
		if (gameover && !timeout) {
			blink_winner (2);
			set_status (STATUS_FLASH, _("Select \"New game\" from the \"Game\" menu to begin."));
		}
		else if (is_player_human () && !timeout) {
			gtk_widget_get_pointer (w, &x, &y);
			process_move (gfx_get_column (x));
		}
		return;
	default:
		break;
	}
}



GnomeUIInfo game_menu_uiinfo[] =
{
	GNOMEUIINFO_MENU_NEW_GAME_ITEM(on_game_new, NULL),
	GNOMEUIINFO_SEPARATOR,
	GNOMEUIINFO_MENU_UNDO_ITEM(on_game_undo, NULL),
	GNOMEUIINFO_MENU_HINT_ITEM(on_game_hint, NULL),
	GNOMEUIINFO_SEPARATOR,
	GNOMEUIINFO_MENU_SCORES_ITEM(on_game_scores, NULL),
	GNOMEUIINFO_SEPARATOR,
	GNOMEUIINFO_MENU_EXIT_ITEM(on_game_exit, NULL),
	GNOMEUIINFO_END
};
GnomeUIInfo settings_menu_uiinfo[] =
{
	GNOMEUIINFO_TOGGLEITEM(N_("_Toolbar"),
	                       N_("Show or hide the tool bar"),
	                       on_settings_toggle_toolbar, NULL),
	GNOMEUIINFO_TOGGLEITEM(N_("Enable _sound"),
	                       N_("Enable or disable sound"),
	                       on_settings_toggle_sound, NULL),
	GNOMEUIINFO_SEPARATOR,
	GNOMEUIINFO_MENU_PREFERENCES_ITEM(on_settings_preferences, NULL),
	GNOMEUIINFO_END
};
GnomeUIInfo help_menu_uiinfo[] =
{
	GNOMEUIINFO_HELP(APPNAME),
	GNOMEUIINFO_MENU_ABOUT_ITEM(on_help_about, NULL),
	GNOMEUIINFO_END
};
GnomeUIInfo menubar_uiinfo[] =
{
	GNOMEUIINFO_MENU_GAME_TREE (game_menu_uiinfo),
	GNOMEUIINFO_MENU_SETTINGS_TREE (settings_menu_uiinfo),
	GNOMEUIINFO_MENU_HELP_TREE (help_menu_uiinfo),
	GNOMEUIINFO_END
};
GnomeUIInfo toolbar[] = {
	{GNOME_APP_UI_ITEM, N_("New"), N_("New game"), on_game_new,
	 NULL, N_("Start a new game"),
	 GNOME_APP_PIXMAP_STOCK, GTK_STOCK_NEW, 0, 0, NULL},
	GNOMEUIINFO_ITEM_STOCK(N_("Undo"), N_("Undo the last move"), on_game_undo, GTK_STOCK_UNDO),
	GNOMEUIINFO_ITEM_STOCK(N_("Hint"), N_("Get a hint for your next move"), on_game_hint, GTK_STOCK_HELP),
	GNOMEUIINFO_END
};



static gboolean
create_app (void)
{
	BonoboDockItem *gdi;
	GtkWidget *bonobodock;

	app = gnome_app_new (APPNAME, _("Four-in-a-row"));
	gtk_window_set_resizable (GTK_WINDOW (app), FALSE);
	gtk_window_set_wmclass (GTK_WINDOW (app), APPNAME, "main");

	g_signal_connect (G_OBJECT(app), "delete_event",
	                  G_CALLBACK(on_delete_event), NULL);

	fname_icon = gnome_program_locate_file (NULL, GNOME_FILE_DOMAIN_APP_PIXMAP,
	                                        ("gnect-icon.png"), TRUE, NULL);
	if (fname_icon != NULL) {
		gnome_window_icon_set_default_from_file (fname_icon); 
		gnome_window_icon_set_from_default (GTK_WINDOW(app));
	}

	bonobodock = GNOME_APP(app)->dock;
	gtk_widget_show (bonobodock);

	gnome_app_create_menus (GNOME_APP(app), menubar_uiinfo);
	gnome_app_create_toolbar (GNOME_APP(app), toolbar);

	drawarea = gtk_drawing_area_new ();
	gtk_widget_set_size_request (drawarea, 350, 350);
	gnome_app_set_contents (GNOME_APP (app), drawarea);

	gtk_widget_set_events (drawarea, GDK_EXPOSURE_MASK | GDK_BUTTON_PRESS_MASK);
	g_signal_connect (GTK_OBJECT(drawarea), "event", GTK_SIGNAL_FUNC(on_drawarea_event), NULL);
	g_signal_connect (GTK_OBJECT(app), "key_press_event", GTK_SIGNAL_FUNC(on_key_press), NULL);

	appbar = gnome_appbar_new (FALSE, TRUE, GNOME_PREFERENCES_NEVER);
	gnome_app_set_statusbar (GNOME_APP(app), appbar);

	gnome_app_install_menu_hints (GNOME_APP(app), menubar_uiinfo);

	if (p.do_toolbar) {
		gtk_check_menu_item_set_active (GTK_CHECK_MENU_ITEM(settings_menu_uiinfo[0].widget), TRUE);
	}

	hint_set_sensitive (FALSE);
	undo_set_sensitive (FALSE);

	gtk_widget_show_all (app);
	gc = gdk_gc_new (drawarea->window);

	if (!p.do_toolbar) {
		gdi = gnome_app_get_dock_item_by_name (GNOME_APP(app), GNOME_APP_TOOLBAR_NAME);
		gtk_widget_hide (GTK_WIDGET(gdi));
	}

	if (!gfx_load (p.theme_id)) {
		if (p.theme_id != 0) {
			if (!gfx_load (0)) {
				return FALSE;
			}
		}
		else {
			return FALSE;
		}
	}

	set_status (STATUS_FLASH, _("Welcome to Gnect!"));

	return TRUE;
}



int
main (int argc, char *argv[])
{
	bindtextdomain (GETTEXT_PACKAGE, GNOMELOCALEDIR);
	bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
	textdomain (GETTEXT_PACKAGE);

	gnome_program_init (APPNAME, VERSION, LIBGNOMEUI_MODULE,
	                    argc, argv, GNOME_PARAM_APP_DATADIR, DATADIR, NULL);

	prefs_init (argc, argv);
	game_init ();

	if (create_app ()) {
		gtk_main ();
	}

	game_free ();

	return 0;
}

