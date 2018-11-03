[CCode (cname = "Prefs", cheader_filename="prefs.h")]
struct Prefs {
  bool do_sound;
  int theme_id;
  Level level[2];
  int keypress[3];
}

[CCode (cname = "Theme", cheader_filename="theme.h")]
struct Theme {
    const string title;
    const string fname_tileset;
    const string fname_bground;
    public string grid_color;
    const string player1;
    const string player2;
    const string player1_win;
    const string player2_win;
    const string player1_turn;
    const string player2_turn;
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

void game_reset ();
void process_move(int c);
void gfx_refresh_pixmaps();
bool gfx_load_pixmaps();
void gfx_paint_tile(Cairo.Context cr, int r, int c);
//void gfx_draw_grid(Cairo.Context c);
//static void gfx_draw_all ();
void gfx_free ();
void scorebox_update ();       /* update visible player descriptions */
void prompt_player ();
void scorebox_reset ();
string theme_get_title(int i);
void on_dialog_close(int response_id);
bool on_animate();
//static void settings_changed_cb (string key);

[CCode (cprefix = "", lower_case_prefix = "", cheader_filename = "config.h")]
namespace Config {
    [CCode (cname = "GETTEXT_PACKAGE")]
    public const string GETTEXT_PACKAGE;
}
//[CCode(cname="GETTEXT_PACKAGE", cheader_filename="config.h,glib/gi18n-lib.h")]
//extern const string GETTEXT_PACKAGE;
