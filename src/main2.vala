using Intl;
using Gtk;
//using temp;

const string jfasolfdas = Config.GETTEXT_PACKAGE;
extern int main2(int argc, char** argv);
extern Gtk.Window window;
extern Gtk.Dialog? scorebox;
extern Label label_name[3];
extern Label label_score[3];
bool gameover;
bool player_active;
PlayerID player;
PlayerID winner;
PlayerID who_starts;
int score[3];
extern AnimID anim;
extern char vstr[];
extern char vlevel[];
int moves;
extern const int SIZE_VSTR;
const int SPEED_BLINK = 150;
int column;
int column_moveto;
int row;
int row_dropto;
extern Gtk.HeaderBar headerbar;

int blink_r1 = 0;
int blink_c1 = 0;
int blink_r2 = 0;
int blink_c2 = 0;
int blink_t = 0;
int blink_n = 0;
bool blink_on = false;
uint timeout = 0;

void on_game_new(SimpleAction a, Variant v) {
    stop_anim ();
    game_reset ();
}

void draw_line (int r1, int c1, int r2, int c2, int tile)
{
  /* draw a line of 'tile' from r1,c1 to r2,c2 */

  bool done = false;
  int d_row = 0;
  int d_col = 0;

  if (r1 < r2)
    d_row = 1;
  else if (r1 > r2)
    d_row = -1;

  if (c1 < c2)
    d_col = 1;
  else if (c1 > c2)
    d_col = -1;

  do {
    done = (r1 == r2 && c1 == c2);
    gboard[r1, c1] = tile;
    Gfx.draw_tile (r1, c1);
    if (r1 != r2)
      r1 += d_row;
    if (c1 != c2)
      c1 += d_col;
  } while (!done);
}

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

void drop () {
  int tile;
  tile = player == PLAYER1 ? Tile.PLAYER1 : Tile.PLAYER2;

  gboard[row, column] = Tile.CLEAR;
  Gfx.draw_tile (row, column);

  row++;
  gboard[row, column] = tile;
  Gfx.draw_tile (row, column);
}

void move (int c) {
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

void stop_anim ()
{
  if (timeout == 0)
    return;
  anim = AnimID.NONE;
  Source.remove(timeout);
  timeout = 0;
}

bool on_drawarea_resize (Gtk.Widget w, Gdk.EventConfigure e) {
  Gfx.resize (w);
  return true;
}

bool on_drawarea_draw (Gtk.Widget w, Cairo.Context cr) {
  Gfx.expose (cr);
  return false;
}

void
on_game_undo (SimpleAction action, Variant parameter)
{
  int r, c;

  if (timeout != 0)
    return;
  c = vstr[moves] - '0' - 1;
  r = first_empty_row (c) + 1;
  vstr[moves] = '0';
  vstr[moves + 1] = '\0';
  moves--;

  if (gameover) {
    score[winner]--;
    scorebox_update ();
    gameover = false;
    prompt_player ();
  } else {
    swap_player ();
  }
  move_cursor (c);

  gboard[r, c] = Tile.CLEAR;
  Gfx.draw_tile (r, c);

  if (get_n_human_players () == 1 && !is_player_human ()) {
    if (moves > 0) {
      c = vstr[moves] - '0' - 1;
      r = first_empty_row (c) + 1;
      vstr[moves] = '0';
      vstr[moves + 1] = '\0';
      moves--;
      swap_player ();
      move_cursor (c);
      gboard[r, c] = Tile.CLEAR;
      Gfx.draw_tile (r, c);
    }
  }
}
void on_game_scores (SimpleAction action, Variant parameter)
{
    Gtk.Grid grid, grid2;
    Gtk.Widget icon;

    if (scorebox != null) {
        scorebox.present();
        return;
    }

    scorebox = new Gtk.Dialog.with_buttons(_("Scores"), window,
        Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.USE_HEADER_BAR);

    scorebox.set_resizable(false);
    scorebox.set_border_width(5);
    scorebox.get_content_area().set_spacing(2);

  // g_signal_connect (scorebox, "destroy",
  //                   G_CALLBACK (gtk_widget_destroyed), &scorebox);

    grid = new Gtk.Grid();
    grid.set_halign(Gtk.Align.CENTER);
    grid.set_row_spacing(6);
    grid.set_orientation(Gtk.Orientation.VERTICAL);
    grid.set_border_width(5);

    scorebox.get_content_area().pack_start(grid);

    grid2 = new Gtk.Grid();
    grid.add(grid2);
    grid2.set_column_spacing(6);

    label_name[PlayerID.PLAYER1] = new Label(null);
    grid2.attach (label_name[PlayerID.PLAYER1], 0, 0, 1, 1);
	label_name[PlayerID.PLAYER1].set_xalign(0);
	label_name[PlayerID.PLAYER1].set_yalign(0.5f);

	label_score[PlayerID.PLAYER1] = new Label(null);
    grid2.attach (label_score[PlayerID.PLAYER1], 1, 0, 1, 1);
	label_score[PlayerID.PLAYER1].set_xalign(0);
	label_score[PlayerID.PLAYER1].set_yalign(0.5f);

    label_name[PlayerID.PLAYER2] = new Label(null);
    grid2.attach (label_name[PlayerID.PLAYER2], 0, 1, 1, 1);
	label_name[PlayerID.PLAYER2].set_xalign(0);
	label_name[PlayerID.PLAYER2].set_yalign(0.5f);

	label_score[PlayerID.PLAYER2] = new Label(null);
    grid2.attach (label_score[PlayerID.PLAYER2], 1, 0, 1, 1);
	label_score[PlayerID.PLAYER2].set_xalign(0);
	label_score[PlayerID.PLAYER2].set_yalign(0.5f);

    label_name[PlayerID.NOBODY] = new Label(_("Drawn:"));
    grid2.attach (label_name[PlayerID.NOBODY], 0, 2, 1, 1);
	label_name[PlayerID.NOBODY].set_xalign(0);
	label_name[PlayerID.NOBODY].set_yalign(0.5f);

	label_score[PlayerID.NOBODY] = new Label(null);
    grid2.attach (label_score[PlayerID.NOBODY], 1, 0, 1, 1);
	label_score[PlayerID.NOBODY].set_xalign(0);
	label_score[PlayerID.NOBODY].set_yalign(0.5f);

    //scorebox.response.connect(on_dialog_close);

    scorebox.show_all();

    scorebox_update ();
}
