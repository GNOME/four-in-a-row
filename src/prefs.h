/* -*-mode:c; c-style:k&r; c-basic-offset:4; -*-
 *
 * gnect prefs.h
 *
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
#define START_MODE_RANDOM       3

#define SOUND_MODE_NONE         0
#define SOUND_MODE_BEEP         1
#define SOUND_MODE_PLAY         2

#define KEY_LEFT                0
#define KEY_RIGHT               1
#define KEY_DROP                2



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
	gboolean   do_wipes;
	gboolean   do_toolbar;
	gboolean   do_sound;
	gboolean   do_verify;
	gboolean   changed;
};


void prefs_get(void);
void prefs_save(void);
void prefs_dialog(void);


#endif
