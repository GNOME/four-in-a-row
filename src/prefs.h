/* prefs.h */

typedef struct _Prefs Prefs;
struct _Prefs {
  gboolean do_sound;
  gboolean do_animate;
  gint theme_id;
  LevelID level[2];
  gint keypress[3];
};


void prefs_init (void);
void prefsbox_open (void);
