/* ggz-network.c
 *
 * Four-in-a-row for GNOME
 * Based on ConnectX protocol for GGZ.
 * 
 * (C) 2006
 * Authors:	Josef Spillner <josef@ggzgamingzone.org> 		
 *		Andreas Røsdal <andrearo@stud.ntnu.no>
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
#include <pwd.h>

#include <ggzmod.h>
#include <ggz-embed.h>
#include <ggz-gtk.h>

#include <games-dlg-chat.h>
#include <games-dlg-players.h>

#include "connectx_client.h"
#include "connect4.h"
#include "ggz-network.h"
#include "main.h"


static gboolean
handle_ggzmod (GIOChannel * channel, GIOCondition cond, gpointer data)
{
  GGZMod *mod;
  int ret;

  mod = data;
  ret = ggzmod_dispatch (mod);
  return (ret >= 0);
}


static gboolean
handle_game_server (GIOChannel * channel, GIOCondition cond, gpointer data)
{
  GGZMod *mod;
  int gamefd;

  mod = data;

  if (ggzmod_get_state (mod) != GGZMOD_STATE_DONE) {
    gamefd = ggzmod_get_server_fd (mod);
    ggzcomm_set_fd (gamefd);
    ggzcomm_network_main ();
    return TRUE;
  } else {
    /* The game is over. */
    return FALSE;
  }
}



static void
handle_ggzmod_server (GGZMod * mod, GGZModEvent e, const void *data)
{
  GIOChannel *channel;
  int gamefd;

  gamefd = ggzmod_get_server_fd (mod);
  ggzmod_set_state (mod, GGZMOD_STATE_PLAYING);
  channel = g_io_channel_unix_new (gamefd);
  g_io_add_watch (channel, G_IO_IN, handle_game_server, mod);
}

static gboolean
on_game_exit (GObject * object, gpointer data)
{
  gtk_main_quit ();
  return TRUE;
}

static void
network_error_cb (void)
{
  /* make game exit, but inform user before */

  static GtkWidget *dialog;

  if (!ggz_network_mode) {
    return;
  }

  ggz_network_mode = FALSE;


  dialog = gtk_message_dialog_new (GTK_WINDOW (app),
				   0,
				   GTK_MESSAGE_ERROR,
				   GTK_BUTTONS_OK,
				   _("A network error has occurred."));
  g_signal_connect (dialog, "response", G_CALLBACK (on_game_exit), NULL);
  /* FIXME:  Invoke bug-buddy...    */
  gtk_window_present (GTK_WINDOW (dialog));
}

static void
network_message_cb (int opcode)
{
  /* message and associated data arrived safely */

  switch (opcode) {
  case msgseat:
    if (variables.num == 0) {
      set_status_message (_("Waiting for an opponent to join the game."));
    } else {
      prompt_player ();
    }

    break;
  case msgplayers:
    /* Not implemented. */
    break;
  case reqmove:
    player_active = TRUE;
    prompt_player ();
    break;
  case rspmove:
    if (!variables.status) {
      process_move (variables.column);
      player_active = FALSE;
    }

    break;
  case msgmove:
    process_move (variables.column2);
    break;
  case sndsync:
    /* Not implemented yet. */
    break;
  case msggameover:
    player_active = FALSE;
    break;
  case reqoptions:
    variables.boardheight2 = BOARDY;
    variables.boardwidth2 = BOARDX;
    variables.connectlength2 = TILES;
    ggzcomm_sndoptions ();
    break;
  case msgoptions:
    /* Not supported yet. */
    break;

  default:
    printf ("Unknown opcode.\n");
    break;
  }

}


void
network_init (void)
{
  GGZMod *mod;
  GIOChannel *channel;
  int ret, ggzmodfd;

  if (!ggzmod_is_ggz_mode ())
    return;

  mod = ggzmod_new (GGZMOD_GAME);
  ggzmod_set_handler (mod, GGZMOD_EVENT_SERVER, handle_ggzmod_server);

  ret = ggzmod_connect (mod);
  if (ret != 0) {
    /* Error: GGZ core client error (e.g. faked GGZMODE env variable) */
    return;
  }

  ggzmodfd = ggzmod_get_fd (mod);
  channel = g_io_channel_unix_new (ggzmodfd);
  g_io_add_watch (channel, G_IO_IN, handle_ggzmod, mod);

  ggzcomm_set_notifier_callback (network_message_cb);
  ggzcomm_set_error_callback (network_error_cb);

  init_chat (mod);
  init_player_list (mod);

  ggz_network_mode = TRUE;

}


/*  Send column number to server. */
void
network_send_move (int column)
{
  variables.column3 = column;
  ggzcomm_sndmove ();
}



/****************************************************************************
  Callback function that's called by the library when a connection is
  established (or lost) to the GGZ server.  The server parameter gives
  the server (or NULL).
****************************************************************************/
static void
ggz_connected (GGZServer * server)
{
  /* Nothing useful to do... */
}

/****************************************************************************
  Callback function that's called by the library when we launch a game.  This
  means we now have a connection to a gnect server so handling can be given
  back to the regular gnect code.
****************************************************************************/
static void
ggz_game_launched (void)
{
  gchar *str = NULL;

  network_init ();
  game_reset ();
  gtk_notebook_set_current_page (GTK_NOTEBOOK (notebook), MAIN_PAGE);

  str = g_strdup_printf (_("Welcome to a network game of %s."),
			 NETWORK_ENGINE);
  add_chat_text (str);
  g_free (str);

}

/****************************************************************************
  Callback function that's invoked when GGZ is exited.
****************************************************************************/
static void
ggz_closed (void)
{
  gtk_notebook_set_current_page (GTK_NOTEBOOK (notebook), MAIN_PAGE);
  ggz_network_mode = FALSE;
  game_reset ();
  prompt_player ();
}

void
on_network_game (void)
{
  GtkWidget *ggzbox;
  struct passwd *pwent;  

  if (ggz_network_mode) {
    gtk_notebook_set_current_page (GTK_NOTEBOOK (notebook), NETWORK_PAGE);
    return;
  }

  game_reset ();
  ggz_network_mode = TRUE;
  prompt_player ();

  ggz_gtk_initialize (FALSE,
		      ggz_connected, ggz_game_launched, ggz_closed,
		      NETWORK_ENGINE, NETWORK_VERSION, "gnect.xml",
		      "GGZ Gaming Zone");

  pwent = getpwuid(getuid());
  ggz_embed_ensure_server ("GGZ Gaming Zone", "gnome.ggzgamingzone.org",
			   5688, pwent->pw_name);

  ggzbox = ggz_gtk_create_main_area (app);
  gtk_notebook_append_page (GTK_NOTEBOOK (notebook), ggzbox, NULL);
  gtk_notebook_set_current_page (GTK_NOTEBOOK (notebook), NETWORK_PAGE);
}
