/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* main.vala
 *
 * Copyright © 2018 Jacob Humphrey
 *
 * This file is part of GNOME Four in a Row.
 *
 * GNOME Four in a Row is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * GNOME Four in a Row is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with GNOME Four in a Row. If not, see <http://www.gnu.org/licenses/>.
 */


public enum AnimID {
    NONE,
    MOVE,
    DROP,
    BLINK,
    HINT
}

public enum PlayerID {
    PLAYER1,
    PLAYER2,
    NOBODY
}

public enum Level {
    HUMAN,
    WEAK,
    MEDIUM,
    STRONG
}

public enum Tile {
    PLAYER1,
    PLAYER2,
    CLEAR,
    CLEAR_CURSOR,
    PLAYER1_CURSOR,
    PLAYER2_CURSOR,
}

public enum Move {
    LEFT,
    RIGHT,
    DROP
}

public enum SoundID{
    DROP,
    I_WIN,
    YOU_WIN,
    PLAYER_WIN,
    DRAWN_GAME,
    COLUMN_FULL
}

SimpleAction hint_action;
SimpleAction undo_action;
SimpleAction new_game_action;

const string APPNAME_LONG = N_("Four-in-a-row");
const int SIZE_VSTR = 53;

Gtk.Application? application;
Gtk.Window window;
Gtk.Dialog? scorebox = null;
Gtk.Label label_name[3];
Gtk.Label label_score[3];
bool gameover;
bool player_active;
PlayerID player;
PlayerID winner;
PlayerID who_starts;
int score[3];
AnimID anim;
char vstr[53];
const char vlevel[] = {'0','a','b','c','\0'};
int moves;
const int SPEED_BLINK = 150;
const int SPEED_MOVE = 35;
const int SPEED_DROP = 20;
int column;
int column_moveto;
int row;
int row_dropto;
Gtk.HeaderBar headerbar;

const int DEFAULT_WIDTH = 495;
const int DEFAULT_HEIGHT = 435;

int blink_r1 = 0;
int blink_c1 = 0;
int blink_r2 = 0;
int blink_c2 = 0;
int blink_t = 0;
int blink_n = 0;
bool blink_on = false;
uint timeout = 0;

void on_game_new(SimpleAction a, Variant? v) {
    stop_anim ();
    game_reset ();
}

void draw_line (int r1, int c1, int r2, int c2, int tile) {
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

public int main (string[] argv) {
    gboard = new int[7,7];
    Intl.setlocale();

    application = new Gtk.Application("org.gnome.four-in-a-row", 0);

    Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
    Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain(Config.GETTEXT_PACKAGE);

    application.startup.connect(create_app);
    application.activate.connect(activate);

    var context = new OptionContext();
    context.add_group(Gtk.get_option_group(true));
    try {
        context.parse(ref argv);
    } catch (Error error) {
        print("%s", error.message);
        return 1;
    }

    settings = new GLib.Settings("org.gnome.four-in-a-row");

    Environment.set_application_name(_(Config.APPNAME_LONG));

    prefs_init();
    game_init();

    if (!Gfx.load_pixmaps())
        return 1;

    var app_retval = application.run(argv);

    //game_free();

    return app_retval;
}

public void activate () {
    if (!window.is_visible()) {
        window.show_all();
        Gfx.refresh_pixmaps();
        Gfx.draw_all ();
        scorebox_update ();       /* update visible player descriptions */
        prompt_player ();
        game_reset ();
    }
}

class NextMove {
    int c;

    public NextMove (int c) {
        this.c = c;
    }

    public bool exec () {
        return next_move(c);
    }
}

public bool next_move (int c) {
    process_move(c);
    return false;
}

public void game_process_move (int c) {
    process_move(c);
}

public void game_init () {
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

int first_empty_row (int c) {
    int r = 1;

    while (r < 7 && gboard[r, c] == Tile.CLEAR)
        r++;
    return r - 1;
}

int get_n_human_players () {
    if (p.level[PlayerID.PLAYER1] != Level.HUMAN && p.level[PlayerID.PLAYER2] != Level.HUMAN)
        return 0;
    if (p.level[PlayerID.PLAYER1] != Level.HUMAN || p.level[PlayerID.PLAYER2] != Level.HUMAN)
        return 1;
    return 2;
}

bool is_player_human () {
    return player == PLAYER1 ? p.level[PlayerID.PLAYER1] == Level.HUMAN
        : p.level[PlayerID.PLAYER2] == Level.HUMAN;
}

static void drop_marble (int r, int c) {
    int tile;
    tile = player == PlayerID.PLAYER1 ? Tile.PLAYER1 : Tile.PLAYER2;

    gboard[r, c] = tile;
    Gfx.draw_tile (r, c);

    column = column_moveto = c;
    row = row_dropto = r;
}

void drop () {
    Tile tile = player == PLAYER1 ? Tile.PLAYER1 : Tile.PLAYER2;

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

static void move_cursor (int c) {
    move (c);
    column = column_moveto = c;
    row = row_dropto = 0;
}

void swap_player () {
    player = (player == PlayerID.PLAYER1) ? PlayerID.PLAYER2 : PlayerID.PLAYER1;
    move_cursor (3);
    prompt_player ();
}


void set_status_message (string? message) {
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
    var temp = new Animate(0);
    timeout = Timeout.add (SPEED_BLINK, temp.exec);
}

void stop_anim () {
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

void on_game_undo (SimpleAction action, Variant? parameter) {
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
void on_game_scores (SimpleAction action, Variant? parameter) {
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

    label_name[PlayerID.PLAYER1] = new Gtk.Label(null);
    grid2.attach (label_name[PlayerID.PLAYER1], 0, 0, 1, 1);
    label_name[PlayerID.PLAYER1].set_xalign(0);
    label_name[PlayerID.PLAYER1].set_yalign(0.5f);

    label_score[PlayerID.PLAYER1] = new Gtk.Label(null);
    grid2.attach (label_score[PlayerID.PLAYER1], 1, 0, 1, 1);
    label_score[PlayerID.PLAYER1].set_xalign(0);
    label_score[PlayerID.PLAYER1].set_yalign(0.5f);

    label_name[PlayerID.PLAYER2] = new Gtk.Label(null);
    grid2.attach (label_name[PlayerID.PLAYER2], 0, 1, 1, 1);
    label_name[PlayerID.PLAYER2].set_xalign(0);
    label_name[PlayerID.PLAYER2].set_yalign(0.5f);

    label_score[PlayerID.PLAYER2] = new Gtk.Label(null);
    grid2.attach (label_score[PlayerID.PLAYER2], 1, 0, 1, 1);
    label_score[PlayerID.PLAYER2].set_xalign(0);
    label_score[PlayerID.PLAYER2].set_yalign(0.5f);

    label_name[PlayerID.NOBODY] = new Gtk.Label(_("Drawn:"));
    grid2.attach (label_name[PlayerID.NOBODY], 0, 2, 1, 1);
    label_name[PlayerID.NOBODY].set_xalign(0);
    label_name[PlayerID.NOBODY].set_yalign(0.5f);

    label_score[PlayerID.NOBODY] = new Gtk.Label(null);
    grid2.attach (label_score[PlayerID.NOBODY], 1, 0, 1, 1);
    label_score[PlayerID.NOBODY].set_xalign(0);
    label_score[PlayerID.NOBODY].set_yalign(0.5f);

    //scorebox.response.connect(on_dialog_close);

    scorebox.show_all();

    scorebox_update ();
}

void on_game_exit (SimpleAction action, Variant? parameter) {
    stop_anim ();
    application.quit();
}

void process_move2 (int c) {
    int r = first_empty_row (c);
    if (r > 0) {
        row = 0;
        row_dropto = r;
        anim = AnimID.DROP;
        var temp = new Animate(c);
        timeout = Timeout.add(SPEED_DROP, temp.exec);
    } else {
        play_sound (SoundID.COLUMN_FULL);
    }
}

bool is_vline_at (PlayerID p, int r, int c, int * r1, int * c1, int * r2, int * c2) {
    *r1 = *r2 = r;
    *c1 = *c2 = c;
    while (*r1 > 1 && gboard[*r1 - 1, c] == p)
        *r1 = *r1 - 1;
    while (*r2 < 6 && gboard[*r2 + 1, c] == p)
        *r2 = *r2 + 1;
    if (*r2 - *r1 >= 3)
        return true;
    return false;
}

bool is_dline1_at (PlayerID p, int r, int c, int * r1, int * c1, int * r2, int * c2) {
    /* upper left to lower right */
    *r1 = *r2 = r;
    *c1 = *c2 = c;
    while (*c1 > 0 && *r1 > 1 && gboard[*r1 - 1, *c1 - 1] == p) {
        *r1 = *r1 - 1;
        *c1 = *c1 - 1;
    }
    while (*c2 < 6 && *r2 < 6 && gboard[*r2 + 1, *c2 + 1] == p) {
        *r2 = *r2 + 1;
        *c2 = *c2 + 1;
    }
    if (*r2 - *r1 >= 3)
        return true;
    return false;
}

bool is_line_at (PlayerID p, int r, int c) {
    int r1, r2, c1, c2;

    return is_hline_at (p, r, c, &r1, &c1, &r2, &c2) ||
        is_vline_at (p, r, c, &r1, &c1, &r2, &c2) ||
        is_dline1_at (p, r, c, &r1, &c1, &r2, &c2) ||
        is_dline2_at (p, r, c, &r1, &c1, &r2, &c2);
}

bool is_dline2_at (PlayerID p, int r, int c, int * r1, int * c1, int * r2, int * c2) {
    /* upper right to lower left */
    *r1 = *r2 = r;
    *c1 = *c2 = c;
    while (*c1 < 6 && *r1 > 1 && gboard[*r1 - 1, *c1 + 1] == p) {
        *r1 = *r1 - 1;
        *c1 = *c1 + 1;
    }
    while (*c2 > 0 && *r2 < 6 && gboard[*r2 + 1, *c2 - 1] == p) {
        *r2 = *r2 + 1;
        *c2 = *c2 - 1;
    }
    if (*r2 - *r1 >= 3)
        return true;
    return false;
}

bool is_hline_at (PlayerID p, int r, int c, int * r1, int * c1, int * r2, int * c2) {
    *r1 = *r2 = r;
    *c1 = *c2 = c;
    while (*c1 > 0 && gboard[r, *c1 - 1] == p)
        *c1 = *c1 - 1;
    while (*c2 < 6 && gboard[r, *c2 + 1] == p)
        *c2 = *c2 + 1;
    if (*c2 - *c1 >= 3)
        return true;
    return false;
}

void scorebox_reset () {
    score[PlayerID.PLAYER1] = 0;
    score[PlayerID.PLAYER2] = 0;
    score[PlayerID.NOBODY] = 0;
    scorebox_update ();
}

void process_move (int c) {
    if (timeout != 0) {
        var temp = new Animate(c);
        Timeout.add(SPEED_DROP, temp.exec);
        return;
    }

    column_moveto = c;
    anim = AnimID.MOVE;
    var temp = new Animate(c);
    timeout = Timeout.add(SPEED_DROP, temp.exec);
}

void on_help_about (SimpleAction action, Variant? parameter) {
    const string authors[] = {"Tim Musson <trmusson@ihug.co.nz>",
        "David Neary <bolsh@gimp.org>",
        "Nikhar Agrawal <nikharagrawal2006@gmail.com>"
    };

    const string artists[] = { "Alan Horkan",
        "Anatol Drlicek",
        "Based on the Faenza icon theme by Matthieu James"
    };

    const string documenters[] = {"Timothy Musson"};

    Gtk.show_about_dialog(window,
        name: _(Config.APPNAME_LONG),
        version: Config.VERSION,
        copyright: "Copyright © 1999–2008 Tim Musson and David Neary\nCopyright © 2014 Michael Catanzaro",
        license_type: Gtk.License.GPL_2_0,
        comments: _("Connect four in a row to win"),
        authors: authors,
        documenters: documenters,
        artists: artists,
        translator_credits: _("translator-credits"),
        logo_icon_name: "four-in-a-row",
        website: "https://wiki.gnome.org/Apps/Four-in-a-row"
        );
}

void check_game_state () {
    if (is_line_at (player, row, column)) {
        gameover = true;
        winner = player;
        switch (get_n_human_players ()) {
        case 1:
            play_sound (is_player_human () ? SoundID.YOU_WIN : SoundID.I_WIN);
            break;
        case 0:
        case 2:
            play_sound (SoundID.PLAYER_WIN);
            break;
        }
        blink_winner (6);
    } else if (moves == 42) {
        gameover = true;
        winner = NOBODY;
        play_sound (SoundID.DRAWN_GAME);
    }
}

void on_help_contents (SimpleAction action, Variant? parameter) {
    try {
        Gtk.show_uri (window.get_screen(),
            "help:four-in-a-row",
            Gtk.get_current_event_time ());
    } catch(Error error) {
        warning ("Failed to show help: %s", error.message);
    }
}

void process_move3 (int c) {
    play_sound (SoundID.DROP);

    vstr[++moves] = '1' + (char)c;
    vstr[moves + 1] = '0';

    check_game_state ();

    if (gameover) {
        score[winner]++;
        scorebox_update ();
        prompt_player ();
    } else {
        swap_player ();
        if (!is_player_human ()) {
            vstr[0] = player == PlayerID.PLAYER1 ? vlevel[p.level[PlayerID.PLAYER1]]
                : vlevel[p.level[PlayerID.PLAYER2]];
            c = playgame ((string)vstr) - 1;
            if (c < 0)
                gameover = true;
            var nm = new NextMove(c);
            Timeout.add(SPEED_DROP, nm.exec);
        }
    }
}

void game_reset () {
    stop_anim ();

    undo_action.set_enabled(false);
    hint_action.set_enabled(false);

    who_starts = (who_starts == PlayerID.PLAYER1)
        ? PlayerID.PLAYER2 : PlayerID.PLAYER1;
    player = who_starts;

    gameover = true;
    player_active = false;
    winner = NOBODY;
    column = 3;
    column_moveto = 3;
    row = 0;
    row_dropto = 0;

    clear_board ();
    set_status_message (null);
    Gfx.draw_all ();

    move_cursor (column);
    gameover = false;
    prompt_player ();
    if (!is_player_human ()) {
        vstr[0] = player == PLAYER1 ? vlevel[p.level[PlayerID.PLAYER1]]
            : vlevel[p.level[PlayerID.PLAYER2]];
        game_process_move (playgame ((string)vstr) - 1);
    }
}

void play_sound (SoundID id) {
    string name;

    if (!p.do_sound)
        return;

    switch (id) {
    case SoundID.DROP:
        name = "slide";
        break;
    case SoundID.I_WIN:
        name = "reverse";
        break;
    case SoundID.YOU_WIN:
        name = "bonus";
        break;
    case SoundID.PLAYER_WIN:
        name = "bonus";
        break;
    case SoundID.DRAWN_GAME:
        name = "reverse";
        break;
    case SoundID.COLUMN_FULL:
        name = "bad";
        break;
    default:
        return;
    }


    string filename, path;

    filename = name + ".ogg";
    path = Path.build_filename (Config.SOUND_DIRECTORY, filename);

    CanberraGtk.context_get().play(
            id,
            Canberra.PROP_MEDIA_NAME, name,
            Canberra.PROP_MEDIA_FILENAME, path);

}

class Animate {
    int c;
    public Animate (int c) {
        this.c = c;
    }

    public bool exec () {
        return on_animate(c);
    }
}

bool on_animate (int c = 0) {
    if (anim == AnimID.NONE)
        return false;

    switch (anim) {
    case AnimID.NONE:
        break;
    case AnimID.HINT:
    case AnimID.MOVE:
        if (column < column_moveto) {
            move (column + 1);
        } else if (column > column_moveto) {
            move (column - 1);
        } else {
            timeout = 0;
            if (anim == AnimID.MOVE) {
                anim = AnimID.NONE;
                process_move2 (c);
            } else {
                anim = AnimID.NONE;
            }
            return false;
        }
        break;
    case AnimID.DROP:
        if (row < row_dropto) {
            drop ();
        } else {
            anim = AnimID.NONE;
            timeout = 0;
            process_move3 (c);
            return false;
        }
        break;
    case AnimID.BLINK:
        draw_line (blink_r1, blink_c1, blink_r2, blink_c2, blink_on ? blink_t
            : Tile.CLEAR);
        blink_n--;
        if (blink_n <= 0 && blink_on) {
            anim = AnimID.NONE;
            timeout = 0;
            return false;
        }
        blink_on = !blink_on;
        break;
    }
    return true;
}

bool on_key_press (Gtk.Widget  w, Gdk.EventKey  e) {
    if ((player_active) || timeout != 0 ||
            (e.keyval != p.keypress[Move.LEFT] &&
            e.keyval != p.keypress[Move.RIGHT] &&
            e.keyval != p.keypress[Move.DROP])) {
        return false;
    }

    if (gameover) {
        blink_winner (2);
        return true;
    }

    if (e.keyval == p.keypress[Move.LEFT] && column != 0) {
        column_moveto--;
        move_cursor (column_moveto);
    } else if (e.keyval == p.keypress[Move.RIGHT] && column < 6) {
        column_moveto++;
        move_cursor (column_moveto);
    } else if (e.keyval == p.keypress[Move.DROP]) {
        game_process_move (column);
    }
    return true;
}

void blink_winner (int n) {
    /* blink the winner's line(s) n times */

    if (winner == NOBODY)
        return;

    blink_t = winner;
    if (is_hline_at (winner, row, column, &blink_r1, &blink_c1, &blink_r2, &blink_c2)) {
        anim = AnimID.BLINK;
        blink_on = false;
        blink_n = n;
        var temp = new Animate(0);
        timeout = Timeout.add (SPEED_BLINK,  temp.exec);
        while (timeout!=0)
            Gtk.main_iteration();
    }

    if (is_vline_at (winner, row, column, &blink_r1, &blink_c1, &blink_r2, &blink_c2)) {
        anim = AnimID.BLINK;
        blink_on = false;
        blink_n = n;
        var temp = new Animate(0);
        timeout = Timeout.add (SPEED_BLINK,  temp.exec);
        while (timeout!=0)
            Gtk.main_iteration();
    }

    if (is_dline1_at (winner, row, column, &blink_r1, &blink_c1, &blink_r2, &blink_c2)) {
        anim = AnimID.BLINK;
        blink_on = false;
        blink_n = n;
        var temp = new Animate(0);
        timeout = Timeout.add (SPEED_BLINK,  temp.exec);
        while (timeout!=0)
            Gtk.main_iteration();
    }

    if (is_dline2_at (winner, row, column, &blink_r1, &blink_c1, &blink_r2, &blink_c2)) {
        anim = AnimID.BLINK;
        blink_on = false;
        blink_n = n;
        var temp = new Animate(0);
        timeout = Timeout.add (SPEED_BLINK,  temp.exec);
        while (timeout!=0)
            Gtk.main_iteration();
    }
}

bool on_button_press (Gtk.Widget w, Gdk.EventButton e) {
    int x, y;
    if (player_active) {
        return false;
    }

    if (gameover && timeout == 0) {
        blink_winner (2);
    } else if (is_player_human () && timeout == 0) {
        w.get_window().get_device_position (e.device, out x, out y, null);
        game_process_move (Gfx.get_column (x));
    }

    return true;
}

void scorebox_update () {
    string s;

    if (scorebox == null)
        return;

    if (get_n_human_players () == 1) {
        if (p.level[PlayerID.PLAYER1] == Level.HUMAN) {
            label_score[PlayerID.PLAYER1].set_text(_("You:"));
            label_score[PlayerID.PLAYER2].set_text(_("Me:"));
        } else {
            label_score[PlayerID.PLAYER2].set_text(_("You:"));
            label_score[PlayerID.PLAYER1].set_text(_("Me:"));
        }
    } else {
        label_name[PlayerID.PLAYER1].set_text(theme_get_player(PlayerID.PLAYER1));
        label_name[PlayerID.PLAYER2].set_text(theme_get_player(PlayerID.PLAYER2));
    }

    label_score[PlayerID.PLAYER1].set_text((string)score[PlayerID.PLAYER1]);
    label_score[PlayerID.PLAYER2].set_text((string)score[PlayerID.PLAYER2]);
    label_score[PlayerID.NOBODY].set_text((string)score[PlayerID.NOBODY]);

}

void on_settings_preferences (SimpleAction action, Variant? parameter) {
    prefsbox_open ();
}

void on_game_hint (SimpleAction action, Variant? parameter) {
    string s;
    int c;

    if (timeout != 0)
        return;
    if (gameover)
        return;

    hint_action.set_enabled(false);
    undo_action.set_enabled(false);

    set_status_message (_("I’m Thinking…"));

    vstr[0] = vlevel[Level.STRONG];
    c = playgame ((string)vstr) - 1;

    column_moveto = c;
    while (timeout != 0)
        Gtk.main_iteration ();
    anim = AnimID.HINT;
    var temp = new Animate(0);
    timeout = Timeout.add (SPEED_MOVE, temp.exec);

    blink_tile (0, c, gboard[0, c], 6);

    s = _("Hint: Column ")+ (c + 1).to_string();
    set_status_message (s);
    g_free (s);

    if (moves <= 0 || (moves == 1 && is_player_human ()))
        undo_action.set_enabled(false);
    else
        undo_action.set_enabled(true);
}

const GLib.ActionEntry app_entries[] = {
    {"new-game", on_game_new, null, null, null},
    {"undo-move", on_game_undo, null, null, null},
    {"hint", on_game_hint, null, null, null},
    {"scores", on_game_scores, null, null, null},
    {"quit", on_game_exit, null, null, null},
    {"preferences", on_settings_preferences, null, null, null},
    {"help", on_help_contents, null, null, null},
    {"about", on_help_about, null, null, null}
};

void create_app (GLib.Application app) {
    Gtk.AspectFrame frame;
    GLib.Menu app_menu, section;

    Gtk.Builder builder;
    Gtk.CssProvider css_provider;
    //Error *error = NULL;

    Gtk.Window.set_default_icon_name("four-in-a-row");

    css_provider = new Gtk.CssProvider ();
    try {
        css_provider.load_from_data("GtkButtonBox{-GtkButtonBox-child-internal-pad-x:0;}\0");
    } catch (Error error){
        stderr.printf("Could not load UI: %s\n", error.message);
        return;
    }
    Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);


    builder = new Gtk.Builder.from_file (Config.DATA_DIRECTORY + "/four-in-a-row.ui");

    window = (Gtk.Window) builder.get_object ("fiar-window");
    window.application = application;
    window.set_default_size(DEFAULT_WIDTH, DEFAULT_HEIGHT); // TODO save size & state

    headerbar = (Gtk.HeaderBar) builder.get_object ("headerbar");

    application.add_action_entries(app_entries, application);
    application.add_accelerator("<Primary>n", "app.new-game", null);
    application.add_accelerator("<Primary>h", "app.hint", null);
    application.add_accelerator("<Primary>z", "app.undo-move", null);
    application.add_accelerator("<Primary>q", "app.quit", null);
    application.add_accelerator("F1", "app.contents", null);

    app_menu = new GLib.Menu();
    section = new GLib.Menu();
    app_menu.append_section(null, section);
    section.append(_("_Scores"), "app.scores");
    section.append(_("_Preferences"), "app.preferences");
    section = new GLib.Menu();
    app_menu.append_section(null, section);
    section.append(_("_Help"), "app.help");
    section.append(_("_About"), "app.about");
    section.append(_("_Quit"), "app.quit");

    new_game_action = (GLib.SimpleAction) application.lookup_action("new-game");
    undo_action = (GLib.SimpleAction) application.lookup_action("undo-move");
    hint_action = (GLib.SimpleAction) application.lookup_action("hint");

    application.app_menu = app_menu;

    frame = (Gtk.AspectFrame) builder.get_object("frame");

    drawarea = new Gtk.DrawingArea();
    /* set a min size to avoid pathological behavior of gtk when scaling down */
    drawarea.set_size_request (350, 350);
    drawarea.halign = Gtk.Align.FILL;
    drawarea.valign = Gtk.Align.FILL;
    frame.add(drawarea);

    drawarea.events = Gdk.EventMask.EXPOSURE_MASK | Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK;
    drawarea.configure_event.connect(on_drawarea_resize);
    drawarea.draw.connect(on_drawarea_draw);
    drawarea.button_press_event.connect(on_button_press);
    drawarea.key_press_event.connect(on_key_press);

    hint_action.set_enabled(false);
    undo_action.set_enabled(false);
}

void on_dialog_close (Gtk.Widget w, int response_id) {
    w.hide();
}

void prompt_player () {
    int players = get_n_human_players ();
    bool human = is_player_human ();
    string who;
    string str;

    hint_action.set_enabled(human && !gameover);

    switch (players) {
    case 0:
        undo_action.set_enabled(false);
        break;
    case 1:
        undo_action.set_enabled((human && moves >1) || (!human && gameover));
        break;
    case 2:
        undo_action.set_enabled(moves > 0);
        break;
    }

    if (gameover && winner == PlayerID.NOBODY) {
        if (score[PlayerID.NOBODY] == 0)
            set_status_message (null);
        else
            set_status_message (_("It’s a draw!"));
        return;
    }

    switch (players) {
    case 1:
        if (human) {
            if (gameover)
                set_status_message (_("You win!"));
            else
                set_status_message (_("Your Turn"));
        } else {
            if (gameover)
                set_status_message (_("I win!"));
            else
                set_status_message (_("I’m Thinking…"));
        }
        break;
    case 2:
    case 0:

        if (gameover) {
            who = player == PLAYER1 ? theme_get_player_win (PlayerID.PLAYER1)
                : theme_get_player_win (PlayerID.PLAYER2);
            str =  _(who);
        } else if (player_active) {
            set_status_message (_("Your Turn"));
            return;
        } else {
            who = player == PLAYER1 ? theme_get_player_turn (PlayerID.PLAYER1)
                : theme_get_player_turn (PlayerID.PLAYER2);
            str =  _(who);
        }

        set_status_message (str);
        break;
    }
}
