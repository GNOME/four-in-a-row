/* -*- mode:C; indent-tabs-mode:t; tab-width:8; c-basic-offset:8; -*- */

/* theme.c
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

#include <glib/gi18n.h>
#include <gtk/gtk.h>

#include "main.h"
#include "theme.h"
#include "prefs.h"


extern Prefs p;

Theme theme[] = {
  {
   N_("High Contrast"),
   "tileset_50x50_hcontrast.svg",
   NULL,
   "#000000",
   N_("Circle"), N_("Cross"),
   N_("Circle wins!"), N_("Cross wins!"),
   N_("Circle’s turn"), N_("Cross’s turn")
   },
  {
   N_("High Contrast Inverse"),
   "tileset_50x50_hcinverse.svg",
   NULL,
   "#FFFFFF",
   N_("Circle"), N_("Cross"),
   N_("Circle wins!"), N_("Cross wins!"),
   N_("Circle’s turn"), N_("Cross’s turn")
   },
  {
   N_("Red and Green Marbles"),
   "tileset_50x50_faenza-glines-icon1.svg",
   "bg_toplight.png",
   "#727F8C",
   N_("Red"), N_("Green"),
   N_("Red wins!"), N_("Green wins!"),
   N_("Red’s turn"), N_("Green’s turn")
   },
  {
   N_("Blue and Red Marbles"),
   "tileset_50x50_faenza-glines-icon2.svg",
   "bg_toplight.png",
   "#727F8C",
   N_("Blue"), N_("Red"),
   N_("Blue wins!"), N_("Red wins!"),
   N_("Blue’s turn"), N_("Red’s turn")
   },
  {
   N_("Stars and Rings"),
   "tileset_50x50_faenza-gnect-icon.svg",
   "bg_toplight.png",
   "#727F8C",
   N_("Red"), N_("Green"),
   N_("Red wins!"), N_("Green wins!"),
   N_("Red’s turn"), N_("Green’s turn")
   }
};


gint n_themes = G_N_ELEMENTS (theme);


const gchar *
theme_get_player (PlayerID who)
{
  if (who == PLAYER1)
    return theme[p.theme_id].player1;
  return theme[p.theme_id].player2;
}


const gchar *
theme_get_player_win (PlayerID who)
{
  if (who == PLAYER1)
    return theme[p.theme_id].player1_win;
  return theme[p.theme_id].player2_win;
}



const gchar *
theme_get_player_turn (PlayerID who)
{
  if (who == PLAYER1)
    return theme[p.theme_id].player1_turn;
  return theme[p.theme_id].player2_turn;
}

const gchar *
theme_get_title (gint id)
{
  return theme[id].title;
}
