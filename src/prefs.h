/* prefs.h */



#define KEY_DIR "/apps/gnect"
#define KEY_LEVEL_PLAYER1      KEY_DIR "/player1"
#define KEY_LEVEL_PLAYER2      KEY_DIR "/player2"
#define KEY_THEME_ID           KEY_DIR "/theme_id"
#define KEY_MOVE_LEFT          KEY_DIR "/keyleft"
#define KEY_MOVE_RIGHT         KEY_DIR "/keyright"
#define KEY_MOVE_DROP          KEY_DIR "/keydrop"
#define KEY_DO_TOOLBAR         KEY_DIR "/toolbar"
#define KEY_DO_SOUND           KEY_DIR "/sound"
#define KEY_DO_ANIMATE         KEY_DIR "/animate"


typedef struct _Prefs Prefs;
struct _Prefs {
	gboolean do_toolbar;
	gboolean do_sound;
	gboolean do_animate;
	gint     theme_id;
	LevelID  level[2];
	gint     keypress[3];
};


void prefs_init (gint argc, gchar **argv);
void prefsbox_open (void);

