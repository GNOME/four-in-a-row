/*
 * gnect gui.c
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

#include "config.h" /* for NLS, config.h before gnome-i18n.h */

#include <gconf/gconf-client.h>
#include <gnome.h>

#include "main.h"
#include "gnect.h"
#include "gui.h"
#include "dialog.h"
#include "gfx.h"
#include "prefs.h"
#include "sound.h"


extern gint      debugging;
extern Gnect     gnect;
extern Prefs     prefs;
extern Theme     *theme_current;
extern GdkPixmap *pixmap_display;
extern gint      tile_width;
extern Anim      anim;
extern GConfClient *gnect_gconf_client;

GtkWidget *app;
GtkWidget *draw_area;

static GtkWidget *app_bar;



static void cb_gui_quit (GtkWidget *widget, gpointer data);
static void cb_gui_game_new (GtkWidget *widget, gpointer data);
static void cb_gui_game_undo (GtkWidget *widget, gpointer data);
static void cb_gui_game_hint (GtkWidget *widget, gpointer data);
static void cb_gui_game_scores (GtkWidget *widget, gpointer data);
static void cb_gui_settings_toolbar (GtkWidget *widget, gpointer data);
static void cb_gui_settings_sound (GtkWidget *widget, gpointer data);
static void cb_gui_settings_grid (GtkWidget *widget, gpointer data);
static void cb_gui_settings_prefs (GtkWidget *widget, gpointer data);
static void cb_gui_help_about (GtkWidget *widget, gpointer data);




/* ========== menus ========== */
GnomeUIInfo game_menu[] = {
        GNOMEUIINFO_MENU_NEW_GAME_ITEM (cb_gui_game_new, NULL),
        GNOMEUIINFO_SEPARATOR,
        GNOMEUIINFO_MENU_UNDO_MOVE_ITEM (cb_gui_game_undo, NULL),
        GNOMEUIINFO_MENU_HINT_ITEM (cb_gui_game_hint, NULL),
        GNOMEUIINFO_SEPARATOR,
        GNOMEUIINFO_MENU_SCORES_ITEM (cb_gui_game_scores, NULL),
        GNOMEUIINFO_MENU_QUIT_ITEM (cb_gui_quit, NULL),
        GNOMEUIINFO_END
};
GnomeUIInfo settings_menu[] = {
        GNOMEUIINFO_TOGGLEITEM_DATA (N_("_Toolbar"), N_("Show or hide the toolbar"), cb_gui_settings_toolbar, NULL, NULL),
        GNOMEUIINFO_TOGGLEITEM_DATA (N_("Enable _sound"), N_("Enable or disable sound"), cb_gui_settings_sound, NULL, NULL),
        GNOMEUIINFO_TOGGLEITEM_DATA (N_("Draw _grid"), N_("Show or hide the grid"), cb_gui_settings_grid, NULL, NULL),
        GNOMEUIINFO_SEPARATOR,
        GNOMEUIINFO_MENU_PREFERENCES_ITEM (cb_gui_settings_prefs, NULL),
        GNOMEUIINFO_END
};
GnomeUIInfo help_menu[] = {
        GNOMEUIINFO_HELP (APPNAME),
        GNOMEUIINFO_MENU_ABOUT_ITEM (cb_gui_help_about, NULL),
        GNOMEUIINFO_END
};
GnomeUIInfo menu_bar[] = {
        GNOMEUIINFO_MENU_GAME_TREE (game_menu),
        GNOMEUIINFO_SUBTREE ("_Settings", settings_menu),
        GNOMEUIINFO_SUBTREE ("_Help", help_menu),
        GNOMEUIINFO_END
};



/* ========== toolbar ========== */
GnomeUIInfo toolbar[] = {
        GNOMEUIINFO_ITEM_STOCK (N_("New"), N_("Start a new game"), cb_gui_game_new, GTK_STOCK_NEW),
        GNOMEUIINFO_ITEM_STOCK (N_("Undo"), N_("Undo the last move"), cb_gui_game_undo, GTK_STOCK_UNDO),
        GNOMEUIINFO_ITEM_STOCK (N_("Hint"), N_("Get a hint for your next move"), cb_gui_game_hint, GTK_STOCK_HELP),
        GNOMEUIINFO_END
};



/* menu item IDs used in toggling and sensitivity changes */

#define ID_MENU_GAME_NEW          0
#define ID_MENU_GAME_UNDO         2
#define ID_MENU_GAME_HINT         3

#define ID_MENU_SETTINGS_TOOLBAR  0
#define ID_MENU_SETTINGS_SOUND    1
#define ID_MENU_SETTINGS_GRID     2

#define ID_TOOLBAR_NEW            0
#define ID_TOOLBAR_UNDO           1
#define ID_TOOLBAR_HINT           2


static void
cb_gui_quit (GtkWidget *widget, gpointer data)
{
  gtk_main_quit ();
}


#if 0
static void
cb_gui_game_new_test (GtkWidget *widget, gint response_id, gpointer data)
{
        if (response_id == GTK_RESPONSE_YES) {
                gnect_reset (TRUE);
        }
        gtk_widget_destroy (widget);
}
#endif


static void
cb_gui_game_new (GtkWidget *widget, gpointer data)
{
        gfx_wipe_board ();
        gnect_reset (TRUE);
}



static void
cb_gui_game_undo (GtkWidget *widget, gpointer data)
{
        if (anim.id) return;

        if (gnect.over || !gnect_is_player_computer (gnect.current_player)) {
                gui_set_undo_sensitive (gnect_undo_move (FALSE));
                gui_set_hint_sensitive (TRUE);
        }
}



static void
cb_gui_game_hint (GtkWidget *widget, gpointer data)
{
        if (anim.id) return;
        gnect_hint ();
}



static void
cb_gui_game_scores (GtkWidget *widget, gpointer data)
{
        dialog_score ();
}



static void
cb_gui_settings_toolbar (GtkWidget *widget, gpointer data)
{
        BonoboDockItem *toolbar_gdi;


        toolbar_gdi = gnome_app_get_dock_item_by_name (GNOME_APP (app), GNOME_APP_TOOLBAR_NAME);
        /* prefs.do_toolbar = (GTK_CHECK_MENU_ITEM (settings_menu[0].widget))->active; */

        prefs.do_toolbar = GTK_CHECK_MENU_ITEM (widget)->active;
        if (prefs.do_toolbar) {
                gtk_widget_show (GTK_WIDGET (toolbar_gdi));
        }
        else {
                gtk_widget_hide (GTK_WIDGET (toolbar_gdi));
                gtk_widget_queue_resize (app);
        }
        gconf_client_set_bool (gnect_gconf_client, "/apps/gnect/toolbar", prefs.do_toolbar, NULL);
}



static void
cb_gui_gconf_toolbar (GConfClient *client, guint cnxn_id, GConfEntry *entry, gpointer user_data)
{
        BonoboDockItem *toolbar_gdi;


        toolbar_gdi = gnome_app_get_dock_item_by_name (GNOME_APP(app), GNOME_APP_TOOLBAR_NAME);
        prefs.do_toolbar = gconf_client_get_bool (gnect_gconf_client, "/apps/gnect/toolbar", NULL);
        gtk_check_menu_item_set_active (GTK_CHECK_MENU_ITEM(settings_menu[ID_MENU_SETTINGS_TOOLBAR].widget),
                                        prefs.do_toolbar);
        if (prefs.do_toolbar) {
                gtk_widget_show (GTK_WIDGET(toolbar_gdi));
        }
        else {
                gtk_widget_hide (GTK_WIDGET(toolbar_gdi));
                gtk_widget_queue_resize (app);
        }
}



static void
cb_gui_settings_sound (GtkWidget *widget, gpointer data)
{
        prefs.do_sound = GTK_CHECK_MENU_ITEM (widget)->active;
        gconf_client_set_bool (gnect_gconf_client, "/apps/gnect/sound", prefs.do_sound, NULL);
}



static void
cb_gui_gconf_sound (GConfClient *client, guint cnxn_id, GConfEntry *entry, gpointer user_data)
{
        BonoboDockItem *toolbar_gdi;


        toolbar_gdi = gnome_app_get_dock_item_by_name (GNOME_APP (app), GNOME_APP_TOOLBAR_NAME);
        prefs.do_sound = gconf_client_get_bool (gnect_gconf_client, "/apps/gnect/sound", NULL);
        gtk_check_menu_item_set_active (GTK_CHECK_MENU_ITEM (settings_menu[ID_MENU_SETTINGS_SOUND].widget),
                                        prefs.do_sound);
}



static void
cb_gui_settings_grid (GtkWidget *widget, gpointer data)
{
        prefs.do_grids = GTK_CHECK_MENU_ITEM (widget)->active;
        gfx_toggle_grid (theme_current, prefs.do_grids);
        gconf_client_set_bool (gnect_gconf_client, "/apps/gnect/grid", prefs.do_grids, NULL);
}




static void
cb_gui_gconf_grid (GConfClient *client, guint cnxn_id, GConfEntry *entry, gpointer user_data)
{
        BonoboDockItem *toolbar_gdi;


        toolbar_gdi = gnome_app_get_dock_item_by_name (GNOME_APP (app), GNOME_APP_TOOLBAR_NAME);
        prefs.do_grids = gconf_client_get_bool (gnect_gconf_client, "/apps/gnect/grid", NULL);
        gtk_check_menu_item_set_active (GTK_CHECK_MENU_ITEM (settings_menu[ID_MENU_SETTINGS_GRID].widget),
                                        prefs.do_grids);
}



static void
cb_gui_settings_prefs (GtkWidget *widget, gpointer data)
{
        prefs_dialog ();
}



static void
cb_gui_help_about (GtkWidget *widget, gpointer data)
{
        dialog_about ();
}



static gint
gui_get_mouse_col (gint x)
{
        /*
         * Return game column relative to pixel x on draw_area
         */

        gint col;

        col = x / tile_width;
        if (col > N_COLS - 1) col--;
        return col;
}



static gint
cb_gui_key_press (GtkWidget *widget, GdkEventKey* event, gpointer data)
{

        /* ignore if computer's busy */
        if (anim.id || gnect_is_player_computer (gnect.current_player)) {
                return FALSE;
        }

        /* ignore if not an assigned key */
        if (event->keyval != prefs.key[KEY_LEFT] &&
                event->keyval != prefs.key[KEY_RIGHT] &&
                event->keyval != prefs.key[KEY_DROP]) {
                return FALSE;
        }

        /* complain if no game in progress */
        if (gnect.over) {
                sound_event (SOUND_CANT_MOVE);
                if (gnect.winner != -1 && gnect.winner != DRAWN_GAME) {
                        gfx_blink_winner (1);
                }
                gui_set_status_prompt_new_game (STATUS_MSG_FLASH);
                return TRUE;
        }

        /* okay */
        if (event->keyval == prefs.key[KEY_LEFT] && gnect.cursor_col) {
                gfx_move_cursor (gnect.cursor_col - 1);
        }
        else if (event->keyval == prefs.key[KEY_RIGHT] && gnect.cursor_col < N_COLS - 1) {
                gfx_move_cursor (gnect.cursor_col + 1);
        }
        else if (event->keyval == prefs.key[KEY_DROP]) {
                gnect_process_move (gnect.cursor_col);
        }
        return TRUE;
}



static void
cb_gui_draw_area_event (GtkWidget *widget, GdkEvent *event)
{
        GdkEventExpose *expose;
        gint x, y;


        switch (event->type) {

        case GDK_EXPOSE :
                expose = (GdkEventExpose *)event;
                gfx_expose (&expose->area);
                break;

        case GDK_BUTTON_PRESS :

                if (anim.id) return;

                if (gnect.over) {

                        sound_event (SOUND_CANT_MOVE);
                        if (gnect.winner != -1 && gnect.winner != DRAWN_GAME) {
                                gfx_blink_winner (1);
                        }
                        gui_set_status_prompt_new_game (STATUS_MSG_FLASH);

                }
                else if (gnect_is_player_human (gnect.current_player)) {

                        gtk_widget_get_pointer (widget, &x, &y);
                        gnect_process_move (gui_get_mouse_col (x));

                }
                break;

        default:
                break;

        }

}



void
gui_set_tooltip (GtkWidget *widget, const gchar *tip_str)
{
        GtkTooltips *t = gtk_tooltips_new ();
        gtk_tooltips_set_tip (t, widget, tip_str, NULL);
}



void
gui_set_status (const gchar *msg_str, gint mode)
{
        switch (mode) {
        case STATUS_MSG_SET :
                gnome_appbar_pop (GNOME_APPBAR (app_bar));
                gnome_appbar_push (GNOME_APPBAR (app_bar), msg_str);
                break;
        case STATUS_MSG_FLASH :
                gnome_app_flash (GNOME_APP (app), msg_str);
                break;
        case STATUS_MSG_CLEAR :
        default :
                gnome_appbar_clear_stack (GNOME_APPBAR (app_bar));
                gnome_appbar_refresh (GNOME_APPBAR (app_bar));
                break;
        }
}



void
gui_set_status_winner (gint winner, gboolean with_sound)
{
        /*
         * Update status bar message according to who's won.
         */

        if (winner == DRAWN_GAME) {

                gui_set_status (_("It's a draw!"), STATUS_MSG_SET);
                if (with_sound) sound_event (SOUND_DRAWN_GAME);

        }
        else {

                if (gnect_get_n_players () == 1) {

                        /* Human vs computer: "You win" or "I win" */

                        if (gnect_is_player_human (winner)) {
                        gui_set_status (_("You win!"), STATUS_MSG_SET);
                                if (with_sound) sound_event (SOUND_YOU_WIN);
                        }
                        else {
                                gui_set_status (_("I win!"), STATUS_MSG_SET);
                                if (with_sound) sound_event (SOUND_I_WIN);
                        }

                }
                else {

                        /* Use winning player's tile description */

                        gchar *str1, *str2;

                        str1 = g_strdup_printf (_("%s wins!"), prefs.descr_player1);
                        str2 = g_strdup_printf (_("%s wins!"), prefs.descr_player2);

                        if (gnect.current_player == PLAYER_1) {
                                gui_set_status (str1, STATUS_MSG_SET);
                        }
                        else {
                                gui_set_status (str2, STATUS_MSG_SET);
                        }

                        g_free (str2);
                        g_free (str1);

                        if (with_sound) sound_event (SOUND_WIN);

                }
        }
}



void
gui_set_status_prompt (gint player)
{
        gchar *prompt_str, *who_str;


        switch (gnect_get_n_players ()) {

        case 1 :
                gui_set_status (_("Your move..."), STATUS_MSG_SET);
                break;

        case 2 :
                if (player == PLAYER_1) {
                        who_str = prefs.descr_player1;
                }
                else {
                        who_str = prefs.descr_player2;
                }
                prompt_str = g_strdup_printf ("%s...", who_str);
                gui_set_status (prompt_str, STATUS_MSG_SET);
                g_free (prompt_str);
                break;

        default:
                break;
        }
}



void
gui_set_status_prompt_new_game (gint mode)
{
        gui_set_status (_("Select \"New game\" from the \"Game\" menu to begin."), mode);
}



void
gui_set_new_sensitive (gboolean sensitive)
{
        gtk_widget_set_sensitive (game_menu[ID_MENU_GAME_NEW].widget, sensitive);
        gtk_widget_set_sensitive (toolbar[ID_TOOLBAR_NEW].widget, sensitive);
}



void
gui_set_hint_sensitive (gboolean sensitive)
{
        gtk_widget_set_sensitive (game_menu[ID_MENU_GAME_HINT].widget, sensitive);
        gtk_widget_set_sensitive (toolbar[ID_TOOLBAR_HINT].widget, sensitive);
}



void
gui_set_undo_sensitive (gboolean sensitive)
{
        gtk_widget_set_sensitive (game_menu[ID_MENU_GAME_UNDO].widget, sensitive);
        gtk_widget_set_sensitive (toolbar[ID_TOOLBAR_UNDO].widget, sensitive);
}



void
gui_update_hint_sensitivity (void)
{
        gui_set_hint_sensitive (!gnect.over && gnect_get_n_players ());
}



void
gui_update_undo_sensitivity (void)
{
        gui_set_undo_sensitive (gnect.veleng_str[2] != '\0' && gnect_get_n_players ());
}



void
gui_create (void)
{
        GtkWidget *vbox, *hbox;


        DEBUG_PRINT (1, "gui_create\n");

        app = gnome_app_new (APPNAME, "Four-in-a-row");
        gtk_window_set_resizable (GTK_WINDOW (app), FALSE);
        gtk_window_set_wmclass (GTK_WINDOW (app), APPNAME, "main");

        g_signal_connect (G_OBJECT (app), "delete_event",
                          G_CALLBACK (cb_gui_quit), NULL);

        gnome_window_icon_set_default_from_file (FNAME_GNECT_ICON);
        gnome_window_icon_set_from_default (GTK_WINDOW(app));

        app_bar = gnome_appbar_new (FALSE, TRUE, GNOME_PREFERENCES_USER);
        gnome_app_set_statusbar (GNOME_APP(app), GTK_WIDGET(app_bar));

        gnome_app_create_menus (GNOME_APP(app), menu_bar);
        gnome_app_install_menu_hints (GNOME_APP(app), menu_bar);

        gnome_app_create_toolbar (GNOME_APP(app), toolbar);

        GTK_CHECK_MENU_ITEM(settings_menu[ID_MENU_SETTINGS_TOOLBAR].widget)->active = prefs.do_toolbar;
        GTK_CHECK_MENU_ITEM(settings_menu[ID_MENU_SETTINGS_SOUND].widget)->active = prefs.do_sound;
        GTK_CHECK_MENU_ITEM(settings_menu[ID_MENU_SETTINGS_GRID].widget)->active = prefs.do_grids;

        gui_set_hint_sensitive (FALSE);
        gui_set_undo_sensitive (FALSE);

        vbox = gtk_vbox_new (FALSE, 5);
        gnome_app_set_contents (GNOME_APP(app), vbox);

        hbox = gtk_hbox_new (FALSE, 0);
        gtk_box_pack_start (GTK_BOX(vbox), hbox, TRUE, FALSE, 0);
        gtk_widget_show (hbox);

        draw_area = gtk_drawing_area_new ();
        gtk_widget_set_size_request (GTK_WIDGET (draw_area), 0, 0);
        gtk_box_pack_start (GTK_BOX (hbox), draw_area, FALSE, FALSE, 0);
        gtk_widget_set_events (draw_area, GDK_EXPOSURE_MASK | GDK_BUTTON_PRESS_MASK);

        gtk_widget_realize (draw_area);
}



void
gui_open (const gchar *geom_str)
{
        BonoboDockItem  *toolbar_gdi;


        DEBUG_PRINT(1, "gui_open\n");

        g_signal_connect (G_OBJECT (draw_area), "event",
                          G_CALLBACK (cb_gui_draw_area_event), NULL);
        g_signal_connect (G_OBJECT (app), "key_press_event",
                          G_CALLBACK (cb_gui_key_press), NULL);

        if (geom_str) gtk_window_parse_geometry (GTK_WINDOW(app), geom_str);

        gconf_client_notify_add (gnect_gconf_client, "/apps/gnect/toolbar",
                                 cb_gui_gconf_toolbar, NULL, NULL, NULL);
        gconf_client_notify_add (gnect_gconf_client, "/apps/gnect/sound",
                                 cb_gui_gconf_sound, NULL, NULL, NULL);
        gconf_client_notify_add (gnect_gconf_client, "/apps/gnect/grid",
                                 cb_gui_gconf_grid, NULL, NULL, NULL);

        gtk_widget_show_all (app);


        if (!prefs.do_toolbar) {
                toolbar_gdi = gnome_app_get_dock_item_by_name (GNOME_APP(app),
                                                               GNOME_APP_TOOLBAR_NAME);
                gtk_widget_hide (GTK_WIDGET (toolbar_gdi));
        }

        gfx_redraw (TRUE);

        gui_set_status_prompt_new_game (STATUS_MSG_SET);
        gui_set_status (_("Welcome to Gnect!"), STATUS_MSG_FLASH);
}

