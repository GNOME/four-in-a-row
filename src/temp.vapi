[CCode (cname = "Prefs", cheader_filename="prefs.h")]
struct Prefs {
  bool do_sound;
  int theme_id;
  Level level[2];
  int keypress[3];
}

[CCode (cname = "Theme", cheader_filename="theme.h")]
struct Theme {
    public string title;
    public string fname_tileset;
    public string fname_bground;
    public string grid_color;
    public string player1;
    public string player2;
    public string player1_win;
    public string player2_win;
    public string player1_turn;
    public string player2_turn;
}

[CCode (cname = "AnimID", cprefix = "ANIM_", cheader_filename="main.h")]
public enum AnimID {
    NONE,
    MOVE,
    DROP,
    BLINK,
    HINT
}

[CCode (cname = "PlayerID", cprefix = "", cheader_filename="main.h")]
public enum PlayerID {
    PLAYER1,
  PLAYER2,
  NOBODY
}


[CCode (cname = "LevelID", cprefix = "LEVEL_", cheader_filename="main.h")]
public enum Level {
   HUMAN,
  WEAK,
  MEDIUM,
  STRONG
}


[CCode (cname = "int", cprefix="TILE_", has_type_id = false, cheader_filename="main.h")]
public enum Tile {
    PLAYER1,
    PLAYER2,
    CLEAR,
    CLEAR_CURSOR,
    PLAYER1_CURSOR,
    PLAYER2_CURSOR,
}

[CCode (cname = "MoveID", cprefix = "MOVE_", cheader_filename="main.h")]
public enum Move {
  LEFT,
  RIGHT,
  DROP
}

[CCode (cname = "SoundID", cprefix = "SOUND_", cheader_filename="main.h")]
public enum SoundID{
  DROP,
  I_WIN,
  YOU_WIN,
  PLAYER_WIN,
  DRAWN_GAME,
  COLUMN_FULL
}

void game_reset ();
//void process_move(int c);
void gfx_refresh_pixmaps();
bool gfx_load_pixmaps();
void gfx_paint_tile(Cairo.Context cr, int r, int c);
//void gfx_draw_grid(Cairo.Context c);
//static void gfx_draw_all ();
void gfx_free ();
void scorebox_update ();       /* update visible player descriptions */
void prompt_player ();
void on_dialog_close(int response_id);
bool on_animate();
//static void settings_changed_cb (string key);
void play_sound(SoundID id);

[CCode (cprefix = "", cheader_filename = "config.h")]
namespace Config {
    [CCode (cname = "GETTEXT_PACKAGE")]
    public const string GETTEXT_PACKAGE;
}
//[CCode(cname="GETTEXT_PACKAGE", cheader_filename="config.h,glib/gi18n-lib.h")]
//extern const string GETTEXT_PACKAGE;
