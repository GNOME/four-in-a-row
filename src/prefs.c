/* -*- mode:C; indent-tabs-mode:t; tab-width:8; c-basic-offset:8; -*- */

/* prefs.c
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



#include <config.h>

#include <glib/gi18n.h>
#include <gtk/gtk.h>
#include <gdk/gdkkeysyms.h>

#include <libgames-support/games-controls.h>

#include "main.h"
#include "theme.h"
#include "prefs.h"
#include "gfx.h"

#define DEFAULT_THEME_ID       0
#define DEFAULT_KEY_LEFT       GDK_KEY_Left
#define DEFAULT_KEY_RIGHT      GDK_KEY_Right
#define DEFAULT_KEY_DROP       GDK_KEY_Down

Prefs p;

extern GSettings *settings;
extern GtkWidget *app;
extern Theme theme[];
extern gint n_themes;

static GtkWidget *prefsbox = NULL;
static GtkWidget *combobox1;
static GtkWidget *combobox2;
static GtkWidget *combobox_theme;
static GtkWidget *checkbutton_animate;
static GtkWidget *checkbutton_sound;

static gint
sane_theme_id (gint val)
{
  if (val < 0 || val >= n_themes)
    return DEFAULT_THEME_ID;
  return val;
}

static gint
sane_player_level (gint val)
{
  if (val < LEVEL_HUMAN)
    return LEVEL_HUMAN;
  if (val > LEVEL_STRONG)
    return LEVEL_STRONG;
  return val;
}

static void
settings_changed_cb (GSettings *settings,
                     const char *key,
                     gpointer user_data)
{
  if (strcmp (key, "animate") == 0) {
    p.do_animate = g_settings_get_boolean (settings, "animate");
    if (prefsbox == NULL)
      return;
    gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (checkbutton_animate),
                                  p.do_animate);
  } else if (strcmp (key, "sound") == 0) {
    p.do_sound = g_settings_get_boolean (settings, "sound");
    gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (checkbutton_sound),
                                  p.do_sound);
  } else if (strcmp (key, "key-left") == 0) {
    p.keypress[MOVE_LEFT] = g_settings_get_int (settings, "key-left");
  } else if (strcmp (key, "key-right") == 0) {
    p.keypress[MOVE_RIGHT] = g_settings_get_int (settings, "key-right");
  } else if (strcmp (key, "key-drop") == 0) {
    p.keypress[MOVE_DROP] = g_settings_get_int (settings, "key-drop");
  } else if (strcmp (key, "theme-id") == 0) {
    gint val;

    val = sane_theme_id (g_settings_get_int (settings, "theme-id"));
    if (val != p.theme_id) {
      p.theme_id = val;
      if (!gfx_change_theme ())
        return;
      if (prefsbox == NULL)
        return;
      gtk_combo_box_set_active (GTK_COMBO_BOX (combobox_theme), p.theme_id);
    }
  }
}

static void
on_select_theme (GtkComboBox * combo, gpointer data)
{
  gint id;

  id = gtk_combo_box_get_active (combo);
  g_settings_set_int (settings, "theme-id", id);
}



static void
on_toggle_animate (GtkToggleButton * t, gpointer data)
{
  p.do_animate = gtk_toggle_button_get_active (t);
  g_settings_set_boolean (settings, "animate", gtk_toggle_button_get_active (t));
}

static void
on_toggle_sound (GtkToggleButton * t, gpointer data)
{
  p.do_sound = gtk_toggle_button_get_active (t);
  g_settings_set_boolean (settings, "sound", gtk_toggle_button_get_active (t));
}

static void
on_select_player1 (GtkWidget * w, gpointer data)
{
  GtkTreeIter iter;
  gint value;

  if (!gtk_combo_box_get_active_iter (GTK_COMBO_BOX (w), &iter))
    return;
  gtk_tree_model_get (GTK_TREE_MODEL (gtk_combo_box_get_model (GTK_COMBO_BOX (w))), &iter, 1, &value, -1);

  p.level[PLAYER1] = value;
  g_settings_set_int (settings, "player1", value);
  scorebox_reset ();
  who_starts = PLAYER2;		/* This gets reversed in game_reset. */
  game_reset ();
}

static void
on_select_player2 (GtkWidget * w, gpointer data)
{
  GtkTreeIter iter;
  gint value;

  if (!gtk_combo_box_get_active_iter (GTK_COMBO_BOX (w), &iter))
    return;
  gtk_tree_model_get (GTK_TREE_MODEL (gtk_combo_box_get_model (GTK_COMBO_BOX (w))), &iter, 1, &value, -1);

  p.level[PLAYER2] = value;
  g_settings_set_int (settings, "player2", value);
  scorebox_reset ();
  who_starts = PLAYER2;		/* This gets reversed in game_reset. */
  game_reset ();
}

void
prefs_init (void)
{
  p.do_sound = g_settings_get_boolean (settings, "sound");
  p.do_animate = g_settings_get_boolean (settings, "animate");
  p.level[PLAYER1] = g_settings_get_int (settings, "player1");
  p.level[PLAYER2] = g_settings_get_int (settings, "player2");
  p.keypress[MOVE_LEFT] = g_settings_get_int (settings, "key-left");
  p.keypress[MOVE_RIGHT] = g_settings_get_int (settings, "key-right");
  p.keypress[MOVE_DROP] = g_settings_get_int (settings, "key-drop");
  p.theme_id = g_settings_get_int (settings, "theme-id");

  g_signal_connect (settings, "changed", G_CALLBACK (settings_changed_cb), NULL);

  p.level[PLAYER1] = sane_player_level (p.level[PLAYER1]);
  p.level[PLAYER2] = sane_player_level (p.level[PLAYER2]);
  p.theme_id = sane_theme_id (p.theme_id);
}

void
prefsbox_open (void)
{
  GtkWidget *notebook;
  GtkWidget *grid;
  GtkWidget *controls_list;
  GtkWidget *label;
  GtkCellRenderer *renderer;
  GtkListStore *model;
  GtkTreeIter iter;
  gint i;

  if (prefsbox != NULL) {
    gtk_window_present (GTK_WINDOW (prefsbox));
    return;
  }

  prefsbox = gtk_dialog_new_with_buttons (_("Four-in-a-Row Preferences"),
					  GTK_WINDOW (app),
					  GTK_DIALOG_DESTROY_WITH_PARENT,
					  GTK_STOCK_CLOSE,
					  GTK_RESPONSE_ACCEPT, NULL);
  gtk_container_set_border_width (GTK_CONTAINER (prefsbox), 5);
  gtk_box_set_spacing (GTK_BOX (gtk_dialog_get_content_area (GTK_DIALOG (prefsbox))),
		       2);

  g_signal_connect (G_OBJECT (prefsbox), "destroy",
		    G_CALLBACK (gtk_widget_destroyed), &prefsbox);

  notebook = gtk_notebook_new ();
  gtk_container_set_border_width (GTK_CONTAINER (notebook), 5);
  gtk_box_pack_start (GTK_BOX (gtk_dialog_get_content_area (GTK_DIALOG (prefsbox))), notebook, TRUE, TRUE, 0);

  /* game tab */

  grid = gtk_grid_new ();
  gtk_grid_set_row_spacing (GTK_GRID (grid), 6);
  gtk_grid_set_column_spacing (GTK_GRID (grid), 12);
  gtk_container_set_border_width (GTK_CONTAINER (grid), 12);

  label = gtk_label_new (_("Game"));
  gtk_notebook_append_page (GTK_NOTEBOOK (notebook), grid, label);

  label = gtk_label_new (_("Player One:"));
  gtk_widget_set_hexpand (label, TRUE);
  gtk_grid_attach (GTK_GRID (grid), label, 0, 0, 1, 1);

  combobox1 = gtk_combo_box_new ();
  renderer = gtk_cell_renderer_text_new ();
  gtk_cell_layout_pack_start (GTK_CELL_LAYOUT (combobox1), renderer, TRUE);
  gtk_cell_layout_add_attribute (GTK_CELL_LAYOUT (combobox1), renderer, "text", 0);
  model = gtk_list_store_new (2, G_TYPE_STRING, G_TYPE_INT);
  gtk_combo_box_set_model (GTK_COMBO_BOX (combobox1), GTK_TREE_MODEL (model));
  gtk_list_store_append (model, &iter);
  gtk_list_store_set (model, &iter, 0, _("Human"), 1, LEVEL_HUMAN, -1);
  if (p.level[PLAYER1] == LEVEL_HUMAN)
    gtk_combo_box_set_active_iter (GTK_COMBO_BOX (combobox1), &iter);
  gtk_list_store_append (model, &iter);
  gtk_list_store_set (model, &iter, 0, _("Level one"), 1, LEVEL_WEAK, -1);
  if (p.level[PLAYER1] == LEVEL_WEAK)
    gtk_combo_box_set_active_iter (GTK_COMBO_BOX (combobox1), &iter);
  gtk_list_store_append (model, &iter);
  gtk_list_store_set (model, &iter, 0, _("Level two"), 1, LEVEL_MEDIUM, -1);
  if (p.level[PLAYER1] == LEVEL_MEDIUM)
    gtk_combo_box_set_active_iter (GTK_COMBO_BOX (combobox1), &iter);
  gtk_list_store_append (model, &iter);
  gtk_list_store_set (model, &iter, 0, _("Level three"), 1, LEVEL_STRONG, -1);
  if (p.level[PLAYER1] == LEVEL_STRONG)
    gtk_combo_box_set_active_iter (GTK_COMBO_BOX (combobox1), &iter);
  g_signal_connect (combobox1, "changed", G_CALLBACK (on_select_player1), NULL);
  gtk_grid_attach (GTK_GRID (grid), combobox1, 1, 0, 1, 1);

  label = gtk_label_new (_("Player Two:"));
  gtk_grid_attach (GTK_GRID (grid), label, 0, 1, 1, 1);

  combobox2 = gtk_combo_box_new ();
  renderer = gtk_cell_renderer_text_new ();
  gtk_cell_layout_pack_start (GTK_CELL_LAYOUT (combobox2), renderer, TRUE);
  gtk_cell_layout_add_attribute (GTK_CELL_LAYOUT (combobox2), renderer, "text", 0);
  model = gtk_list_store_new (2, G_TYPE_STRING, G_TYPE_INT);
  gtk_combo_box_set_model (GTK_COMBO_BOX (combobox2), GTK_TREE_MODEL (model));
  gtk_list_store_append (model, &iter);
  gtk_list_store_set (model, &iter, 0, _("Human"), 1, LEVEL_HUMAN, -1);
  if (p.level[PLAYER2] == LEVEL_HUMAN)
    gtk_combo_box_set_active_iter (GTK_COMBO_BOX (combobox2), &iter);
  gtk_list_store_append (model, &iter);
  gtk_list_store_set (model, &iter, 0, _("Level one"), 1, LEVEL_WEAK, -1);
  if (p.level[PLAYER2] == LEVEL_WEAK)
    gtk_combo_box_set_active_iter (GTK_COMBO_BOX (combobox2), &iter);
  gtk_list_store_append (model, &iter);
  gtk_list_store_set (model, &iter, 0, _("Level two"), 1, LEVEL_MEDIUM, -1);
  if (p.level[PLAYER2] == LEVEL_MEDIUM)
    gtk_combo_box_set_active_iter (GTK_COMBO_BOX (combobox2), &iter);
  gtk_list_store_append (model, &iter);
  gtk_list_store_set (model, &iter, 0, _("Level three"), 1, LEVEL_STRONG, -1);
  if (p.level[PLAYER2] == LEVEL_STRONG)
    gtk_combo_box_set_active_iter (GTK_COMBO_BOX (combobox2), &iter);
  g_signal_connect (combobox2, "changed", G_CALLBACK (on_select_player2), NULL);
  gtk_grid_attach (GTK_GRID (grid), combobox2, 1, 1, 1, 1);

  label = gtk_label_new_with_mnemonic (_("_Theme:"));
  gtk_misc_set_alignment (GTK_MISC (label), 0.0, 0.5);
  gtk_grid_attach (GTK_GRID (grid), label, 0, 2, 1, 1);

  combobox_theme = gtk_combo_box_text_new ();
  for (i = 0; i < n_themes; i++) {
    gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox_theme),
		 	            _(theme_get_title (i)));
  }
  gtk_label_set_mnemonic_widget (GTK_LABEL (label), combobox_theme);
  gtk_grid_attach (GTK_GRID (grid), combobox_theme, 1, 2, 1, 1);

  checkbutton_animate =
    gtk_check_button_new_with_mnemonic (_("Enable _animation"));
  gtk_grid_attach (GTK_GRID (grid), checkbutton_animate, 0, 3, 2, 1);

  checkbutton_sound =
    gtk_check_button_new_with_mnemonic (_("E_nable sounds"));
  gtk_grid_attach (GTK_GRID (grid), checkbutton_sound, 0, 4, 2, 1);

  /* keyboard tab */

  label = gtk_label_new_with_mnemonic (_("Keyboard Controls"));

  controls_list = games_controls_list_new (settings);
  games_controls_list_add_controls (GAMES_CONTROLS_LIST (controls_list),
				    "key-left", _("Move left"), DEFAULT_KEY_LEFT,
                                    "key-right", _("Move right"), DEFAULT_KEY_RIGHT,
				    "key-drop", _("Drop marble"), DEFAULT_KEY_DROP,
                                    NULL);
  gtk_container_set_border_width (GTK_CONTAINER (controls_list), 12);
  gtk_notebook_append_page (GTK_NOTEBOOK (notebook), controls_list, label);

  /* fill in initial values */

  gtk_combo_box_set_active (GTK_COMBO_BOX (combobox_theme), p.theme_id);
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (checkbutton_animate),
				p.do_animate);
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (checkbutton_sound),
				p.do_sound);

  /* connect signals */

  g_signal_connect (prefsbox, "response", G_CALLBACK (on_dialog_close),
		    &prefsbox);

  g_signal_connect (G_OBJECT (combobox_theme), "changed",
		    G_CALLBACK (on_select_theme), NULL);

  g_signal_connect (G_OBJECT (checkbutton_animate), "toggled",
		    G_CALLBACK (on_toggle_animate), NULL);

  g_signal_connect (G_OBJECT (checkbutton_sound), "toggled",
		    G_CALLBACK (on_toggle_sound), NULL);

  gtk_widget_show_all (prefsbox);
}
