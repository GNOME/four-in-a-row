/* -*-mode:c; c-style:k&r; c-basic-offset:4; -*-
 *
 * gnect sound.h
 *
 */



#ifndef _GNECT_SOUND_H_
#define _GNECT_SOUND_H_


#define SOUND_WIN                          0
#define SOUND_I_WIN                        1
#define SOUND_YOU_WIN                      2
#define SOUND_DRAWN_GAME                   3
#define SOUND_CANT_MOVE                    4
#define SOUND_DROP_COUNTER                 5


void sound_event(gint sound_id);


#endif
