/*
 * gnect sound.c
 *
 */



#include "config.h"
#include "main.h"
#include "sound.h"
#include "prefs.h"


/* event names used in gnect.soundlist */
#define SOUND_STR_WIN                         "playerwin"
#define SOUND_STR_I_WIN                       "iwin"
#define SOUND_STR_YOU_WIN                     "youwin"
#define SOUND_STR_DRAWN_GAME                  "draw"
#define SOUND_STR_CANT_MOVE                   "cantmove"
#define SOUND_STR_DROP_COUNTER                "drop"



extern Prefs prefs;



void
sound_event (gint sound_id)
{
	/*
	 * If sound isn't toggled off, make a noise according
	 * to sound_mode and sound_id
	 */


	if (prefs.do_sound) {

		switch (sound_id) {

		case SOUND_WIN :
			if (prefs.sound_mode == SOUND_MODE_BEEP) {
				gdk_beep ();
			}
			else if (prefs.sound_mode == SOUND_MODE_PLAY) {
				gnome_triggers_do (NULL, NULL, APPNAME, SOUND_STR_WIN, NULL);
			}
			break;

		case SOUND_I_WIN :
			if (prefs.sound_mode == SOUND_MODE_BEEP) {
				gdk_beep ();
			}
			else if (prefs.sound_mode == SOUND_MODE_PLAY) {
				gnome_triggers_do (NULL, NULL, APPNAME, SOUND_STR_I_WIN, NULL);
			}
			break;

		case SOUND_YOU_WIN :
			if (prefs.sound_mode == SOUND_MODE_BEEP) {
				gdk_beep ();
			}
			else if (prefs.sound_mode == SOUND_MODE_PLAY) {
				gnome_triggers_do (NULL, NULL, APPNAME, SOUND_STR_YOU_WIN, NULL);
			}
			break;

		case SOUND_DRAWN_GAME :
			if (prefs.sound_mode == SOUND_MODE_BEEP) {
				gdk_beep ();
			}
			else if (prefs.sound_mode == SOUND_MODE_PLAY) {
				gnome_triggers_do (NULL, NULL, APPNAME, SOUND_STR_DRAWN_GAME, NULL);
			}
			break;

		case SOUND_CANT_MOVE :
			if (prefs.sound_mode == SOUND_MODE_BEEP) {
				gdk_beep ();
			}
			else if (prefs.sound_mode == SOUND_MODE_PLAY) {
				gnome_triggers_do (NULL, NULL, APPNAME, SOUND_STR_CANT_MOVE, NULL);
			}
			break;

		case SOUND_DROP_COUNTER :
			if (prefs.sound_mode == SOUND_MODE_PLAY) {
				gnome_triggers_do (NULL, NULL, APPNAME, SOUND_STR_DROP_COUNTER, NULL);
			}
			break;

		default:
			break;

		}

	}

}
