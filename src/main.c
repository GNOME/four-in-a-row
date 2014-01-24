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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include <config.h>
#include <stdlib.h>
#include <locale.h>

#include <glib/gi18n.h>
#include <gtk/gtk.h>
#include <canberra-gtk.h>

#include "connect4.h"
#include "main.h"
#include "theme.h"
#include "prefs.h"
#include "gfx.h"
#include "games-gridframe.h"
#include "games-stock.h"

#define SPEED_MOVE     25
#define SPEED_DROP     20
#define SPEED_BLINK    150

#define DEFAULT_WIDTH 350
#define DEFAULT_HEIGHT 390

extern Prefs p;

GSettings *settings;
GtkWidget *app;
GtkWidget *notebook;
GtkWidget *drawarea;
GtkWidget *statusbar;
GtkWidget *scorebox = NULL;
static GtkApplication *application;

GtkWidget *label_name[3];
GtkWidget *label_score[3];

GAction *new_game_action;
GAction *undo_action;
GAction *hint_action;

PlayerID player;
PlayerID winner;
PlayerID who_starts;
gboolean gameover;
gboolean player_active;
gint moves;
gint score[3];
gint column;
gint column_moveto;
gint row;
gint row_dropto;
gint timeout;

gint gboard[7][7];
gchar vstr[SIZE_VSTR];
gchar vlevel[] = "0abc";
struct board *vboard;

typedef enum {
  ANIM_NONE,
  ANIM_MOVE,
  ANIM_DROP,
  ANIM_BLINK,
  ANIM_HINT
} AnimID;

AnimID anim;

gint blink_r1, blink_c1;
gint blink_r2, blink_c2;
gint blink_t;
gint blink_n;
gboolean blink_on;


static void game_process_move (gint c);
static void process_move2 (gint c);
static void process_move3 (gint c);


static void
clear_board (void)
{
  gint r, c, i;

  for (r = 0; r < 7; r++) {
    for (c = 0; c < 7; c++) {
      gboard[r][c] = TILE_CLEAR;
    }
  }

  for (i = 0; i < SIZE_VSTR; i++)
    vstr[i] = '\0';

  vstr[0] = vlevel[LEVEL_WEAK];
  vstr[1] = '0';
  moves = 0;
}



static gint
first_empty_row (gint c)
{
  gint r = 1;

  while (r < 7 && gboard[r][c] == TILE_CLEAR)
    r++;
  return r - 1;
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

  if (player == PLAYER1)
    tile = TILE_PLAYER1;
  else
    tile = TILE_PLAYER2;

  gboard[r][c] = tile;
  gfx_draw_tile (r, c);

  column = column_moveto = c;
  row = row_dropto = r;
}



static void
drop (void)
{
  gint tile;

  if (player == PLAYER1)
    tile = TILE_PLAYER1;
  else
    tile = TILE_PLAYER2;

  gboard[row][column] = TILE_CLEAR;
  gfx_draw_tile (row, column);

  row++;
  gboard[row][column] = tile;
  gfx_draw_tile (row, column);
}



static void
move_cursor (gint c)
{
  gboard[0][column] = TILE_CLEAR;
  gfx_draw_tile (0, column);

  column = c;

  if (player == PLAYER1)
    gboard[0][c] = TILE_PLAYER1;
  else
    gboard[0][c] = TILE_PLAYER2;

  gfx_draw_tile (0, c);

  column = column_moveto = c;
  row = row_dropto = 0;
}



static void
move (gint c)
{
  gboard[0][column] = TILE_CLEAR;
  gfx_draw_tile (0, column);

  column = c;

  if (player == PLAYER1)
    gboard[0][c] = TILE_PLAYER1;
  else
    gboard[0][c] = TILE_PLAYER2;

  gfx_draw_tile (0, c);
}



static void
draw_line (gint r1, gint c1, gint r2, gint c2, gint tile)
{
  /* draw a line of 'tile' from r1,c1 to r2,c2 */

  gboolean done = FALSE;
  gint d_row = 0;
  gint d_col = 0;

  if (r1 < r2)
    d_row = 1;
  else if (r1 > r2)
    d_row = -1;

  if (c1 < c2)
    d_col = 1;
  else if (c1 > c2)
    d_col = -1;

  do {
    done = (r1 == r2 && c1 == c2);
    gboard[r1][c1] = tile;
    gfx_draw_tile (r1, c1);
    if (r1 != r2)
      r1 += d_row;
    if (c1 != c2)
      c1 += d_col;
  } while (!done);
}



static gboolean
on_animate (gint c)
{
  if (anim == ANIM_NONE)
    return FALSE;

  switch (anim) {
  case ANIM_NONE:
    break;
  case ANIM_HINT:
  case ANIM_MOVE:
    if (column < column_moveto) {
      move (column + 1);
    } else if (column > column_moveto) {
      move (column - 1);
    } else {
      timeout = 0;
      if (anim == ANIM_MOVE) {
	anim = ANIM_NONE;
	process_move2 (c);
      } else {
	anim = ANIM_NONE;
      }
      return FALSE;
    }
    break;
  case ANIM_DROP:
    if (row < row_dropto) {
      drop ();
    } else {
      anim = ANIM_NONE;
      timeout = 0;
      process_move3 (c);
      return FALSE;
    }
    break;
  case ANIM_BLINK:
    if (blink_on)
      draw_line (blink_r1, blink_c1, blink_r2, blink_c2, blink_t);
    else
      draw_line (blink_r1, blink_c1, blink_r2, blink_c2, TILE_CLEAR);
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
  if (timeout)
    return;
  blink_r1 = r;
  blink_c1 = c;
  blink_r2 = r;
  blink_c2 = c;
  blink_t = t;
  blink_n = n;
  blink_on = FALSE;
  anim = ANIM_BLINK;
  timeout = g_timeout_add (SPEED_BLINK, (GSourceFunc) on_animate, NULL);
}



static void
swap_player (void)
{
  player = (player == PLAYER1) ? PLAYER2 : PLAYER1;
  move_cursor (column);
  prompt_player ();
}



void
set_status_message (const gchar * message)
{
  guint context_id;
  context_id =
    gtk_statusbar_get_context_id (GTK_STATUSBAR (statusbar), "message");
  gtk_statusbar_pop (GTK_STATUSBAR (statusbar), context_id);
  if (message)
    gtk_statusbar_push (GTK_STATUSBAR (statusbar), context_id, message);
}

static void
stop_anim (void)
{
  if (timeout == 0)
    return;
  anim = ANIM_NONE;
  g_source_remove (timeout);
  timeout = 0;
}

static void
game_init (void)
{
  g_random_set_seed ((guint) time (NULL));
  vboard = veleng_init ();

  anim = ANIM_NONE;
  gameover = TRUE;
  player_active = FALSE;
  player = PLAYER1;
  winner = NOBODY;
  score[PLAYER1] = 0;
  score[PLAYER2] = 0;
  score[NOBODY] = 0;

  who_starts = PLAYER2;		/* This gets reversed immediately. */

  clear_board ();
}



void
game_reset (void)
{
  stop_anim ();

  g_simple_action_set_enabled (G_SIMPLE_ACTION (undo_action), FALSE);
  g_simple_action_set_enabled (G_SIMPLE_ACTION (hint_action), FALSE);

  who_starts = (who_starts == PLAYER1) ? PLAYER2 : PLAYER1;
  player = who_starts;

  gameover = TRUE;
  player_active = FALSE;
  winner = NOBODY;
  column = 3;
  column_moveto = 3;
  row = 0;
  row_dropto = 0;

  clear_board ();
  set_status_message (NULL);
  gfx_draw_all ();

  move_cursor (column);
  gameover = FALSE;
  prompt_player ();
  if (!is_player_human ()) {
    if (player == PLAYER1) {
      vstr[0] = vlevel[p.level[PLAYER1]];
    } else {
      vstr[0] = vlevel[p.level[PLAYER2]];
    }
    game_process_move (playgame (vstr, vboard) - 1);
  }
}



static void
game_free (void)
{
  veleng_free (vboard);
  gfx_free ();
}



static void
play_sound (SoundID id)
{
 const gchar *name = NULL;

 if (!p.do_sound)
    return;

  switch (id) {
  case SOUND_DROP:
    name = "slide";
    break;
  case SOUND_I_WIN:
    name = "reverse";
    break;
  case SOUND_YOU_WIN:
    name = "bonus";
    break;
  case SOUND_PLAYER_WIN:
    name = "bonus";
    break;
  case SOUND_DRAWN_GAME:
    name = "reverse";
    break;
  case SOUND_COLUMN_FULL:
    name = "bad";
    break;
  }

  if (name)
  {
    gchar *filename, *path;

    filename = g_strdup_printf ("%s.ogg", name);
    path = g_build_filename (SOUND_DIRECTORY, filename, NULL);
    g_free (filename);

    ca_gtk_play_for_widget (drawarea,
                            0,
                            CA_PROP_MEDIA_NAME, name,
                            CA_PROP_MEDIA_FILENAME, path, NULL);
    g_free (path);
  }
}


void
prompt_player (void)
{
  gint players = get_n_human_players ();
  gint human = is_player_human ();
  const gchar *who = NULL;
  gchar *str = NULL;

  g_simple_action_set_enabled (G_SIMPLE_ACTION (new_game_action), (human || gameover));
  g_simple_action_set_enabled (G_SIMPLE_ACTION (hint_action), (human || gameover));

  switch (players) {
  case 0:
    g_simple_action_set_enabled (G_SIMPLE_ACTION (undo_action), FALSE);
    break;
  case 1:
    g_simple_action_set_enabled (G_SIMPLE_ACTION (undo_action),
                              ((human && moves > 1) || (!human && gameover)));
    break;
  case 2:
    g_simple_action_set_enabled (G_SIMPLE_ACTION (undo_action), (moves > 0));
    break;
  }

  if (gameover && winner == NOBODY) {
    if (score[NOBODY] == 0) {
      set_status_message ("");
    } else {
      set_status_message (_("It's a draw!"));
    }
    return;
  }

  switch (players) {
  case 1:
    if (human) {
      if (gameover)
	set_status_message (_("You win!"));
      else
	set_status_message (_("It is your move."));
    } else {
      if (gameover)
	set_status_message (_("I win!"));
      else
	set_status_message (_("Thinking..."));
    }
    break;
  case 2:
  case 0:
    if (player == PLAYER1)
	who = _(theme_get_player (PLAYER1));
    else
	who = _(theme_get_player (PLAYER2));

    if (gameover) {
	str = g_strdup_printf (_("%s wins!"), who);
      }
    if (player_active) {
      set_status_message (_("It is your move."));
      return;

    } else {
      str = g_strdup_printf (_("Waiting for %s to move."), who);
    }

    set_status_message (str);
    g_free (str);
    break;
  }
}



static void
on_game_new (GSimpleAction *action, GVariant *parameter, gpointer data)
{
  stop_anim ();
  game_reset ();
}

static void
on_game_exit (GSimpleAction *action, GVariant *parameter, gpointer data)
{

  stop_anim ();
  g_application_quit (G_APPLICATION (application));
}

static void
on_game_undo (GSimpleAction *action, GVariant *parameter, gpointer data)
{
  gint r, c;

  if (timeout)
    return;
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
  } else {
    swap_player ();
  }
  move_cursor (c);

  gboard[r][c] = TILE_CLEAR;
  gfx_draw_tile (r, c);

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
      gfx_draw_tile (r, c);
    }
  }
}



static void
on_game_hint (GSimpleAction *action, GVariant *parameter, gpointer data)
{
  gchar *s;
  gint c;

  if (timeout)
    return;
  if (gameover)
    return;

  g_simple_action_set_enabled (G_SIMPLE_ACTION (hint_action), FALSE);
  g_simple_action_set_enabled (G_SIMPLE_ACTION (undo_action), FALSE);

  set_status_message (_("Thinking..."));

  vstr[0] = vlevel[LEVEL_STRONG];
  c = playgame (vstr, vboard) - 1;

  column_moveto = c;
  if (p.do_animate) {
    while (timeout)
      gtk_main_iteration ();
    anim = ANIM_HINT;
    timeout = g_timeout_add (SPEED_MOVE, (GSourceFunc) on_animate, NULL);
  } else {
    move_cursor (column_moveto);
  }

  blink_tile (0, c, gboard[0][c], 6);

  s = g_strdup_printf (_("Hint: Column %d"), c + 1);
  set_status_message (s);
  g_free (s);

  g_simple_action_set_enabled (G_SIMPLE_ACTION (hint_action), TRUE);
  g_simple_action_set_enabled (G_SIMPLE_ACTION (undo_action), (moves > 0));
}

void
on_dialog_close (GtkWidget * w, int response_id, gpointer data)
{
  gtk_widget_hide (w);
}



void
scorebox_update (void)
{
  gchar *s;

  if (scorebox == NULL)
    return;

  if (get_n_human_players () == 1) {
    if (p.level[PLAYER1] == LEVEL_HUMAN) {
      gtk_label_set_text (GTK_LABEL (label_name[PLAYER1]), _("You:"));
      gtk_label_set_text (GTK_LABEL (label_name[PLAYER2]), _("Me:"));
    } else {
      gtk_label_set_text (GTK_LABEL (label_name[PLAYER1]), _("Me:"));
      gtk_label_set_text (GTK_LABEL (label_name[PLAYER2]), _("You:"));
    }
  } else {
    gtk_label_set_text (GTK_LABEL (label_name[PLAYER1]),
			_(theme_get_player (PLAYER1)));
    gtk_label_set_text (GTK_LABEL (label_name[PLAYER2]),
			_(theme_get_player (PLAYER2)));
  }

  s = g_strdup_printf ("%d", score[PLAYER1]);
  gtk_label_set_text (GTK_LABEL (label_score[PLAYER1]), s);
  g_free (s);

  s = g_strdup_printf ("%d", score[PLAYER2]);
  gtk_label_set_text (GTK_LABEL (label_score[PLAYER2]), s);
  g_free (s);

  s = g_strdup_printf ("%d", score[NOBODY]);
  gtk_label_set_text (GTK_LABEL (label_score[NOBODY]), s);
  g_free (s);
}



void
scorebox_reset (void)
{
  score[PLAYER1] = 0;
  score[PLAYER2] = 0;
  score[NOBODY] = 0;
  scorebox_update ();
}



static void
on_game_scores (GSimpleAction *action, GVariant *parameter, gpointer data)
{
  GtkWidget *grid, *grid2, *icon;

  if (scorebox != NULL) {
    gtk_window_present (GTK_WINDOW (scorebox));
    return;
  }

  scorebox = gtk_dialog_new_with_buttons (_("Scores"),
					  GTK_WINDOW (app),
					  GTK_DIALOG_DESTROY_WITH_PARENT,
					  GTK_STOCK_CLOSE,
					  GTK_RESPONSE_CLOSE, NULL);

  gtk_window_set_resizable (GTK_WINDOW (scorebox), FALSE);
  gtk_container_set_border_width (GTK_CONTAINER (scorebox), 5);
  gtk_box_set_spacing (GTK_BOX (gtk_dialog_get_content_area (GTK_DIALOG (scorebox))), 2);

  g_signal_connect (scorebox, "destroy",
		    G_CALLBACK (gtk_widget_destroyed), &scorebox);

  grid = gtk_grid_new ();
  gtk_grid_set_row_spacing (GTK_GRID (grid), 6);
  gtk_orientable_set_orientation (GTK_ORIENTABLE (grid), GTK_ORIENTATION_VERTICAL);
  gtk_container_set_border_width (GTK_CONTAINER (grid), 5);

  gtk_box_pack_start (GTK_BOX (gtk_dialog_get_content_area (GTK_DIALOG (scorebox))),
		      grid, TRUE, TRUE, 0);

  icon = gtk_image_new_from_icon_name ("four-in-a-row", GTK_ICON_SIZE_DIALOG);
  gtk_container_add (GTK_CONTAINER (grid), icon);

  grid2 = gtk_grid_new ();
  gtk_container_add (GTK_CONTAINER (grid), grid2);
  gtk_grid_set_column_spacing (GTK_GRID (grid2), 6);

  label_name[PLAYER1] = gtk_label_new (NULL);
  gtk_grid_attach (GTK_GRID (grid2), label_name[PLAYER1], 0, 0, 1, 1);
  gtk_misc_set_alignment (GTK_MISC (label_name[PLAYER1]), 0, 0.5);

  label_score[PLAYER1] = gtk_label_new (NULL);
  gtk_grid_attach (GTK_GRID (grid2), label_score[PLAYER1], 1, 0, 1, 1);
  gtk_misc_set_alignment (GTK_MISC (label_score[PLAYER1]), 1, 0.5);

  label_name[PLAYER2] = gtk_label_new (NULL);
  gtk_grid_attach (GTK_GRID (grid2), label_name[PLAYER2], 0, 1, 1, 1);
  gtk_misc_set_alignment (GTK_MISC (label_name[PLAYER2]), 0, 0.5);

  label_score[PLAYER2] = gtk_label_new (NULL);
  gtk_grid_attach (GTK_GRID (grid2), label_score[PLAYER2], 1, 1, 1, 1);
  gtk_misc_set_alignment (GTK_MISC (label_score[PLAYER2]), 1, 0.5);

  label_name[NOBODY] = gtk_label_new (_("Drawn:"));
  gtk_grid_attach (GTK_GRID (grid2), label_name[NOBODY], 0, 2, 1, 1);
  gtk_misc_set_alignment (GTK_MISC (label_name[NOBODY]), 0, 0.5);

  label_score[NOBODY] = gtk_label_new (NULL);
  gtk_grid_attach (GTK_GRID (grid2), label_score[NOBODY], 1, 2, 1, 1);
  gtk_misc_set_alignment (GTK_MISC (label_score[NOBODY]), 1, 0.5);

  g_signal_connect (GTK_DIALOG (scorebox), "response",
		    G_CALLBACK (on_dialog_close), NULL);

  gtk_widget_show_all (scorebox);

  scorebox_update ();
}

static void
on_help_about (GSimpleAction *action, GVariant *parameter, gpointer data)
{
  const gchar *authors[] = { "Four-in-a-row:",
    "  Tim Musson <trmusson@ihug.co.nz>",
    "  David Neary <bolsh@gimp.org>",
    "",
    "Velena Engine V1.07:",
    "  AI engine written by Giuliano Bertoletti",
    "  Based on the knowledged approach of Victor Allis",
    "  Copyright (C) 1996-97 ",
    "  Giuliano Bertoletti and GBE 32241 Software PR.",
    NULL
  };

  const gchar *artists[] = { "Alan Horkan",
    "Tim Musson",
    "Anatol Drlicek",
    "Some themes based on the Faenza icon theme by Matthieu James",
    NULL
  };

  const gchar *documenters[] = { "Timothy Musson",
    NULL
  };

  gtk_show_about_dialog (GTK_WINDOW (app),
			 "name", _(APPNAME_LONG),
			 "version", VERSION,
			 "copyright",
			 "Copyright © 1999–2008, Tim Musson and David Neary",
			 "license-type", GTK_LICENSE_GPL_2_0, "comments",
		         _("Connect four in a row to win.\n\nFour-in-a-row is a part of GNOME Games."),
			 "authors", authors, "documenters", documenters,
			 "artists", artists, "translator-credits",
			 _("translator-credits"),
			 "logo-icon-name", "four-in-a-row",
			 "website", "https://wiki.gnome.org/Apps/Four-in-a-row",
			 NULL);
}


static void
on_help_contents (GSimpleAction *action, GVariant *parameter, gpointer data)
{
  GError *error = NULL;

  gtk_show_uri (gtk_widget_get_screen (GTK_WIDGET (app)), "help:four-in-a-row", gtk_get_current_event_time (), &error);
  if (error)
    g_warning ("Failed to show help: %s", error->message);
  g_clear_error (&error);
}


static void
on_settings_preferences (GSimpleAction *action, GVariant *parameter, gpointer user_data)
{
  prefsbox_open ();
}



static gboolean
is_hline_at (PlayerID p, gint r, gint c, gint * r1, gint * c1, gint * r2,
	     gint * c2)
{
  *r1 = *r2 = r;
  *c1 = *c2 = c;
  while (*c1 > 0 && gboard[r][*c1 - 1] == p)
    *c1 = *c1 - 1;
  while (*c2 < 6 && gboard[r][*c2 + 1] == p)
    *c2 = *c2 + 1;
  if (*c2 - *c1 >= 3)
    return TRUE;
  return FALSE;
}



static gboolean
is_vline_at (PlayerID p, gint r, gint c, gint * r1, gint * c1, gint * r2,
	     gint * c2)
{
  *r1 = *r2 = r;
  *c1 = *c2 = c;
  while (*r1 > 1 && gboard[*r1 - 1][c] == p)
    *r1 = *r1 - 1;
  while (*r2 < 6 && gboard[*r2 + 1][c] == p)
    *r2 = *r2 + 1;
  if (*r2 - *r1 >= 3)
    return TRUE;
  return FALSE;
}



static gboolean
is_dline1_at (PlayerID p, gint r, gint c, gint * r1, gint * c1, gint * r2,
	      gint * c2)
{
  /* upper left to lower right */
  *r1 = *r2 = r;
  *c1 = *c2 = c;
  while (*c1 > 0 && *r1 > 1 && gboard[*r1 - 1][*c1 - 1] == p) {
    *r1 = *r1 - 1;
    *c1 = *c1 - 1;
  }
  while (*c2 < 6 && *r2 < 6 && gboard[*r2 + 1][*c2 + 1] == p) {
    *r2 = *r2 + 1;
    *c2 = *c2 + 1;
  }
  if (*r2 - *r1 >= 3)
    return TRUE;
  return FALSE;
}



static gboolean
is_dline2_at (PlayerID p, gint r, gint c, gint * r1, gint * c1, gint * r2,
	      gint * c2)
{
  /* upper right to lower left */
  *r1 = *r2 = r;
  *c1 = *c2 = c;
  while (*c1 < 6 && *r1 > 1 && gboard[*r1 - 1][*c1 + 1] == p) {
    *r1 = *r1 - 1;
    *c1 = *c1 + 1;
  }
  while (*c2 > 0 && *r2 < 6 && gboard[*r2 + 1][*c2 - 1] == p) {
    *r2 = *r2 + 1;
    *c2 = *c2 - 1;
  }
  if (*r2 - *r1 >= 3)
    return TRUE;
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

  if (winner == NOBODY)
    return;

  blink_t = winner;
  if (is_hline_at
      (winner, row, column, &blink_r1, &blink_c1, &blink_r2, &blink_c2)) {
    anim = ANIM_BLINK;
    blink_on = FALSE;
    blink_n = n;
    timeout = g_timeout_add (SPEED_BLINK, (GSourceFunc) on_animate, NULL);
    while (timeout)
      gtk_main_iteration ();
  }

  if (is_vline_at
      (winner, row, column, &blink_r1, &blink_c1, &blink_r2, &blink_c2)) {
    anim = ANIM_BLINK;
    blink_on = FALSE;
    blink_n = n;
    timeout = g_timeout_add (SPEED_BLINK, (GSourceFunc) on_animate, NULL);
    while (timeout)
      gtk_main_iteration ();
  }

  if (is_dline1_at
      (winner, row, column, &blink_r1, &blink_c1, &blink_r2, &blink_c2)) {
    anim = ANIM_BLINK;
    blink_on = FALSE;
    blink_n = n;
    timeout = g_timeout_add (SPEED_BLINK, (GSourceFunc) on_animate, NULL);
    while (timeout)
      gtk_main_iteration ();
  }

  if (is_dline2_at
      (winner, row, column, &blink_r1, &blink_c1, &blink_r2, &blink_c2)) {
    anim = ANIM_BLINK;
    blink_on = FALSE;
    blink_n = n;
    timeout = g_timeout_add (SPEED_BLINK, (GSourceFunc) on_animate, NULL);
    while (timeout)
      gtk_main_iteration ();
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
      } else {
	play_sound (SOUND_I_WIN);
      }
      break;
    case 0:
    case 2:
      play_sound (SOUND_PLAYER_WIN);
      break;
    }
    blink_winner (6);
  } else if (moves == 42) {
    gameover = TRUE;
    winner = NOBODY;
    play_sound (SOUND_DRAWN_GAME);
  }
}

static gint
next_move (gint c)
{
  process_move (c);
  return FALSE;
}

static void
game_process_move (gint c)
{
  process_move (c);
}

void
process_move (gint c)
{
  if (timeout) {
    g_timeout_add (SPEED_DROP,
	           (GSourceFunc) next_move, GINT_TO_POINTER (c));
    return;

  }

  if (!p.do_animate) {
    move_cursor (c);
    column_moveto = c;
    process_move2 (c);
  } else {
    column_moveto = c;
    anim = ANIM_MOVE;
    timeout = g_timeout_add (SPEED_MOVE,
                             (GSourceFunc) on_animate, GINT_TO_POINTER (c));
  }
}

static void
process_move2 (gint c)
{
  gint r;

  r = first_empty_row (c);
  if (r > 0) {

    if (!p.do_animate) {
      drop_marble (r, c);
      process_move3 (c);
    } else {
      row = 0;
      row_dropto = r;
      anim = ANIM_DROP;
      timeout = g_timeout_add (SPEED_DROP,
                               (GSourceFunc) on_animate,
                               GINT_TO_POINTER (c));
    }
  } else {
    play_sound (SOUND_COLUMN_FULL);
  }
}

static void
process_move3 (gint c)
{
  play_sound (SOUND_DROP);

  vstr[++moves] = '1' + c;
  vstr[moves + 1] = '0';

  check_game_state ();

  if (gameover) {
    score[winner]++;
    scorebox_update ();
    prompt_player ();
  } else {
    swap_player ();
    if (!is_player_human ()) {
      if (player == PLAYER1) {
	vstr[0] = vlevel[p.level[PLAYER1]];
      } else {
	vstr[0] = vlevel[p.level[PLAYER2]];
      }
      c = playgame (vstr, vboard) - 1;
      if (c < 0)
	gameover = TRUE;
      g_timeout_add (SPEED_DROP,
                     (GSourceFunc) next_move, GINT_TO_POINTER (c));
    }
  }
}

static gint
on_drawarea_resize (GtkWidget * w, GdkEventConfigure * e, gpointer data)
{
  gfx_resize (w);

  return TRUE;
}

static gboolean
on_drawarea_draw (GtkWidget * w, cairo_t *cr, gpointer data)
{
  gfx_expose (cr);

  return FALSE;
}

static gboolean
on_key_press (GtkWidget * w, GdkEventKey * e, gpointer data)
{
  if ((player_active) || timeout ||
      (e->keyval != p.keypress[MOVE_LEFT] &&
       e->keyval != p.keypress[MOVE_RIGHT] &&
       e->keyval != p.keypress[MOVE_DROP])) {
    return FALSE;
  }

  if (gameover) {
    blink_winner (2);
    return TRUE;
  }

  if (e->keyval == p.keypress[MOVE_LEFT] && column) {
    column_moveto--;
    move_cursor (column_moveto);
  } else if (e->keyval == p.keypress[MOVE_RIGHT] && column < 6) {
    column_moveto++;
    move_cursor (column_moveto);
  } else if (e->keyval == p.keypress[MOVE_DROP]) {
    game_process_move (column);
  }
  return TRUE;
}

static gboolean
on_button_press (GtkWidget * w, GdkEventButton * e, gpointer data)
{
  gint x, y;
  if (player_active) {
    return FALSE;
  }

  if (gameover && !timeout) {
    blink_winner (2);
  } else if (is_player_human () && !timeout) {
    gdk_window_get_device_position (gtk_widget_get_window (w), e->device, &x, &y, NULL);
    game_process_move (gfx_get_column (x));
  }

  return TRUE;
}

static const GActionEntry app_entries[] = {
  {"new-game", on_game_new, NULL, NULL, NULL},
  {"undo-move", on_game_undo, NULL, NULL, NULL},
  {"hint", on_game_hint, NULL, NULL, NULL},
  {"scores", on_game_scores, NULL, NULL, NULL},
  {"quit", on_game_exit, NULL, NULL, NULL},
  {"preferences", on_settings_preferences, NULL, NULL, NULL},
  {"help", on_help_contents, NULL, NULL, NULL},
  {"about", on_help_about, NULL, NULL, NULL}
};

static gboolean
create_app (void)
{
  GtkWidget *gridframe;
  GtkWidget *grid;
  GtkWidget *vpaned;
  GMenu *app_menu, *section;

  app = gtk_application_window_new (application);
  gtk_window_set_application (GTK_WINDOW (app), application);
  gtk_window_set_title (GTK_WINDOW (app), _(APPNAME_LONG));

  gtk_window_set_default_size (GTK_WINDOW (app), DEFAULT_WIDTH, DEFAULT_HEIGHT);
  //games_conf_add_window (GTK_WINDOW (app), NULL);

  notebook = gtk_notebook_new ();
  gtk_notebook_set_show_tabs (GTK_NOTEBOOK (notebook), FALSE);
  gtk_notebook_set_show_border (GTK_NOTEBOOK (notebook), FALSE);

  gtk_window_set_default_icon_name ("four-in-a-row");

  statusbar = gtk_statusbar_new ();

  g_action_map_add_action_entries (G_ACTION_MAP (application), app_entries, G_N_ELEMENTS (app_entries), application);
  gtk_application_add_accelerator (application, "<Primary>n", "app.new-game", NULL);
  gtk_application_add_accelerator (application, "<Primary>h", "app.hint", NULL);
  gtk_application_add_accelerator (application, "<Primary>z", "app.undo-move", NULL);
  gtk_application_add_accelerator (application, "<Primary>q", "app.quit", NULL);
  gtk_application_add_accelerator (application, "F1", "app.contents", NULL);

  app_menu = g_menu_new ();
  section = g_menu_new ();
  g_menu_append_section (app_menu, NULL, G_MENU_MODEL (section));
  g_menu_append (section, _("_New Game"), "app.new-game");
  g_menu_append (section, _("_Undo Move"), "app.undo-move");
  g_menu_append (section, _("_Hint"), "app.hint");
  g_menu_append (section, _("_Scores"), "app.scores");
  section = g_menu_new ();
  g_menu_append_section (app_menu, NULL, G_MENU_MODEL (section));
  g_menu_append (section, _("_Preferences"), "app.preferences");
  section = g_menu_new ();
  g_menu_append_section (app_menu, NULL, G_MENU_MODEL (section));
  g_menu_append (section, _("_Help"), "app.help");
  g_menu_append (section, _("_About"), "app.about");
  g_menu_append (section, _("_Quit"), "app.quit");

  new_game_action = g_action_map_lookup_action (G_ACTION_MAP (application), "new-game");
  undo_action = g_action_map_lookup_action (G_ACTION_MAP (application), "undo-move");
  hint_action = g_action_map_lookup_action (G_ACTION_MAP (application), "hint");

  gtk_application_set_app_menu (GTK_APPLICATION (application), G_MENU_MODEL (app_menu));


  vpaned = gtk_paned_new (GTK_ORIENTATION_VERTICAL);
  gtk_widget_set_hexpand (vpaned, TRUE);
  gtk_widget_set_vexpand (vpaned, TRUE);

  grid = gtk_grid_new ();
  gtk_orientable_set_orientation (GTK_ORIENTABLE (grid), GTK_ORIENTATION_VERTICAL);

  gridframe = games_grid_frame_new (7, 7);

  gtk_paned_pack1 (GTK_PANED (vpaned), gridframe, TRUE, FALSE);

  gtk_container_add (GTK_CONTAINER (grid), vpaned);
  gtk_container_add (GTK_CONTAINER (grid), statusbar);

  gtk_container_add (GTK_CONTAINER (app), notebook);
  gtk_notebook_append_page (GTK_NOTEBOOK (notebook), grid, NULL);
  gtk_notebook_set_current_page (GTK_NOTEBOOK (notebook), MAIN_PAGE);

  drawarea = gtk_drawing_area_new ();

  /* set a min size to avoid pathological behavior of gtk when scaling down */
  gtk_widget_set_size_request (drawarea, 200, 200);

  gtk_container_add (GTK_CONTAINER (gridframe), drawarea);

  gtk_widget_set_events (drawarea, GDK_EXPOSURE_MASK | GDK_BUTTON_PRESS_MASK);
  g_signal_connect (G_OBJECT (drawarea), "configure_event",
		    G_CALLBACK (on_drawarea_resize), NULL);
  g_signal_connect (G_OBJECT (drawarea), "draw",
		    G_CALLBACK (on_drawarea_draw), NULL);
  g_signal_connect (G_OBJECT (drawarea), "button_press_event",
		    G_CALLBACK (on_button_press), NULL);
  g_signal_connect (G_OBJECT (app), "key_press_event",
		    G_CALLBACK (on_key_press), NULL);

  /* We do our own double-buffering. */
  gtk_widget_set_double_buffered (GTK_WIDGET (drawarea), FALSE);

  g_simple_action_set_enabled (G_SIMPLE_ACTION (hint_action), FALSE);
  g_simple_action_set_enabled (G_SIMPLE_ACTION (undo_action), FALSE);

  gtk_widget_show_all (app);

  gfx_refresh_pixmaps ();
  gfx_draw_all ();

  scorebox_update ();		/* update visible player descriptions */
  prompt_player ();

  game_reset ();
  return TRUE;
}



int
main (int argc, char *argv[])
{
  GOptionContext *context;
  gboolean retval;
  GError *error = NULL;
  gint app_retval;

  setlocale (LC_ALL, "");
  bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
  bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
  textdomain (GETTEXT_PACKAGE);

  application = gtk_application_new ("org.gnome.four-in-a-row", 0);
  g_signal_connect (application, "activate", G_CALLBACK (create_app), NULL);

  /*
   * Required because the binary doesn't match the desktop file.
   * Has to be before the call to g_option_context_parse.
   */
  g_set_prgname (APPNAME);

  context = g_option_context_new (NULL);
  g_option_context_add_group (context, gtk_get_option_group (TRUE));
  retval = g_option_context_parse (context, &argc, &argv, &error);
  g_option_context_free (context);
  if (!retval) {
    g_print ("%s", error->message);
    g_error_free (error);
    exit (1);
  }
  
  settings = g_settings_new ("org.gnome.four-in-a-row");

  g_set_application_name (_(APPNAME_LONG));

  prefs_init ();
  game_init ();

  /* init gfx */
  if (!gfx_load_pixmaps ()) {
    exit (1);
  }

  app_retval = g_application_run (G_APPLICATION (application), argc, argv);

  game_free ();

  return app_retval;
}
