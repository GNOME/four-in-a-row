/* prefs.h */
#ifndef PREFS_H
#define PREFS_H
#include <main.h>

typedef struct _Prefs Prefs;
struct _Prefs {
  gboolean do_sound;
  gint theme_id;
  LevelID level[2];
  gint keypress[3];
};


void prefs_init (void);
void prefsbox_open (void);
#endif
