/*
 * gnect prefs.h
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

#ifndef _GNECT_PREFS_H_
#define _GNECT_PREFS_H_


#define PLAYER_HUMAN            0
#define PLAYER_GNECT            1
#define PLAYER_VELENA_WEAK      2
#define PLAYER_VELENA_MEDIUM    3
#define PLAYER_VELENA_STRONG    4

#define START_MODE_PLAYER_1     0
#define START_MODE_PLAYER_2     1
#define START_MODE_ALTERNATE    2

#define SOUND_MODE_NONE         0
#define SOUND_MODE_BEEP         1
#define SOUND_MODE_PLAY         2

typedef enum {
        KEY_LEFT = 0,
        KEY_RIGHT,
        KEY_DROP
} KeyID;



typedef struct _Prefs Prefs;

struct _Prefs {
	gint       player1;
	gint       player2;
	gint       start_mode;
	gint       sound_mode;
	gint       key[3];         /* KEY_LEFT, KEY_RIGHT, KEY_DROP */
	gchar      *fname_theme;
	gchar      *descr_player1; /* don't free; ptr to gnect.current_theme->descr_player1 */
	gchar      *descr_player2; /* ditto player2 */
	gboolean   do_grids;
	gboolean   do_animate;
	gboolean   do_toolbar;
	gboolean   do_sound;
	gboolean   changed;
};


void prefs_init (gint argc, gchar **argv);
void prefs_free (void);
void prefs_get (void);
void prefs_save (void);
void prefs_dialog (void);


#endif
