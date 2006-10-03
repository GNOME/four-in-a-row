/* server.h - Network game server for gnect.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

#include "ggzdmod.h"

#define GGZSPECTATORS
#define GGZSTATISTICS

/* GGZdMod callbacks */
void game_handle_ggz_state (GGZdMod * ggz,
			    GGZdModEvent event, const void *data);
void game_handle_ggz_seat (GGZdMod * ggz, GGZdModEvent event,
			   const void *data);
//static void game_handle_ggz_leave(GGZdMod *ggz, GGZdModEvent event, const void *data);
#ifdef GGZSPECTATORS
void game_handle_ggz_spectator_join (GGZdMod * ggz,
				     GGZdModEvent event, const void *data);
void game_handle_ggz_spectator_leave (GGZdMod * ggz,
				      GGZdModEvent event, const void *data);
void game_handle_ggz_spectator (GGZdMod * ggz,
				GGZdModEvent event, const void *data);
#endif
void game_handle_ggz_player (GGZdMod * ggz, GGZdModEvent event,
			     const void *data);


/* ConnectX game events */
#define CONNECTX_EVENT_LAUNCH      0
#define CONNECTX_EVENT_JOIN        1
#define CONNECTX_EVENT_LEAVE       2
#define CONNECTX_EVENT_OPTIONS     3
#define CONNECTX_EVENT_MOVE	       4

#define	dtEmpty    1
#define	dtPlayer1  2
#define	dtPlayer2  3

/* board sizes */
#define MAX_BOARDWIDTH		20
#define MAX_BOARDHEIGHT		15
#define MIN_BOARDWIDTH		4
#define MIN_BOARDHEIGHT		4
#define MAX_CONNECTLENGTH	6
#define MIN_CONNECTLENGTH	3


void game_init (GGZdMod * ggz);
