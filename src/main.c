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

#include "ai.h"
#include "main.h"
#include "theme.h"
#include "prefs.h"
#include "gfx.h"

#define SPEED_MOVE     25
#define SPEED_DROP     20
#define SPEED_BLINK    150

#define DEFAULT_WIDTH 495
#define DEFAULT_HEIGHT 435

extern Prefs p;

GSettings *settings;
extern GtkWidget *window;
GtkWidget *drawarea;
GtkWidget *headerbar;
extern GtkWidget *scorebox;
extern GtkApplication *application;

extern GtkWidget *label_name[3];
extern GtkWidget *label_score[3];

GAction *new_game_action;
GAction *undo_action;
GAction *hint_action;

extern PlayerID player;
extern PlayerID winner;
extern PlayerID who_starts;
extern gboolean gameover;
extern gboolean player_active;
extern gint moves;
extern gint score[3];
extern gint column;
extern gint column_moveto;
extern gint row;
extern gint row_dropto;
extern gint timeout;

extern gint gboard[7][7];
extern gchar vstr[SIZE_VSTR];
gchar vlevel[] = "0abc";
struct board *vboard;

extern AnimID anim;

extern gint blink_r1, blink_c1;
extern gint blink_r2, blink_c2;
extern gint blink_t;
extern gint blink_n;
extern gboolean blink_on;


void game_process_move (gint c);
void process_move2 (gint c);
void process_move3 (gint c);
void game_free (void);
gint next_move (gint c);
void move (gint c);
void drop ();
void stop_anim ();
void clear_board ();
void move_cursor (gint c);
gboolean is_player_human ();
//void playgame ();
int get_n_human_players();
void on_game_undo (GSimpleAction *action, GVariant *parameter);
void on_game_scores (GSimpleAction *action, GVariant *parameter);
void on_game_new (GSimpleAction *action, GVariant *parameter, gpointer data);
void on_game_exit (GSimpleAction *action, GVariant *parameter, gpointer data);

gboolean
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
      draw_line (blink_r1, blink_c1, blink_r2, blink_c2, blink_on ? blink_t
                                                                  : TILE_CLEAR);
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
    vstr[0] = player == PLAYER1 ? vlevel[p.level[PLAYER1]]
                                : vlevel[p.level[PLAYER2]];
    game_process_move (playgame (vstr) - 1);
  }
}

void
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

    ca_context_play (ca_gtk_context_get(),
                     id,
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

  g_simple_action_set_enabled (G_SIMPLE_ACTION (hint_action), (human && !gameover));

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
    if (score[NOBODY] == 0)
      set_status_message (NULL);
    else
      set_status_message (_("It’s a draw!"));
    return;
  }

  switch (players) {
  case 1:
    if (human) {
      if (gameover)
        set_status_message (_("You win!"));
      else
        set_status_message (_("Your Turn"));
    } else {
      if (gameover)
        set_status_message (_("I win!"));
      else
        set_status_message (_("I’m Thinking…"));
    }
    break;
  case 2:
  case 0:

    if (gameover) {
      who = player == PLAYER1 ? theme_get_player_win (PLAYER1)
                              : theme_get_player_win (PLAYER2);
      str = g_strdup_printf ("%s", _(who));
    } else if (player_active) {
      set_status_message (_("Your Turn"));
      return;
    } else {
      who = player == PLAYER1 ? theme_get_player_turn (PLAYER1)
                              : theme_get_player_turn (PLAYER2);
      str = g_strdup_printf ("%s", _(who));
    }

    set_status_message (str);
    g_free (str);
    break;
  }
}







void
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

  set_status_message (_("I’m Thinking…"));

  vstr[0] = vlevel[LEVEL_STRONG];
  c = playgame (vstr) - 1;

  column_moveto = c;
  while (timeout)
    gtk_main_iteration ();
  anim = ANIM_HINT;
  timeout = g_timeout_add (SPEED_MOVE, (GSourceFunc) on_animate, NULL);

  blink_tile (0, c, gboard[0][c], 6);

  s = g_strdup_printf (_("Hint: Column %d"), c + 1);
  set_status_message (s);
  g_free (s);

  if (moves <= 0 || (moves == 1 && is_player_human ()))
    g_simple_action_set_enabled (G_SIMPLE_ACTION (undo_action), FALSE);
  else
    g_simple_action_set_enabled (G_SIMPLE_ACTION (undo_action), TRUE);
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
on_help_about (GSimpleAction *action, GVariant *parameter, gpointer data)
{
  const gchar *authors[] = {"Tim Musson <trmusson@ihug.co.nz>",
    "David Neary <bolsh@gimp.org>",
    "Nikhar Agrawal <nikharagrawal2006@gmail.com>",
    NULL
  };

  const gchar *artists[] = { "Alan Horkan",
    "Anatol Drlicek",
    "Based on the Faenza icon theme by Matthieu James",
    NULL
  };

  const gchar *documenters[] = { "Timothy Musson",
    NULL
  };

  gtk_show_about_dialog (GTK_WINDOW (window),
                         "name", _(APPNAME_LONG),
                         "version", VERSION,
                         "copyright",
                         "Copyright © 1999–2008 Tim Musson and David Neary\nCopyright © 2014 Michael Catanzaro",
                         "license-type", GTK_LICENSE_GPL_2_0, "comments",
                         _("Connect four in a row to win."),
                         "authors", authors, "documenters", documenters,
                         "artists", artists, "translator-credits",
                         _("translator-credits"),
                         "logo-icon-name", "four-in-a-row",
                         "website", "https://wiki.gnome.org/Apps/Four-in-a-row",
                         NULL);
}


void
on_help_contents (GSimpleAction *action, GVariant *parameter, gpointer data)
{
  GError *error = NULL;

  gtk_show_uri (gtk_widget_get_screen (window), "help:four-in-a-row", gtk_get_current_event_time (), &error);
  if (error)
    g_warning ("Failed to show help: %s", error->message);
  g_clear_error (&error);
}


void
on_settings_preferences (GSimpleAction *action, GVariant *parameter, gpointer user_data)
{
  prefsbox_open ();
}

void
blink_winner (gint n)
{
  /* blink the winner's line(s) n times */

  if (winner == NOBODY)
    return;

  blink_t = winner;
  if (is_hline_at (winner, row, column, &blink_r1, &blink_c1, &blink_r2, &blink_c2)) {
    anim = ANIM_BLINK;
    blink_on = FALSE;
    blink_n = n;
    timeout = g_timeout_add (SPEED_BLINK, (GSourceFunc) on_animate, NULL);
    while (timeout)
      gtk_main_iteration ();
  }

  if (is_vline_at (winner, row, column, &blink_r1, &blink_c1, &blink_r2, &blink_c2)) {
    anim = ANIM_BLINK;
    blink_on = FALSE;
    blink_n = n;
    timeout = g_timeout_add (SPEED_BLINK, (GSourceFunc) on_animate, NULL);
    while (timeout)
      gtk_main_iteration ();
  }

  if (is_dline1_at (winner, row, column, &blink_r1, &blink_c1, &blink_r2, &blink_c2)) {
    anim = ANIM_BLINK;
    blink_on = FALSE;
    blink_n = n;
    timeout = g_timeout_add (SPEED_BLINK, (GSourceFunc) on_animate, NULL);
    while (timeout)
      gtk_main_iteration ();
  }

  if (is_dline2_at (winner, row, column, &blink_r1, &blink_c1, &blink_r2, &blink_c2)) {
    anim = ANIM_BLINK;
    blink_on = FALSE;
    blink_n = n;
    timeout = g_timeout_add (SPEED_BLINK, (GSourceFunc) on_animate, NULL);
    while (timeout)
      gtk_main_iteration ();
  }
}

void
check_game_state (void)
{
  if (is_line_at (player, row, column)) {
    gameover = TRUE;
    winner = player;
    switch (get_n_human_players ()) {
    case 1:
      play_sound (is_player_human () ? SOUND_YOU_WIN : SOUND_I_WIN);
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







void
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
      vstr[0] = player == PLAYER1 ? vlevel[p.level[PLAYER1]]
                                  : vlevel[p.level[PLAYER2]];
      c = playgame (vstr) - 1;
      if (c < 0)
        gameover = TRUE;
      g_timeout_add (SPEED_DROP, (GSourceFunc) next_move, GINT_TO_POINTER (c));
    }
  }
}

int on_drawarea_resize (GtkWidget * w, GdkEventConfigure * e, gpointer data);

gboolean on_drawarea_draw (GtkWidget * w, cairo_t *cr, gpointer data);

gboolean
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

gboolean
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

void
create_app (GApplication *app, gpointer user_data)
{
  GtkWidget *frame;
  GMenu *app_menu, *section;

  GtkBuilder *builder = NULL;
  GtkCssProvider *css_provider = NULL;
  GError *error = NULL;

  gtk_window_set_default_icon_name ("four-in-a-row");

  css_provider = gtk_css_provider_get_default ();
  gtk_css_provider_load_from_data (css_provider, "GtkButtonBox{-GtkButtonBox-child-internal-pad-x:0;}\0", -1, &error);
  if (G_UNLIKELY (error != NULL)) {
      fprintf (stderr, "Could not load UI: %s\n", error->message);
      g_clear_error (&error);
      return;
  }
  gtk_style_context_add_provider_for_screen (gdk_screen_get_default (), css_provider, GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);

  builder = gtk_builder_new_from_file (DATA_DIRECTORY "/four-in-a-row.ui");

  window = gtk_builder_get_object (builder, "fiar-window");
  gtk_window_set_application (GTK_WINDOW (window), application);
  gtk_window_set_default_size (GTK_WINDOW (window), DEFAULT_WIDTH, DEFAULT_HEIGHT);     // TODO save size & state

  headerbar = gtk_builder_get_object (builder, "headerbar");

  g_action_map_add_action_entries (G_ACTION_MAP (application), app_entries, G_N_ELEMENTS (app_entries), application);
  gtk_application_add_accelerator (application, "<Primary>n", "app.new-game", NULL);
  gtk_application_add_accelerator (application, "<Primary>h", "app.hint", NULL);
  gtk_application_add_accelerator (application, "<Primary>z", "app.undo-move", NULL);
  gtk_application_add_accelerator (application, "<Primary>q", "app.quit", NULL);
  gtk_application_add_accelerator (application, "F1", "app.contents", NULL);

  app_menu = g_menu_new ();
  section = g_menu_new ();
  g_menu_append_section (app_menu, NULL, G_MENU_MODEL (section));
  g_menu_append (section, _("_Scores"), "app.scores");
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

  frame = gtk_builder_get_object (builder, "frame");

  drawarea = gtk_drawing_area_new ();
  /* set a min size to avoid pathological behavior of gtk when scaling down */
  gtk_widget_set_size_request (drawarea, 350, 350);
  gtk_widget_set_halign (drawarea, GTK_ALIGN_FILL);
  gtk_widget_set_valign (drawarea, GTK_ALIGN_FILL);
  gtk_container_add (GTK_CONTAINER (frame), drawarea);

  gtk_widget_set_events (drawarea, GDK_EXPOSURE_MASK | GDK_BUTTON_PRESS_MASK | GDK_BUTTON_RELEASE_MASK);
  g_signal_connect (G_OBJECT (drawarea), "configure_event",
                    G_CALLBACK (on_drawarea_resize), NULL);
  g_signal_connect (G_OBJECT (drawarea), "draw",
                    G_CALLBACK (on_drawarea_draw), NULL);
  g_signal_connect (G_OBJECT (drawarea), "button_press_event",
                    G_CALLBACK (on_button_press), NULL);
  g_signal_connect (G_OBJECT (window), "key_press_event",
                    G_CALLBACK (on_key_press), NULL);

  g_simple_action_set_enabled (G_SIMPLE_ACTION (hint_action), FALSE);
  g_simple_action_set_enabled (G_SIMPLE_ACTION (undo_action), FALSE);
}

void activate (GApplication *app, gpointer user_data);

int
main2 (int argc, char *argv[])
{
  GOptionContext *context;
  gboolean retval;
  GError *error = NULL;
  gint app_retval;

  bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
  bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
  textdomain (GETTEXT_PACKAGE);

  application = gtk_application_new ("org.gnome.four-in-a-row", 0);
  g_signal_connect (application, "startup", G_CALLBACK (create_app), NULL);
  g_signal_connect (application, "activate", G_CALLBACK (activate), NULL);

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
  if (!gfx_load_pixmaps ())
    exit (1);

  app_retval = g_application_run (G_APPLICATION (application), argc, argv);

  game_free ();

  return app_retval;
}
