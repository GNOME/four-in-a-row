/* -*- mode:C; indent-tabs-mode:nil; tab-width:8; c-basic-offset:8; -*- */

/*
 * gnect prefs.c
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA. 
 */

#include "config.h"
#include <string.h>
#include <gconf/gconf-client.h>
#include <games-gconf.h>
#include <games-frame.h>
#include "main.h"
#include "gnect.h"
#include "prefs.h"
#include "gui.h"
#include "dialog.h"
#include "gfx.h"

#define DEFAULT_FNAME_THEME            "default.gnect"       /* If no prefs exist, start with this theme */
#define DEFAULT_PLAYER_1               PLAYER_HUMAN          /* Human */
#define DEFAULT_PLAYER_2               PLAYER_VELENA_WEAK    /* Velena Engine, first level */
#define DEFAULT_KEY_LEFT               106                   /* j */
#define DEFAULT_KEY_RIGHT              108                   /* l */
#define DEFAULT_KEY_DROP               107                   /* k */
#define DEFAULT_START_MODE             START_MODE_ALTERNATE  /* Players take turns at starting */
#define DEFAULT_SOUND_MODE             SOUND_MODE_BEEP       /* Speaker beep */
#define DEFAULT_DO_GRIDS               TRUE             /* Draw grids on background images by default */
#define DEFAULT_DO_ANIMATE             TRUE             /* Use animation by default */
#define DEFAULT_DO_TOOLBAR             FALSE            /* Toolbar disabled */
#define DEFAULT_DO_SOUND               TRUE             /* Sound enabled */

extern gint      debugging;
extern Gnect     gnect;
extern Anim      anim;
extern GtkWidget *app;
extern Theme     *theme_base;
extern Theme     *theme_current;

GConfClient *gnect_gconf_client = NULL;
Prefs  prefs;

static GtkWidget *frame_player_selection1;
static GtkWidget *frame_player_selection2;
static GtkWidget *dlg_prefs = NULL;
static GtkWidget *checkbutton_animate = NULL;
static GtkWidget *button_move[3];
static GtkWidget *entry_move[3];
static GtkWidget *optionmenu_theme = NULL;
static GtkWidget *optionmenu_theme_menu = NULL;
static GtkWidget *radio_player1[5];
static GtkWidget *radio_player2[5];
static GtkWidget *radio_start[3];
static GtkWidget *radio_sound[2];

static void prefs_dialog_update_player_selection_labels (void);
static void cb_prefs_gconf_player1_changed (GConfClient *client, guint cnxn_id,
                                            GConfEntry *entry, gpointer user_data);
static void cb_prefs_gconf_player2_changed (GConfClient *client, guint cnxn_id,
                                            GConfEntry *entry, gpointer user_data);
static void cb_prefs_gconf_who_starts_changed (GConfClient *client, guint cnxn_id,
                                               GConfEntry *entry, gpointer user_data);
static void cb_prefs_gconf_theme_changed (GConfClient *client, guint cnxn_id,
                                          GConfEntry *entry, gpointer user_data);
static void cb_prefs_gconf_key_left_changed (GConfClient *client, guint cnxn_id,
                                             GConfEntry *entry, gpointer user_data);
static void cb_prefs_gconf_key_right_changed (GConfClient *client, guint cnxn_id,
                                              GConfEntry *entry, gpointer user_data);
static void cb_prefs_gconf_key_drop_changed (GConfClient *client, guint cnxn_id,
                                             GConfEntry *entry, gpointer user_data);
static void cb_prefs_gconf_animate_changed (GConfClient *client, guint cnxn_id,
                                            GConfEntry *entry, gpointer user_data);
static void cb_prefs_gconf_sound_mode_changed (GConfClient *client, guint cnxn_id,
                                               GConfEntry *entry, gpointer user_data);


static void
prefs_check (void)
{
        /* sanity check important values */
        if (prefs.start_mode < 0 || prefs.start_mode > 2) {
                prefs.start_mode = DEFAULT_START_MODE;
                gconf_client_set_int (gnect_gconf_client, "/apps/gnect/startmode",
                                      prefs.start_mode, NULL);
        }
        if (prefs.player1 < 0 || prefs.player1 > 4) {
                prefs.player1 = DEFAULT_PLAYER_1;
                gconf_client_set_int (gnect_gconf_client, "/apps/gnect/player1",
                                      prefs.player1, NULL);
        }
        if (prefs.player2 < 0 || prefs.player2 > 4) {
                prefs.player2 = DEFAULT_PLAYER_2;
                gconf_client_set_int (gnect_gconf_client, "/apps/gnect/player2",
                                      prefs.player2, NULL);
        }
        if (prefs.sound_mode < 1 || prefs.sound_mode > 2) {
                prefs.sound_mode = DEFAULT_SOUND_MODE;
                gconf_client_set_int (gnect_gconf_client, "/apps/gnect/soundmode",
                                      prefs.sound_mode, NULL);
        }
}



static gint
gnect_gconf_get_int (gchar *key, gint default_int)
{
        /*
         * First checks gconf, then schema, then defaults to the
         * value passed. (Code & comment lifted from gataxx.)
         */
        GConfValue *value = NULL;
        GConfValue *schema_value = NULL;
        gint retval;

        value = gconf_client_get (gnect_gconf_client, key, NULL);

        if (value == NULL) {
                return default_int;
        }
        if (value->type == GCONF_VALUE_INT) {
                retval = gconf_value_get_int (value);
                gconf_value_free (value);
        }
        else {
                schema_value = gconf_client_get_default_from_schema
                               (gnect_gconf_client, key, NULL);
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
        /* (Code lifted from gataxx) */
  
        GConfValue *value = NULL;
        GConfValue *schema_value = NULL;
        gboolean retval;

        value = gconf_client_get (gnect_gconf_client, key, NULL);
        if (value == NULL) {
                return default_bool;
        }
        if (value->type == GCONF_VALUE_BOOL) {
                retval = gconf_value_get_bool (value);
                gconf_value_free (value);
        }
        else {
                schema_value = gconf_client_get_default_from_schema
                               (gnect_gconf_client, key, NULL);
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



static gchar *
gnect_gconf_get_string (gchar *key)
{
        /*
         * First checks gconf, then schema. Returns NULL if not found in
         * either. (Code & comment lifted from gataxx.)
         */

        GConfValue *value = NULL;
        GConfValue *schema_value = NULL;
        gchar *retval = NULL;

        value = gconf_client_get (gnect_gconf_client, key, NULL);
        if (value == NULL) {
                return NULL;
        }
        if (value->type == GCONF_VALUE_STRING) {
                retval = g_strdup (gconf_value_get_string (value));
                gconf_value_free (value);
        }
        else {
                schema_value = gconf_client_get_default_from_schema
                               (gnect_gconf_client, key, NULL);
                if (schema_value == NULL) {
                        retval = NULL;
                }
                else {
                        retval = g_strdup (gconf_value_get_string (schema_value));
                }
                gconf_value_free (value);
                gconf_value_free (schema_value);
        }
        return retval;
}



void
prefs_get (void)
{
        DEBUG_PRINT(1, "prefs_get\n");

        prefs.player1 = gnect_gconf_get_int ("/apps/gnect/player1", DEFAULT_PLAYER_1);
        prefs.player2 = gnect_gconf_get_int ("/apps/gnect/player2", DEFAULT_PLAYER_2);
        prefs.start_mode = gnect_gconf_get_int ("/apps/gnect/startmode", DEFAULT_START_MODE);
        prefs.fname_theme = gnect_gconf_get_string ("/apps/gnect/theme");
        if (!prefs.fname_theme) prefs.fname_theme = g_strdup (DEFAULT_FNAME_THEME);
        prefs.do_grids = gnect_gconf_get_bool ("/apps/gnect/grid", DEFAULT_DO_GRIDS);
        prefs.do_animate = gnect_gconf_get_bool ("/apps/gnect/animate", DEFAULT_DO_ANIMATE);
        prefs.do_sound = gnect_gconf_get_bool ("/apps/gnect/sound", DEFAULT_DO_SOUND);
        prefs.sound_mode = gnect_gconf_get_int ("/apps/gnect/soundmode", DEFAULT_SOUND_MODE);
        prefs.key[KEY_LEFT] = gnect_gconf_get_int ("/apps/gnect/keyleft", DEFAULT_KEY_LEFT);
        prefs.key[KEY_RIGHT] = gnect_gconf_get_int ("/apps/gnect/keyright", DEFAULT_KEY_RIGHT);
        prefs.key[KEY_DROP] = gnect_gconf_get_int ("/apps/gnect/keydrop", DEFAULT_KEY_DROP);
        prefs.do_toolbar = gnect_gconf_get_bool ("/apps/gnect/toolbar", DEFAULT_DO_TOOLBAR);

        prefs.descr_player1 = NULL;
        prefs.descr_player2 = NULL;

        prefs_check ();
}



void
prefs_save (void)
{
        /* FIXME: prefs_save() is no longer used - remove from here, prefs.h and gnect.c */
}


void
prefs_init (gint argc, gchar **argv)
{
        gint i;


        for (i = 0; i < 4; i++) {
                radio_player1[i] = NULL;
                radio_player2[i] = NULL;
        }
        for (i = 0; i < 3; i++) {radio_start[i] = NULL; entry_move[i] = NULL;}
        for (i = 0; i < 2; i++) radio_sound[i] = NULL;

        gconf_init (argc, argv, NULL);
        gnect_gconf_client = gconf_client_get_default ();
        if (!games_gconf_sanity_check_string (gnect_gconf_client, "/apps/gnect/theme")) {
          exit(1);
        }

        gconf_client_add_dir (gnect_gconf_client, "/apps/gnect",
                              GCONF_CLIENT_PRELOAD_NONE, NULL);

        prefs_get ();

        gconf_client_notify_add (gnect_gconf_client, "/apps/gnect/player1",
                                 cb_prefs_gconf_player1_changed, NULL, NULL, NULL);
        gconf_client_notify_add (gnect_gconf_client, "/apps/gnect/player2",
                                 cb_prefs_gconf_player2_changed, NULL, NULL, NULL);
        gconf_client_notify_add (gnect_gconf_client, "/apps/gnect/startmode",
                                 cb_prefs_gconf_who_starts_changed, NULL, NULL, NULL);

        gconf_client_notify_add (gnect_gconf_client, "/apps/gnect/theme",
                                 cb_prefs_gconf_theme_changed, NULL, NULL, NULL);

        gconf_client_notify_add (gnect_gconf_client, "/apps/gnect/keyleft",
                                 cb_prefs_gconf_key_left_changed, NULL, NULL, NULL);
        gconf_client_notify_add (gnect_gconf_client, "/apps/gnect/keyright",
                                 cb_prefs_gconf_key_right_changed, NULL, NULL, NULL);
        gconf_client_notify_add (gnect_gconf_client, "/apps/gnect/keydrop",
                                 cb_prefs_gconf_key_drop_changed, NULL, NULL, NULL);

        gconf_client_notify_add (gnect_gconf_client, "/apps/gnect/animate",
                                 cb_prefs_gconf_animate_changed, NULL, NULL, NULL);
        gconf_client_notify_add (gnect_gconf_client, "/apps/gnect/soundmode",
                                 cb_prefs_gconf_sound_mode_changed, NULL, NULL, NULL);
}

  
  
void
prefs_free (void)
{
        g_free (prefs.fname_theme);
        g_object_unref (G_OBJECT(gnect_gconf_client));
}



static void
prefs_dialog_update_player_selection_labels (void)
{
        if (dlg_prefs) {

                gchar *label_player1, *label_player2;

                label_player1 = g_strdup_printf (_("Player 1: %s"), prefs.descr_player1);
                label_player2 = g_strdup_printf (_("Player 2: %s"), prefs.descr_player2);
                games_frame_set_label (GAMES_FRAME (frame_player_selection1), label_player1);
                games_frame_set_label (GAMES_FRAME (frame_player_selection2), label_player2);

                g_free (label_player1);
                g_free (label_player2);

        }
}


#if 0
static gboolean
prefs_verify_kill_game ()
{
        gint response;
        GtkWidget *dialog;


       	dialog = gtk_message_dialog_new (GTK_WINDOW (dlg_prefs),
                                         GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT,
                                         GTK_MESSAGE_QUESTION,
                                         GTK_BUTTONS_OK_CANCEL,
                                         _("Applying this change to Player Selection\nwill end the current game"));

       	gtk_dialog_set_default_response (GTK_DIALOG (dialog), GTK_RESPONSE_YES);
        gtk_dialog_set_has_separator (GTK_DIALOG (dialog), FALSE);
       	response = gtk_dialog_run (GTK_DIALOG (dialog));
		
       	gtk_widget_destroy (dialog);
       	
       	return response == GTK_RESPONSE_OK;
}
#endif


static void
cb_prefs_gconf_player1_changed (GConfClient *client, guint cnxn_id, GConfEntry *entry, gpointer user_data)
{
        gint player1_tmp;


        player1_tmp = gconf_client_get_int (gnect_gconf_client, "/apps/gnect/player1", NULL);
        if (player1_tmp != prefs.player1) {
                prefs.player1 = player1_tmp;
                prefs_check ();
                if (radio_player1[0] != NULL) {
                        gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON(radio_player1[prefs.player1]), TRUE);
                        gnect_reset (FALSE);
                        gnect_reset_display ();
                        gnect_reset_scores ();
                        gui_set_status_prompt_new_game (STATUS_MSG_SET);
                }
        }
}



static void
cb_prefs_dialog_player1_select (GtkWidget *widget, gpointer *data)
{
        if (!gtk_toggle_button_get_active (GTK_TOGGLE_BUTTON(radio_player1[(gint)data]))) return;
        prefs.player1 = (gint)data;
        gconf_client_set_int (gnect_gconf_client, "/apps/gnect/player1", prefs.player1, NULL);

        gnect_reset (FALSE);
        gnect_reset_display ();
        gnect_reset_scores ();
        gui_set_status_prompt_new_game (STATUS_MSG_SET);
}



static void
cb_prefs_gconf_player2_changed (GConfClient *client, guint cnxn_id, GConfEntry *entry, gpointer user_data)
{
        gint player2_tmp;


        player2_tmp = gconf_client_get_int (gnect_gconf_client, "/apps/gnect/player2", NULL);
        if (player2_tmp != prefs.player2) {
                prefs.player2 = player2_tmp;
                prefs_check ();
                if (radio_player2[0] != NULL) {
                        gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON(radio_player2[prefs.player2]), TRUE);
                        gnect_reset (FALSE);
                        gnect_reset_display ();
                        gnect_reset_scores ();
                        gui_set_status_prompt_new_game (STATUS_MSG_SET);
                }
        }
}



static void
cb_prefs_dialog_player2_select (GtkWidget *widget, gpointer *data)
{
        if (!gtk_toggle_button_get_active (GTK_TOGGLE_BUTTON(radio_player2[(gint)data]))) return;
        prefs.player2 = (gint)data;
        gconf_client_set_int (gnect_gconf_client, "/apps/gnect/player2", prefs.player2, NULL);

        gnect_reset (FALSE);
        gnect_reset_display ();
        gnect_reset_scores ();
        gui_set_status_prompt_new_game (STATUS_MSG_SET);
}



static void
cb_prefs_gconf_who_starts_changed (GConfClient *client, guint cnxn_id, GConfEntry *entry, gpointer user_data)
{
        gint start_mode_tmp;


        start_mode_tmp = gconf_client_get_int (gnect_gconf_client, "/apps/gnect/startmode", NULL);
        if (start_mode_tmp != prefs.start_mode) {
                prefs.start_mode = start_mode_tmp;
                prefs_check ();
                if (radio_start[0] != NULL) {
                        gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON(radio_start[prefs.start_mode]), TRUE);
                }
        }
}



static void
cb_prefs_dialog_who_starts_select (GtkWidget *widget, gpointer *data)
{
        prefs.start_mode = (gint)data;
        gconf_client_set_int (gnect_gconf_client, "/apps/gnect/startmode", prefs.start_mode, NULL);
}



static void
cb_prefs_gconf_animate_changed (GConfClient *client, guint cnxn_id, GConfEntry *entry, gpointer user_data)
{
        gboolean animate_tmp;


        animate_tmp = gconf_client_get_bool (gnect_gconf_client, "/apps/gnect/animate", NULL);
        if (animate_tmp != prefs.do_animate) {
                prefs.do_animate = animate_tmp;
                if (checkbutton_animate != NULL) {
                        gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (checkbutton_animate), prefs.do_animate);
                }
        }
}



static void
cb_prefs_dialog_animate_select (GtkWidget *widget, gpointer *data)
{
        prefs.do_animate = GTK_TOGGLE_BUTTON(widget)->active;
        gconf_client_set_bool (gnect_gconf_client, "/apps/gnect/animate",  prefs.do_animate, NULL);
}



static void
cb_prefs_gconf_sound_mode_changed (GConfClient *client, guint cnxn_id, GConfEntry *entry, gpointer user_data)
{
        gint sound_mode_tmp;


        sound_mode_tmp = gconf_client_get_int (gnect_gconf_client, "/apps/gnect/soundmode", NULL);
        if (sound_mode_tmp != prefs.sound_mode) {
                prefs.sound_mode = sound_mode_tmp;
                prefs_check ();
                if (radio_sound[0] != NULL) {
                        gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON(radio_sound[prefs.sound_mode - 1]), TRUE);
                }
        }
}



static void
cb_prefs_dialog_sound_select (GtkWidget *widget, gpointer *data)
{
        prefs.sound_mode = (gint)data;
        gconf_client_set_int (gnect_gconf_client, "/apps/gnect/soundmode", prefs.sound_mode, NULL);
}



static void
prefs_theme_switched (Theme *theme)
{
        /* redraw player descriptions wherever they might be visible */

        prefs_dialog_update_player_selection_labels ();

        dialog_score_update ();

        /* update status bar prompt */

        if (!gnect.over) {
                gui_set_status_prompt (gnect.current_player);
        }
        else if (gnect.winner != -1) {
                gui_set_status_winner (gnect.winner, FALSE);
        }

        prefs.fname_theme = theme->fname;
        prefs.descr_player1 = theme->descr_player1;
        prefs.descr_player2 = theme->descr_player2;
        gconf_client_set_string (gnect_gconf_client, "/apps/gnect/theme", prefs.fname_theme, NULL);
}



static void
cb_prefs_gconf_theme_changed (GConfClient *client, guint cnxn_id, GConfEntry *entry, gpointer user_data)
{ 
        Theme *theme;
        gchar *fname_tmp;


        fname_tmp = gconf_client_get_string (gnect_gconf_client, "/apps/gnect/theme", NULL);
        if (strcmp (fname_tmp, theme_current->fname) != 0) {

                theme = theme_get_ptr_from_fname (fname_tmp);
                if (theme != NULL && theme_load (theme)) {

                        prefs_theme_switched (theme);

                        if (optionmenu_theme != NULL) {
                                gtk_option_menu_set_history (GTK_OPTION_MENU(optionmenu_theme), theme_current->id);
                        }
                }
                else {
                        gconf_client_set_string (gnect_gconf_client, "/apps/gnect/theme",
                                                 theme_current->fname, NULL);
                }
        }
}



static void
cb_prefs_dialog_theme_select (GtkWidget *widget, gpointer *data)
{
        Theme *theme = (Theme*)data;


        if (strcmp (theme->fname, prefs.fname_theme) != 0) {

                if (!theme_load (theme)) {

                        gnome_app_warning (GNOME_APP(app), _("Error loading theme"));

                }
                else {

                        prefs_theme_switched (theme);
                        gconf_client_set_string (gnect_gconf_client, "/apps/gnect/theme",
                                                 theme_current->fname, NULL);

                }
        }
}



static void
cb_prefs_gconf_key_left_changed (GConfClient *client, guint cnxn_id, GConfEntry *entry, gpointer user_data)
{
        gint key_tmp;


        key_tmp = gconf_client_get_int (gnect_gconf_client, "/apps/gnect/keyleft", NULL);
        if (key_tmp != prefs.key[KEY_LEFT]) {
                prefs.key[KEY_LEFT] = key_tmp;
                if (entry_move[KEY_LEFT] != NULL) {
                        gtk_entry_set_text (GTK_ENTRY(entry_move[KEY_LEFT]), gdk_keyval_name (prefs.key[KEY_LEFT]));
                }
        }
}



static void
cb_prefs_gconf_key_right_changed (GConfClient *client, guint cnxn_id, GConfEntry *entry, gpointer user_data)
{
        gint key_tmp;


        key_tmp = gconf_client_get_int (gnect_gconf_client, "/apps/gnect/keyright", NULL);
        if (key_tmp != prefs.key[KEY_RIGHT]) {
                prefs.key[KEY_RIGHT] = key_tmp;
                if (entry_move[KEY_RIGHT] != NULL) {
                        gtk_entry_set_text (GTK_ENTRY(entry_move[KEY_RIGHT]), gdk_keyval_name (prefs.key[KEY_RIGHT]));
                }
        }
}



static void
cb_prefs_gconf_key_drop_changed (GConfClient *client, guint cnxn_id, GConfEntry *entry, gpointer user_data)
{
        gint key_tmp;


        key_tmp = gconf_client_get_int (gnect_gconf_client, "/apps/gnect/keydrop", NULL);
        if (key_tmp != prefs.key[KEY_DROP]) {
                prefs.key[KEY_DROP] = key_tmp;
                if (entry_move[KEY_DROP] != NULL) {
                        gtk_entry_set_text (GTK_ENTRY(entry_move[KEY_DROP]), gdk_keyval_name (prefs.key[KEY_DROP]));
                }
        }
}



static void
keyboard_entries_set_sensitive (gboolean sensitive)
{
        gint i;

        for (i = 0; i < 3; i++) {
                gtk_widget_set_sensitive (entry_move[i], sensitive);
        }
}



static void
cb_button_move_clicked (GtkWidget *button, gpointer key_select)
{
        keyboard_entries_set_sensitive (FALSE);
        gtk_widget_set_sensitive (entry_move[(gint)key_select], TRUE);
        gtk_widget_grab_focus (entry_move[(gint)key_select]);
}



static void
cb_prefs_dialog_key_select (GtkWidget *widget, GdkEventKey *data)
{
        gint key_select;

        gtk_entry_set_text (GTK_ENTRY(widget), gdk_keyval_name (data->keyval));

        if (widget == entry_move[KEY_LEFT]) {
                key_select = KEY_LEFT;
                prefs.key[KEY_LEFT] = data->keyval;
                gconf_client_set_int (gnect_gconf_client, "/apps/gnect/keyleft", prefs.key[KEY_LEFT], NULL);
        }
        else if (widget == entry_move[KEY_RIGHT]) {
                key_select = KEY_RIGHT;
                prefs.key[KEY_RIGHT] = data->keyval;
                gconf_client_set_int (gnect_gconf_client, "/apps/gnect/keyright", prefs.key[KEY_RIGHT], NULL);
        }
        else {
                key_select = KEY_DROP;
                prefs.key[KEY_DROP] = data->keyval;
                gconf_client_set_int (gnect_gconf_client, "/apps/gnect/keydrop", prefs.key[KEY_DROP], NULL);
        }
        gtk_widget_set_sensitive (widget, FALSE);
        gtk_widget_grab_focus (button_move[key_select]);
}

static void
prefs_dialog_fill_theme_menu (void)
{
        /* add theme titles to theme selection menu */


        Theme *theme = theme_base;
        gint itemno = 0;


        while (theme) {

                GtkWidget *item;

                gchar *title = theme->title;

                item = gtk_menu_item_new_with_label (title);

                if (theme->tooltip) gui_set_tooltip (GTK_WIDGET(item), theme->tooltip);

                gtk_widget_show (item);
                gtk_menu_shell_append (GTK_MENU_SHELL (optionmenu_theme_menu), item);
                g_signal_connect (GTK_OBJECT(item), "activate", GTK_SIGNAL_FUNC(cb_prefs_dialog_theme_select), theme);

                /* select current theme */
                if (strcmp (prefs.fname_theme, theme->fname) == 0) {
                        gtk_menu_set_active (GTK_MENU (optionmenu_theme_menu), itemno);
                }

                itemno++;

                theme = theme->next;

        }
}



static gchar *
prefs_dialog_get_player_selection_label (gint n)
{
        switch (n) {
        case 0 :
                return _("Human");
                break;
        case 1 :
                return _("Non-Velena / Simple");
                break;
        case 2 :
                return _("Velena / Weak");
                break;
        case 3 :
                return _("Velena / Medium");
                break;
        case 4 :
                return _("Velena / Strong");
                break;
        }
        return "";
}



static gchar *
prefs_dialog_get_who_starts_label (gint n)
{
        switch (n) {
        case 0 :
                return _("Always Player 1");
                break;
        case 1 :
                return _("Always Player 2");
                break;
        case 2 :
                return _("Take turns");
                break;
        }
        return "";
}



static void
prefs_dialog_create (void)
{
        GtkWidget *action_area;
        GtkWidget *vbox1, *vbox2, *hbox1;
        GtkWidget *frame;
        GtkWidget *label;
        GtkWidget *table;
        GSList    *group_player1 = NULL;
        GSList    *group_player2 = NULL;
        GSList    *group_start   = NULL;
        GSList    *group_sound   = NULL;
        gint i;


        DEBUG_PRINT (1, "prefs_dialog_create\n");

        dlg_prefs = gtk_dialog_new_with_buttons (_("Four-in-a-row Preferences"),
                                                 GTK_WINDOW (app),
                                                 GTK_DIALOG_DESTROY_WITH_PARENT,
                                                 /* GTK_STOCK_HELP, GTK_RESPONSE_HELP, */
                                                 GTK_STOCK_CLOSE, GTK_RESPONSE_ACCEPT,
                                                 NULL);
        gtk_dialog_set_has_separator (GTK_DIALOG (dlg_prefs), FALSE);
        g_signal_connect (GTK_OBJECT(dlg_prefs), "destroy",
                          GTK_SIGNAL_FUNC(gtk_widget_destroyed), &dlg_prefs);

        action_area = gtk_notebook_new ();
        gtk_box_pack_start (GTK_BOX (GTK_DIALOG (dlg_prefs)->vbox), action_area,
                            TRUE, TRUE, 0);

        vbox1 = gtk_vbox_new (FALSE, 0);
        gtk_container_set_border_width (GTK_CONTAINER (vbox1), 10);

        label = gtk_label_new_with_mnemonic (_("_Player Selection"));
	gtk_notebook_append_page (GTK_NOTEBOOK (action_area), vbox1, label);

        table = gtk_table_new (2, 2, FALSE);
        gtk_box_pack_start (GTK_BOX (vbox1), table, FALSE, FALSE, 0);

        /* player 1 */

        frame_player_selection1 = games_frame_new (NULL);
        gtk_table_attach_defaults (GTK_TABLE (table), frame_player_selection1, 0, 1, 0, 1);

        vbox2 = gtk_vbox_new (FALSE, 0);
        gtk_container_add (GTK_CONTAINER (frame_player_selection1), vbox2);

        for (i = 0; i < 5; i++) {
                radio_player1[i] = gtk_radio_button_new_with_label
                  (group_player1, prefs_dialog_get_player_selection_label (i));
                group_player1 = gtk_radio_button_get_group (GTK_RADIO_BUTTON(radio_player1[i]));
                gtk_box_pack_start (GTK_BOX (vbox2), radio_player1[i], FALSE, FALSE, 0);
                gtk_container_set_border_width (GTK_CONTAINER (radio_player1[i]), 3);
        }

        /* player 2 */

        frame_player_selection2 = games_frame_new (NULL);
        gtk_table_attach_defaults (GTK_TABLE (table), frame_player_selection2, 1, 2, 0, 1);

        vbox2 = gtk_vbox_new (FALSE, 0);
        gtk_container_add (GTK_CONTAINER (frame_player_selection2), vbox2);

        for (i = 0; i < 5; i++) {
                radio_player2[i] = gtk_radio_button_new_with_label (group_player2, prefs_dialog_get_player_selection_label (i));
                group_player2 = gtk_radio_button_get_group (GTK_RADIO_BUTTON(radio_player2[i]));
                gtk_box_pack_start (GTK_BOX(vbox2), radio_player2[i], FALSE, FALSE, 0);
                gtk_container_set_border_width (GTK_CONTAINER(radio_player2[i]), 3);
        }

        /* who starts? */

        frame = games_frame_new (_("Who starts?"));
        gtk_table_attach_defaults (GTK_TABLE (table), frame, 0, 1, 1, 2);

        vbox2 = gtk_vbox_new (FALSE, 0);
        gtk_container_add (GTK_CONTAINER (frame), vbox2);

        for (i = 0; i < 3; i++) {
                radio_start[i] = gtk_radio_button_new_with_label (group_start, prefs_dialog_get_who_starts_label (i));
                group_start = gtk_radio_button_get_group (GTK_RADIO_BUTTON (radio_start[i]));
                gtk_box_pack_start (GTK_BOX (vbox2), radio_start[i], FALSE, FALSE, 0);
                gtk_container_set_border_width (GTK_CONTAINER (radio_start[i]), 3);
        }

        /* theme */
        label = gtk_label_new (_("Appearance and Behaviour"));
        vbox2 = gtk_vbox_new (FALSE, 0);
	gtk_notebook_append_page (GTK_NOTEBOOK (action_area), vbox2, label);

        table = gtk_table_new (3, 1, FALSE);
        gtk_box_pack_start (GTK_BOX (vbox2), table, FALSE, FALSE, 0);

        frame = games_frame_new (_("Theme"));
        gtk_table_attach_defaults (GTK_TABLE (table), frame, 0, 1, 0, 1);

        vbox1 = gtk_vbox_new (FALSE, 0);
        gtk_container_set_border_width (GTK_CONTAINER(vbox1), 5);
        gtk_container_add (GTK_CONTAINER (frame), vbox1);

	hbox1 = gtk_hbox_new (FALSE, 6);
        gtk_box_pack_start (GTK_BOX (vbox1), hbox1, FALSE, FALSE, 0);

        label = gtk_label_new (_("Theme Selection:"));
        gtk_box_pack_start (GTK_BOX (hbox1), label, FALSE, FALSE, 0);
        gtk_misc_set_alignment (GTK_MISC (label), 0, 0.5);

        optionmenu_theme = gtk_option_menu_new ();
        gtk_box_pack_start (GTK_BOX (hbox1), optionmenu_theme, FALSE, FALSE, 0);

        optionmenu_theme_menu = gtk_menu_new ();
        prefs_dialog_fill_theme_menu ();
        gtk_option_menu_set_menu (GTK_OPTION_MENU (optionmenu_theme),
                                  optionmenu_theme_menu);

        /* animation */
        frame = games_frame_new (_("Animation"));
        gtk_table_attach_defaults (GTK_TABLE (table), frame, 0, 1, 1, 2);

        vbox1 = gtk_vbox_new (FALSE, 0);
        gtk_container_set_border_width (GTK_CONTAINER (vbox1), 5);
        gtk_container_add (GTK_CONTAINER (frame), vbox1);

        checkbutton_animate = gtk_check_button_new_with_label (_("Enable animation"));
        gtk_box_pack_start (GTK_BOX(vbox1), checkbutton_animate, FALSE, FALSE, 0);

        /* sound */

        frame = games_frame_new (_("Sound Type"));
        gtk_table_attach_defaults (GTK_TABLE (table), frame, 0, 1, 2, 3);
        vbox1 = gtk_vbox_new (FALSE, 0);
        gtk_container_add (GTK_CONTAINER (frame), vbox1);

        radio_sound[0] = gtk_radio_button_new_with_label (group_sound, _("Speaker beep"));
        group_sound = gtk_radio_button_get_group (GTK_RADIO_BUTTON (radio_sound[0]));
        gtk_box_pack_start (GTK_BOX (vbox1), radio_sound[0], FALSE, FALSE, 0);

        radio_sound[1] = gtk_radio_button_new_with_label (group_sound, _("GNOME sound"));
        group_sound = gtk_radio_button_get_group (GTK_RADIO_BUTTON (radio_sound[1]));
        gui_set_tooltip (GTK_WIDGET (radio_sound[1]), _("This can be set up using the GNOME Control Center"));
        gtk_box_pack_start (GTK_BOX (vbox1), radio_sound[1], FALSE, FALSE, 0);


        /* keyboard */
        label = gtk_label_new (_("Controls"));
        vbox2 = gtk_vbox_new (FALSE, 0);
	gtk_notebook_append_page (GTK_NOTEBOOK (action_area), vbox2, label);

        frame = games_frame_new (_("Keyboard Control"));
        gtk_box_pack_start (GTK_BOX (vbox2), frame, TRUE, TRUE, 5);

        vbox1 = gtk_vbox_new (FALSE, 0);
        gtk_container_set_border_width (GTK_CONTAINER(vbox1), 5);
        gtk_container_add (GTK_CONTAINER (frame), vbox1);

        table = gtk_table_new (3, 2, FALSE);
        gtk_box_pack_start (GTK_BOX(vbox1), table, FALSE, FALSE, 0);
        gtk_container_set_border_width (GTK_CONTAINER(table), 5);
        gtk_table_set_row_spacings (GTK_TABLE (table), 6);
        gtk_table_set_col_spacings (GTK_TABLE (table), 12);
  
        button_move[KEY_LEFT] = gtk_button_new_with_label (_("Move left"));
        gtk_widget_show (button_move[KEY_LEFT]);
        gtk_table_attach (GTK_TABLE(table), button_move[KEY_LEFT], 0, 1, 0, 1,
                          (GtkAttachOptions)(GTK_EXPAND | GTK_FILL),
                          (GtkAttachOptions)(0), 0, 0);
  
        button_move[KEY_RIGHT] = gtk_button_new_with_label (_("Move right"));
        gtk_widget_show (button_move[KEY_RIGHT]);
        gtk_table_attach (GTK_TABLE(table), button_move[KEY_RIGHT], 0, 1, 1, 2
,
                          (GtkAttachOptions)(GTK_EXPAND | GTK_FILL),
                          (GtkAttachOptions)(0), 0, 0);
  
        button_move[KEY_DROP] = gtk_button_new_with_label (_("Drop counter"));
        gtk_widget_show (button_move[KEY_DROP]);
        gtk_table_attach (GTK_TABLE(table), button_move[KEY_DROP], 0, 1, 2, 3,
                          (GtkAttachOptions)(GTK_EXPAND | GTK_FILL),
                          (GtkAttachOptions)(0), 0, 0);
        entry_move[KEY_LEFT] = gtk_entry_new ();
        gtk_widget_show (entry_move[KEY_LEFT]);
        gtk_table_attach (GTK_TABLE(table), entry_move[KEY_LEFT], 1, 2, 0, 1,
                          (GtkAttachOptions)(GTK_EXPAND | GTK_FILL),
                          (GtkAttachOptions)(0), 0, 0);
        gtk_entry_set_width_chars (GTK_ENTRY (entry_move[KEY_LEFT]), 8);
        
        entry_move[KEY_RIGHT] = gtk_entry_new ();
        gtk_widget_show (entry_move[KEY_RIGHT]);
        gtk_table_attach (GTK_TABLE(table), entry_move[KEY_RIGHT], 1, 2, 1, 2,
                          (GtkAttachOptions)(GTK_EXPAND | GTK_FILL),
                          (GtkAttachOptions)(0), 0, 0);
        gtk_entry_set_width_chars (GTK_ENTRY (entry_move[KEY_RIGHT]), 8);
        
        entry_move[KEY_DROP] = gtk_entry_new ();
        gtk_widget_show (entry_move[KEY_DROP]);
        gtk_table_attach (GTK_TABLE(table), entry_move[KEY_DROP], 1, 2, 2, 3,
                          (GtkAttachOptions)(GTK_EXPAND | GTK_FILL),
                          (GtkAttachOptions)(0), 0, 0);
        gtk_entry_set_width_chars (GTK_ENTRY (entry_move[KEY_DROP]), 8);
        
        gtk_label_set_mnemonic_widget (GTK_LABEL(label), optionmenu_theme);


        /* fill in values */

        prefs_dialog_update_player_selection_labels ();

        gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON(radio_player1[prefs.player1]), TRUE);
        gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON(radio_player2[prefs.player2]), TRUE);
        gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON(radio_start[prefs.start_mode]), TRUE);

        gtk_option_menu_set_history (GTK_OPTION_MENU(optionmenu_theme), theme_current->id);

        gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON(checkbutton_animate), prefs.do_animate);

        gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON(radio_sound[prefs.sound_mode - 1]), TRUE);
        
        gtk_entry_set_text (GTK_ENTRY(entry_move[KEY_LEFT]), gdk_keyval_name (prefs.key[KEY_LEFT]));
        gtk_entry_set_text (GTK_ENTRY(entry_move[KEY_RIGHT]), gdk_keyval_name (prefs.key[KEY_RIGHT]));
        gtk_entry_set_text (GTK_ENTRY(entry_move[KEY_DROP]), gdk_keyval_name (prefs.key[KEY_DROP]));

        keyboard_entries_set_sensitive (FALSE);
        
        /* signals */

        g_signal_connect (dlg_prefs, "response", G_CALLBACK(gtk_widget_hide), NULL);
        for (i = 0; i < 5; i++) {
                g_signal_connect (GTK_OBJECT(radio_player1[i]), "toggled", GTK_SIGNAL_FUNC(cb_prefs_dialog_player1_select),(gpointer)i);
                g_signal_connect (GTK_OBJECT(radio_player2[i]), "toggled", GTK_SIGNAL_FUNC(cb_prefs_dialog_player2_select),(gpointer)i);
        }
        for (i = 0; i < 3; i++) {
                g_signal_connect (GTK_OBJECT(radio_start[i]), "toggled",
                                  GTK_SIGNAL_FUNC(cb_prefs_dialog_who_starts_select),
                                  (gpointer)i);
                gtk_entry_set_text (GTK_ENTRY(entry_move[i]),
                                    gdk_keyval_name (prefs.key[i]));
                gtk_editable_set_editable (GTK_EDITABLE(entry_move[i]), FALSE);
                g_signal_connect (GTK_OBJECT(button_move[i]),
                                  "clicked",
                                  GTK_SIGNAL_FUNC(cb_button_move_clicked),
                                  (gpointer)i);
                g_signal_connect (GTK_OBJECT(entry_move[i]),
                                  "key_press_event",
                                  GTK_SIGNAL_FUNC(cb_prefs_dialog_key_select),
                                  NULL);
        }
        g_signal_connect (GTK_OBJECT(radio_sound[0]), "toggled", GTK_SIGNAL_FUNC(cb_prefs_dialog_sound_select),(gpointer)SOUND_MODE_BEEP);
        g_signal_connect (GTK_OBJECT(radio_sound[1]), "toggled", GTK_SIGNAL_FUNC(cb_prefs_dialog_sound_select),(gpointer)SOUND_MODE_PLAY);
        g_signal_connect (GTK_OBJECT(checkbutton_animate), "toggled", GTK_SIGNAL_FUNC(cb_prefs_dialog_animate_select), NULL);
        g_signal_connect (GTK_OBJECT(entry_move[KEY_LEFT]), "key_press_event", GTK_SIGNAL_FUNC(cb_prefs_dialog_key_select), NULL);
        g_signal_connect (GTK_OBJECT(entry_move[KEY_RIGHT]), "key_press_event", GTK_SIGNAL_FUNC(cb_prefs_dialog_key_select), NULL);
        g_signal_connect (GTK_OBJECT(entry_move[KEY_DROP]), "key_press_event", GTK_SIGNAL_FUNC(cb_prefs_dialog_key_select), NULL);
        
        gtk_widget_show_all (dlg_prefs);
}



void
prefs_dialog (void)
{
        if (!dlg_prefs) {

                /* build and show it */
                prefs_dialog_create ();
                gtk_window_present (GTK_WINDOW (dlg_prefs));

        }
        else {

                /* unhide */ 
                gtk_window_present (GTK_WINDOW (dlg_prefs));

        }
}
