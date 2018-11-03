using Intl;
//using temp;

extern int main2(int argc, char** argv);
extern Gtk.Window window;
extern bool gameover;
extern bool player_active;
extern PlayerID player;
extern PlayerID winner;
extern PlayerID who_starts;
extern int score[3];
extern AnimID anim;
extern char vstr[];
extern char vlevel[];
extern int moves;
extern const int SIZE_VSTR;
const int SPEED_BLINK = 150;
extern int column;
extern int column_moveto;
extern int row;
extern int row_dropto;
extern Gtk.HeaderBar headerbar;

int blink_r1 = 0;
int blink_c1 = 0;
int blink_r2 = 0;
int blink_c2 = 0;
int blink_t = 0;
int blink_n = 0;
bool blink_on = false;
uint timeout = 0;


public int main(string[] argv) {
    setlocale();

    var application = new Gtk.Application("org.gnome.four-in-a-row", 0);

    return main2(argv.length, argv);
}

public void activate() {
    if (!window.is_visible()) {
        window.show_all();
        gfx_refresh_pixmaps();
        Gfx.draw_all ();
        scorebox_update ();       /* update visible player descriptions */
        prompt_player ();
        game_reset ();
    }
}

public int next_move(int c) {
    process_move(c);
    return 0;
}

public void game_process_move(int c) {
    process_move(c);
}

public void game_free() {
    gfx_free();
}

public void game_init ()
{
    //Random.set_seed ((uint) Linux.timegm(null));

    anim = AnimID.NONE;
    gameover = true;
    player_active = false;
    player = PlayerID.PLAYER1;
    winner = PlayerID.NOBODY;
    score[PlayerID.PLAYER1] = 0;
    score[PlayerID.PLAYER2] = 0;
    score[PlayerID.NOBODY] = 0;

    who_starts = PlayerID.PLAYER2;     /* This gets reversed immediately. */

    clear_board ();
}

void clear_board () {
  int r, c, i;

  for (r = 0; r < 7; r++) {
    for (c = 0; c < 7; c++) {
      gboard[r, c] = Tile.CLEAR;
    }
  }

  for (i = 0; i < SIZE_VSTR; i++)
    vstr[i] = '\0';

  vstr[0] = vlevel[Level.WEAK];
  vstr[1] = '0';
  moves = 0;
}

static int first_empty_row (int c) {
  int r = 1;

  while (r < 7 && gboard[r, c] == Tile.CLEAR)
    r++;
  return r - 1;
}

static int get_n_human_players () {
  if (p.level[PlayerID.PLAYER1] != Level.HUMAN && p.level[PlayerID.PLAYER2] != Level.HUMAN)
    return 0;
  if (p.level[PlayerID.PLAYER1] != Level.HUMAN || p.level[PlayerID.PLAYER2] != Level.HUMAN)
    return 1;
  return 2;
}

static bool is_player_human ()
{
  return player == PLAYER1 ? p.level[PlayerID.PLAYER1] == Level.HUMAN
                           : p.level[PlayerID.PLAYER2] == Level.HUMAN;
}

static void drop_marble (int r, int c)
{
  int tile;
  tile = player == PlayerID.PLAYER1 ? Tile.PLAYER1 : Tile.PLAYER2;

  gboard[r, c] = tile;
  Gfx.draw_tile (r, c);

  column = column_moveto = c;
  row = row_dropto = r;
}

static void drop () {
  int tile;
  tile = player == PLAYER1 ? Tile.PLAYER1 : Tile.PLAYER2;

  gboard[row, column] = Tile.CLEAR;
  Gfx.draw_tile (row, column);

  row++;
  gboard[row, column] = tile;
  Gfx.draw_tile (row, column);
}

static void move (int c) {
  gboard[0, column] = Tile.CLEAR;
  Gfx.draw_tile (0, column);

  column = c;
  gboard[0, c] = player == PlayerID.PLAYER1 ? Tile.PLAYER1 : Tile.PLAYER2;

  Gfx.draw_tile (0, c);
}

static void move_cursor (int c)
{
  move (c);
  column = column_moveto = c;
  row = row_dropto = 0;
}

void swap_player ()
{
  player = (player == PlayerID.PLAYER1) ? PlayerID.PLAYER2 : PlayerID.PLAYER1;
  move_cursor (3);
  prompt_player ();
}


void set_status_message (string message)
{
    headerbar.set_title(message);
}

static void blink_tile (int r, int c, int t, int n) {
  if (timeout != 0)
    return;
  blink_r1 = r;
  blink_c1 = c;
  blink_r2 = r;
  blink_c2 = c;
  blink_t = t;
  blink_n = n;
  blink_on = false;
  anim = AnimID.BLINK;
  timeout = Timeout.add (SPEED_BLINK, on_animate);
}
