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



#include "config.h"
#include <gnome.h>
#include <gconf/gconf-client.h>
#include <games-gconf.h>
#include <games-frame.h>
#include <games-controls.h>
#include "main.h"
#include "theme.h"
#include "prefs.h"
#include "gfx.h"

#define DEFAULT_LEVEL_PLAYER1  LEVEL_HUMAN
#define DEFAULT_LEVEL_PLAYER2  LEVEL_WEAK
#define DEFAULT_THEME_ID       0
#define DEFAULT_KEY_LEFT       65361
#define DEFAULT_KEY_RIGHT      65363
#define DEFAULT_KEY_DROP       65364
#define DEFAULT_DO_TOOLBAR     FALSE
#define DEFAULT_DO_SOUND       TRUE
#define DEFAULT_DO_ANIMATE     TRUE

Prefs p;
GConfClient *conf_client = NULL;

extern GnomeUIInfo settings_menu_uiinfo[];
extern GtkWidget *app;
extern Theme theme[];
extern gint n_themes;

static GtkWidget *prefsbox = NULL;
static GtkWidget *frame_player1;
static GtkWidget *frame_player2;
static GtkWidget *radio1[4];
static GtkWidget *radio2[4];
static GtkWidget *combobox_theme;
static GtkWidget *checkbutton_animate;


static gint
gnect_gconf_get_int (gchar *key, gint default_int)
{
	/* First checks gconf, then schema, then defaults to the
	 * value passed. (Code taken from gataxx.)
	 */
	GConfValue *value = NULL;
	GConfValue *schema_value = NULL;
	gint retval;

	value = gconf_client_get (conf_client, key, NULL);
                                                                                
	if (value == NULL) return default_int;

	if (value->type == GCONF_VALUE_INT) {
		retval = gconf_value_get_int (value);
		gconf_value_free (value);
	}
	else {
		schema_value = gconf_client_get_default_from_schema (conf_client, key, NULL);
		if (schema_value == NULL) {
			retval = default_int;
		}
		else {
			retval = gconf_value_get_int (schema_value);
		}
		gconf_value_free (value);
		gconf_value_free (schema_value);
	}
	return retval;
}



static gboolean
gnect_gconf_get_bool (gchar *key, gboolean default_bool)
{
	GConfValue *value = NULL;
	GConfValue *schema_value = NULL;
	gboolean retval;

	value = gconf_client_get (conf_client, key, NULL);

	if (value == NULL) return default_bool;

	if (value->type == GCONF_VALUE_BOOL) {
		retval = gconf_value_get_bool (value);
		gconf_value_free (value);
	}
	else {
		schema_value = gconf_client_get_default_from_schema (conf_client, key, NULL);
		if (schema_value == NULL) {
			retval = default_bool;
		}
		else {
			retval = gconf_value_get_bool (schema_value);
		}
		gconf_value_free (value);
		gconf_value_free (schema_value);
	}
	return retval;
}



static gint
sane_theme_id (gint val)
{
	if (val < 0 || val >= n_themes) return DEFAULT_THEME_ID;
	return val;
}



static gint
sane_player_level (gint val)
{
	if (val < LEVEL_HUMAN) return LEVEL_HUMAN;
	if (val > LEVEL_STRONG) return LEVEL_STRONG;
	return val;
}



static void
prefsbox_update_player_labels (void)
{
	/* Make player selection labels match the current theme */

	gchar *str;

	if (prefsbox == NULL) return;

	str = g_strdup_printf (_("Player One:\n%s"), _(theme_get_player (PLAYER1)));
	games_frame_set_label (GAMES_FRAME (frame_player1), str);
	g_free (str);

	str = g_strdup_printf (_("Player Two:\n%s"), _(theme_get_player (PLAYER2)));
	games_frame_set_label (GAMES_FRAME (frame_player2), str);
	g_free (str);
}



static void
gconf_animate_changed (GConfClient *client, guint cnxn_id, GConfEntry *entry, gpointer user_data)
{
	p.do_animate = gconf_client_get_bool (conf_client, KEY_DO_ANIMATE, NULL);
	if (prefsbox == NULL) return;
	gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (checkbutton_animate), p.do_animate);
}



static void
gconf_toolbar_changed (GConfClient *client, guint cnxn_id, GConfEntry *entry, gpointer user_data)
{
	p.do_toolbar = gconf_client_get_bool (conf_client, KEY_DO_TOOLBAR, NULL);
	toolbar_changed ();
	gtk_check_menu_item_set_active (GTK_CHECK_MENU_ITEM(settings_menu_uiinfo[0].widget), p.do_toolbar);
}



static void
gconf_sound_changed (GConfClient *client, guint cnxn_id, GConfEntry *entry, gpointer user_data)
{
	p.do_sound = gconf_client_get_bool (conf_client, KEY_DO_SOUND, NULL);
	gtk_check_menu_item_set_active (GTK_CHECK_MENU_ITEM(settings_menu_uiinfo[1].widget), p.do_sound);
}



static void
gconf_keyleft_changed (GConfClient *client, guint cnxn_id, GConfEntry *entry, gpointer user_data)
{
	p.keypress[MOVE_LEFT] = gconf_client_get_int (conf_client, KEY_MOVE_LEFT, NULL);
}



static void
gconf_keyright_changed (GConfClient *client, guint cnxn_id, GConfEntry *entry, gpointer user_data)
{
	p.keypress[MOVE_RIGHT] = gconf_client_get_int (conf_client, KEY_MOVE_RIGHT, NULL);
}



static void
gconf_keydrop_changed (GConfClient *client, guint cnxn_id, GConfEntry *entry, gpointer user_data)
{
	p.keypress[MOVE_DROP] = gconf_client_get_int (conf_client, KEY_MOVE_DROP, NULL);
}



static void
gconf_theme_changed (GConfClient *client, guint cnxn_id, GConfEntry *entry, gpointer user_data)
{
	gint val;

	val = sane_theme_id (gconf_client_get_int (conf_client, KEY_THEME_ID, NULL));
	if (val != p.theme_id) {
		if (!gfx_load (val)) return;
		p.theme_id = val;
		if (prefsbox == NULL) return;
		gtk_combo_box_set_active (GTK_COMBO_BOX(combobox_theme), p.theme_id);
		prefsbox_update_player_labels ();
	}
}



static void
on_select_theme (GtkComboBox *combo, gpointer data)
{
	gint id;

	id = gtk_combo_box_get_active (combo);
	if (!gfx_load (id)) return;
	prefsbox_update_player_labels ();

	gconf_client_set_int (conf_client, KEY_THEME_ID, id, NULL);
}



static void
on_toggle_animate (GtkToggleButton *t, gpointer data)
{
	p.do_animate = t->active;
	gconf_client_set_bool (conf_client, KEY_DO_ANIMATE, t->active, NULL);
}


void
prefsbox_players_set_sensitive (gboolean sensitive)
{
	if (prefsbox == NULL) return;
	gtk_widget_set_sensitive (frame_player1, sensitive);
	gtk_widget_set_sensitive (frame_player2, sensitive);
}


static void
on_select_player1 (GtkWidget *w, gpointer data)
{
	if (!GTK_TOGGLE_BUTTON(w)->active) return;
	p.level[PLAYER1] = GPOINTER_TO_INT(data);
	gconf_client_set_int (conf_client, KEY_LEVEL_PLAYER1, 
                              GPOINTER_TO_INT(data), NULL);
	scorebox_reset ();
	game_reset (FALSE);
}



static void
on_select_player2 (GtkWidget *w, gpointer data)
{
	if (!GTK_TOGGLE_BUTTON(w)->active) return;
	p.level[PLAYER2] = GPOINTER_TO_INT(data);
	gconf_client_set_int (conf_client, KEY_LEVEL_PLAYER2, 
                              GPOINTER_TO_INT(data), NULL);
	scorebox_reset ();
	game_reset (FALSE);
}



void
prefs_init (gint argc, gchar **argv)
{
	gconf_init (argc, argv, NULL);
	conf_client = gconf_client_get_default ();
#if 0
	if (!games_gconf_sanity_check_string (conf_client, "/apps/gnect/theme")) {
		exit(1);
	}
#endif
	gconf_client_add_dir (conf_client, KEY_DIR, GCONF_CLIENT_PRELOAD_NONE, NULL);

	p.do_toolbar = gnect_gconf_get_bool (KEY_DO_TOOLBAR, DEFAULT_DO_TOOLBAR);
	p.do_sound   = gnect_gconf_get_bool (KEY_DO_SOUND, DEFAULT_DO_SOUND);
	p.do_animate = gnect_gconf_get_bool (KEY_DO_ANIMATE, DEFAULT_DO_ANIMATE);
	p.level[PLAYER1] = gnect_gconf_get_int (KEY_LEVEL_PLAYER1, DEFAULT_LEVEL_PLAYER1);
	p.level[PLAYER2] = gnect_gconf_get_int (KEY_LEVEL_PLAYER2, DEFAULT_LEVEL_PLAYER2);
	p.keypress[MOVE_LEFT]  = gnect_gconf_get_int (KEY_MOVE_LEFT, DEFAULT_KEY_LEFT);
	p.keypress[MOVE_RIGHT] = gnect_gconf_get_int (KEY_MOVE_RIGHT, DEFAULT_KEY_RIGHT);
	p.keypress[MOVE_DROP]  = gnect_gconf_get_int (KEY_MOVE_DROP, DEFAULT_KEY_DROP);
	p.theme_id = gnect_gconf_get_int (KEY_THEME_ID, DEFAULT_THEME_ID);

	gconf_client_notify_add (conf_client, KEY_DO_TOOLBAR,
	                         gconf_toolbar_changed, NULL, NULL, NULL);
	gconf_client_notify_add (conf_client, KEY_DO_SOUND,
	                         gconf_sound_changed, NULL, NULL, NULL);
	gconf_client_notify_add (conf_client, KEY_DO_ANIMATE,
	                         gconf_animate_changed, NULL, NULL, NULL);
	gconf_client_notify_add (conf_client, KEY_MOVE_LEFT,
	                         gconf_keyleft_changed, NULL, NULL, NULL);
	gconf_client_notify_add (conf_client, KEY_MOVE_RIGHT,
	                         gconf_keyright_changed, NULL, NULL, NULL);
	gconf_client_notify_add (conf_client, KEY_MOVE_DROP,
	                         gconf_keydrop_changed, NULL, NULL, NULL);
	gconf_client_notify_add (conf_client, KEY_THEME_ID,
	                         gconf_theme_changed, NULL, NULL, NULL);

	p.level[PLAYER1] = sane_player_level (p.level[PLAYER1]);
	p.level[PLAYER2] = sane_player_level (p.level[PLAYER2]);
	p.theme_id = sane_theme_id (p.theme_id);
}



static const gchar*
get_player_radio (LevelID id)
{
	switch (id) {
	case LEVEL_HUMAN:
		return _("Human");
	case LEVEL_WEAK:
		return _("Level one");
	case LEVEL_MEDIUM:
		return _("Level two");
	case LEVEL_STRONG:
		return _("Level three");
	}
	return "";
}



void
prefsbox_open (void)
{
	GtkWidget *notebook;
	GtkWidget *frame;
	GtkWidget *hbox;
	GtkWidget *vbox1, *vbox2;
	GtkWidget *controls_list;
	GtkWidget *label;
	GSList *group;
	gint i;

	if (prefsbox != NULL) {
		gtk_window_present (GTK_WINDOW(prefsbox));
		return;
	}

	prefsbox = gtk_dialog_new_with_buttons (_("Four-in-a-row Preferences"),
	                                        GTK_WINDOW(app),
	                                        GTK_DIALOG_DESTROY_WITH_PARENT,
	                                        GTK_STOCK_CLOSE, GTK_RESPONSE_ACCEPT,
	                                        NULL);
	gtk_dialog_set_has_separator (GTK_DIALOG(prefsbox), FALSE);
	g_signal_connect (G_OBJECT(prefsbox), "destroy",
	                  G_CALLBACK(gtk_widget_destroyed), &prefsbox);

	notebook = gtk_notebook_new ();
	gtk_box_pack_start (GTK_BOX(GTK_DIALOG(prefsbox)->vbox), notebook,
	                    TRUE, TRUE, 0);


	/* game tab */

	vbox1 = gtk_vbox_new (FALSE, 0);
	label = gtk_label_new_with_mnemonic (_("_Game"));
	gtk_notebook_append_page (GTK_NOTEBOOK(notebook), vbox1, label);

	hbox = gtk_hbox_new (FALSE, 0);
	gtk_box_pack_start (GTK_BOX (vbox1), hbox, TRUE, TRUE, 0);

	frame_player1 = games_frame_new (NULL);
	gtk_box_pack_start (GTK_BOX(hbox), frame_player1, TRUE, TRUE, 0);

	vbox2 = gtk_vbox_new (FALSE, 0);
	gtk_container_add (GTK_CONTAINER(frame_player1), vbox2);

	group = NULL;
	for (i = 0; i < 4; i++) {
		radio1[i] = gtk_radio_button_new_with_label (group, get_player_radio (i));
		group = gtk_radio_button_get_group (GTK_RADIO_BUTTON(radio1[i]));
		gtk_box_pack_start (GTK_BOX(vbox2), radio1[i], FALSE, FALSE, 0);
	}

	frame_player2 = games_frame_new (NULL);
	gtk_box_pack_start (GTK_BOX(hbox), frame_player2, TRUE, TRUE, 0);

	vbox2 = gtk_vbox_new (FALSE, 0);
	gtk_container_add (GTK_CONTAINER(frame_player2), vbox2);

	group = NULL;
	for (i = 0; i < 4; i++) {
		radio2[i] = gtk_radio_button_new_with_label (group, get_player_radio (i));
		group = gtk_radio_button_get_group (GTK_RADIO_BUTTON(radio2[i]));
		gtk_box_pack_start (GTK_BOX(vbox2), radio2[i], FALSE, FALSE, 0);
	}

	frame = games_frame_new (_("Appearance"));
	gtk_box_pack_start (GTK_BOX(vbox1), frame, TRUE, TRUE, 0);

	vbox2 = gtk_vbox_new (FALSE, 0);
	gtk_container_add (GTK_CONTAINER(frame), vbox2);

	hbox = gtk_hbox_new (FALSE, 0);
	gtk_box_pack_start (GTK_BOX(vbox2), hbox, FALSE, FALSE, 0);

	label = gtk_label_new_with_mnemonic (_("_Theme:"));
	gtk_box_pack_start (GTK_BOX(hbox), label, TRUE, TRUE, 0);
	gtk_misc_set_alignment (GTK_MISC(label), 7.45058e-09, 0.5);

	combobox_theme = gtk_combo_box_new_text ();
	for (i = 0; i < n_themes; i++) {
		gtk_combo_box_append_text (GTK_COMBO_BOX (combobox_theme),
					   _(theme_get_title (i)));
	}

	gtk_box_pack_start (GTK_BOX(hbox), combobox_theme, TRUE, TRUE, 0);

	gtk_label_set_mnemonic_widget (GTK_LABEL(label), combobox_theme);

	checkbutton_animate = gtk_check_button_new_with_mnemonic (_("Enable _animation"));
	gtk_box_pack_start (GTK_BOX(vbox2), checkbutton_animate, FALSE, FALSE, 6);


	/* keyboard tab */

	vbox1 = gtk_vbox_new (FALSE, 0);
	label = gtk_label_new_with_mnemonic (_("Controls"));
	gtk_notebook_append_page (GTK_NOTEBOOK(notebook), vbox1, label);

	frame = games_frame_new (_("Keyboard controls"));
	gtk_container_add (GTK_CONTAINER(vbox1), frame);

	vbox2 = gtk_vbox_new (FALSE, 6);
	gtk_container_add (GTK_CONTAINER(frame), vbox2);

	controls_list = games_controls_list_new ();
	games_controls_list_add_controls (GAMES_CONTROLS_LIST (controls_list), KEY_MOVE_LEFT, KEY_MOVE_RIGHT, KEY_MOVE_DROP);

	gtk_box_pack_start (GTK_BOX(vbox2), controls_list, FALSE, FALSE, 0);

	/* fill in initial values */

	prefsbox_update_player_labels ();
	gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON(radio1[p.level[PLAYER1]]), TRUE);
	gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON(radio2[p.level[PLAYER2]]), TRUE);
	gtk_combo_box_set_active (GTK_COMBO_BOX(combobox_theme), p.theme_id);
	gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON(checkbutton_animate), p.do_animate);

	/* connect signals */

	g_signal_connect (prefsbox, "response", G_CALLBACK(on_dialog_close), &prefsbox);
	
	for (i = 0; i < 4; i++) {
		g_signal_connect (G_OBJECT(radio1[i]), "toggled", G_CALLBACK(on_select_player1), GINT_TO_POINTER(i));
		g_signal_connect (G_OBJECT(radio2[i]), "toggled", G_CALLBACK(on_select_player2), GINT_TO_POINTER(i));
	}

	g_signal_connect (G_OBJECT (combobox_theme), "changed", G_CALLBACK (on_select_theme), NULL);

	g_signal_connect (G_OBJECT(checkbutton_animate), "toggled", G_CALLBACK(on_toggle_animate), NULL);

	gtk_widget_show_all (prefsbox);
}

