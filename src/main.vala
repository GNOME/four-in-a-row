/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* main.vala
 *
 * Copyright © 2018 Jacob Humphrey
 *
 * This file is part of GNOME Four-in-a-row.
 *
 * GNOME Four-in-a-row is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * GNOME Four-in-a-row is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with GNOME Four-in-a-row. If not, see <http://www.gnu.org/licenses/>.
 */

const string APPNAME_LONG = N_("Four-in-a-row");
const int SIZE_VSTR = 53;
const int SPEED_BLINK = 150;
const int SPEED_MOVE = 35;
const int SPEED_DROP = 20;
const char vlevel[] = {'0','a','b','c','\0'};
const int DEFAULT_WIDTH = 495;
const int DEFAULT_HEIGHT = 435;

public enum AnimID {
    NONE,
    MOVE,
    DROP,
    BLINK,
    HINT
}

public enum PlayerID {
    PLAYER1 = 0,
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
    PLAYER1 = 0,
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

public enum SoundID {
    DROP,
    I_WIN,
    YOU_WIN,
    PLAYER_WIN,
    DRAWN_GAME,
    COLUMN_FULL
}

class FourInARow : Gtk.Application {
    public bool gameover;
    public bool player_active;

    const ActionEntry app_entries[] = {
        {"scores", on_game_scores},
        {"quit", on_game_exit},
        {"preferences", on_settings_preferences},
        {"help", on_help_contents},
        {"about", on_help_about}
    };

    public void game_reset() {
        stop_anim();

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

        clear_board();
        set_status_message(null);
        GameBoardView.instance.draw_all();

        move_cursor(column);
        gameover = false;
        prompt_player();
        if (!is_player_human()) {
            vstr[0] = player == PLAYER1 ? vlevel[p.level[PlayerID.PLAYER1]]
                : vlevel[p.level[PlayerID.PLAYER2]];
            game_process_move(playgame((string)vstr) - 1);
        }
    }

    public void blink_winner(int n) {
        /* blink the winner's line(s) n times */

        if (winner == NOBODY)
            return;

        blink_t = winner;

        if (Board.instance.is_line_at((Tile)winner, row, column, out blink_r1,
                                      out blink_c1, out blink_r2, out blink_c2)) {
            anim = AnimID.BLINK;
            blink_on = false;
            blink_n = n;
            var temp = new Animate(0);
            timeout = Timeout.add(SPEED_BLINK,  temp.exec);
            while (timeout!=0)
                Gtk.main_iteration();
        }

    }

    public void add_actions() {
        new_game_action = new SimpleAction("new-game", null);
        new_game_action.activate.connect(this.on_game_new);
        add_action(new_game_action);

        hint_action = new SimpleAction("hint", null);
        hint_action.activate.connect(this.on_game_hint);
        add_action(hint_action);

        undo_action = new SimpleAction("undo-move", null);
        undo_action.activate.connect(on_game_undo);
        add_action(undo_action);

        set_accels_for_action("app.new-game", {"<Primary>n"});
        set_accels_for_action("app.hint", {"<Primary>h"});
        set_accels_for_action("app.undo-move", {"<Primary>z"});
        set_accels_for_action("app.quit", {"<Primary>q"});
        set_accels_for_action("app.contents", {"F1"});

        add_action_entries(app_entries, this);
    }

    void on_game_new(Variant? v) {
        stop_anim();
        game_reset();
    }

    public void draw_line(int r1, int c1, int r2, int c2, int tile) {
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
            Board.instance.set(r1, c1, (Tile) tile);
            GameBoardView.instance.draw_tile(r1, c1);
            if (r1 != r2)
                r1 += d_row;
            if (c1 != c2)
                c1 += d_col;
        } while (!done);
    }

    public FourInARow() {
        Object(application_id: "org.gnome.four-in-a-row",
               flags: ApplicationFlags.FLAGS_NONE);
        anim = AnimID.NONE;
        gameover = true;
        player_active = false;
        player = PlayerID.PLAYER1;
        winner = PlayerID.NOBODY;
        score[PlayerID.PLAYER1] = 0;
        score[PlayerID.PLAYER2] = 0;
        score[PlayerID.NOBODY] = 0;

        who_starts = PlayerID.PLAYER2;     /* This gets reversed immediately. */

        clear_board();
    }

    protected override void activate() {
        if (!window.is_visible()) {
            window.show_all();
            GameBoardView.instance.refresh_pixmaps();
            GameBoardView.instance.draw_all();
            scorebox.update();       /* update visible player descriptions */
            prompt_player();
            game_reset();
        }
    }

    // protected override void startup() {
    //     create_app(this);
    // }

    public void prompt_player() {
        int players = p.get_n_human_players();
        bool human = is_player_human();
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
                set_status_message(null);
            else
                set_status_message(_("It’s a draw!"));
            return;
        }

        switch (players) {
        case 1:
            if (human) {
                if (gameover)
                    set_status_message(_("You win!"));
                else
                    set_status_message(_("Your Turn"));
            } else {
                if (gameover)
                    set_status_message(_("I win!"));
                else
                    set_status_message(_("I’m Thinking…"));
            }
            break;
        case 2:
        case 0:

            if (gameover) {
                who = player == PLAYER1 ? theme_get_player_win(PlayerID.PLAYER1)
                    : theme_get_player_win(PlayerID.PLAYER2);
                str =  _(who);
            } else if (player_active) {
                set_status_message(_("Your Turn"));
                return;
            } else {
                who = player == PLAYER1 ? theme_get_player_turn(PlayerID.PLAYER1)
                    : theme_get_player_turn(PlayerID.PLAYER2);
                str =  _(who);
            }

            set_status_message(str);
            break;
        }
    }

    public void swap_player() {
        player = (player == PlayerID.PLAYER1) ? PlayerID.PLAYER2 : PlayerID.PLAYER1;
        move_cursor(3);
        prompt_player();
    }

    public void game_process_move(int c) {
        process_move(c);
    }

    public void play_sound(SoundID id) {
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
        path = Path.build_filename(Config.SOUND_DIRECTORY, filename);

        CanberraGtk.context_get().play(
                id,
                Canberra.PROP_MEDIA_NAME, name,
                Canberra.PROP_MEDIA_FILENAME, path);

    }

    public void process_move3(int c) {
        play_sound(SoundID.DROP);

        vstr[++moves] = '1' + (char)c;
        vstr[moves + 1] = '0';

        check_game_state();

        if (gameover) {
            score[winner]++;
            scorebox.update();
            prompt_player();
        } else {
            swap_player();
            if (!is_player_human()) {
                vstr[0] = player == PlayerID.PLAYER1 ? vlevel[p.level[PlayerID.PLAYER1]]
                    : vlevel[p.level[PlayerID.PLAYER2]];
                c = playgame((string)vstr) - 1;
                if (c < 0)
                    gameover = true;
                var nm = new NextMove(c);
                Timeout.add(SPEED_DROP, nm.exec);
            }
        }
    }

    public void game_init() {
        anim = AnimID.NONE;
        gameover = true;
        player_active = false;
        player = PlayerID.PLAYER1;
        winner = PlayerID.NOBODY;
        score[PlayerID.PLAYER1] = 0;
        score[PlayerID.PLAYER2] = 0;
        score[PlayerID.NOBODY] = 0;

        who_starts = PlayerID.PLAYER2;     /* This gets reversed immediately. */

        clear_board();
    }

    public bool is_player_human() {
        return player == PLAYER1 ? p.level[PlayerID.PLAYER1] == Level.HUMAN
            : p.level[PlayerID.PLAYER2] == Level.HUMAN;
    }

    public void process_move2(int c) {
        int r = Board.instance.first_empty_row(c);
        if (r > 0) {
            row = 0;
            row_dropto = r;
            anim = AnimID.DROP;
            var temp = new Animate(c);
            timeout = Timeout.add(SPEED_DROP, temp.exec);
        } else {
            application.play_sound(SoundID.COLUMN_FULL);
        }
    }

    public void process_move(int c) {
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

    void drop_marble(int r, int c) {
        Tile tile = player == PlayerID.PLAYER1 ? Tile.PLAYER1 : Tile.PLAYER2;

        Board.instance.set(r, c, tile);
        GameBoardView.instance.draw_tile(r, c);

        column = column_moveto = c;
        row = row_dropto = r;
    }

    public void drop() {
        Tile tile = player == PLAYER1 ? Tile.PLAYER1 : Tile.PLAYER2;

        Board.instance.set(row, column, Tile.CLEAR);
        GameBoardView.instance.draw_tile(row, column);

        row++;
        Board.instance.set(row, column, tile);
        GameBoardView.instance.draw_tile(row, column);
    }

    public void move(int c) {
        Board.instance.set(0, column, Tile.CLEAR);
        GameBoardView.instance.draw_tile(0, column);

        column = c;
        Board.instance.set(0, c, player == PlayerID.PLAYER1 ? Tile.PLAYER1 : Tile.PLAYER2);

        GameBoardView.instance.draw_tile(0, c);
    }

    public void move_cursor(int c) {
        move(c);
        column = column_moveto = c;
        row = row_dropto = 0;
    }

    void set_status_message(string? message) {
        headerbar.set_title(message);
    }

    class NextMove {
        int c;

        public NextMove(int c) {
            this.c = c;
        }

        public bool exec() {
            application.process_move(c);
            return false;
        }
    }

    void stop_anim() {
        if (timeout == 0)
            return;
        anim = AnimID.NONE;
        Source.remove(timeout);
        timeout = 0;
    }

    void clear_board() {
        Board.instance.clear();

        for (var i = 0; i < SIZE_VSTR; i++)
            vstr[i] = '\0';

        vstr[0] = vlevel[Level.WEAK];
        vstr[1] = '0';
        moves = 0;
    }

    void blink_tile(int r, int c, int t, int n) {
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
        timeout = Timeout.add(SPEED_BLINK, temp.exec);
    }

    void on_game_hint(SimpleAction action, Variant? parameter) {
        string s;
        int c;

        if (timeout != 0)
            return;
        if (gameover)
            return;

        hint_action.set_enabled(false);
        undo_action.set_enabled(false);

        application.set_status_message(_("I’m Thinking…"));

        vstr[0] = vlevel[Level.STRONG];
        c = playgame((string)vstr) - 1;

        column_moveto = c;
        while (timeout != 0)
            Gtk.main_iteration();
        anim = AnimID.HINT;
        var temp = new Animate(0);
        timeout = Timeout.add(SPEED_MOVE, temp.exec);

        application.blink_tile(0, c, Board.instance.get(0, c), 6);

        s = _("Hint: Column ")+ (c + 1).to_string();
        application.set_status_message(s);

        if (moves <= 0 || (moves == 1 && application.is_player_human()))
            undo_action.set_enabled(false);
        else
            undo_action.set_enabled(true);
    }

    void on_game_scores(SimpleAction action, Variant? parameter) {
        if (scorebox != null) {
            scorebox.present();
            return;
        }

        scorebox = new Scorebox();
        scorebox.show_all();
        scorebox.update();
    }

    void on_game_exit(SimpleAction action, Variant? parameter) {
        stop_anim();
        quit();
    }

    class Animate {
        int c;
        public Animate(int c) {
            this.c = c;
        }

        public bool exec() {
            if (anim == AnimID.NONE)
            return false;

            switch (anim) {
            case AnimID.NONE:
                break;
            case AnimID.HINT:
            case AnimID.MOVE:
                if (column < column_moveto) {
                    application.move(column + 1);
                } else if (column > column_moveto) {
                    application.move(column - 1);
                } else {
                    timeout = 0;
                    if (anim == AnimID.MOVE) {
                        anim = AnimID.NONE;
                        application.process_move2(c);
                    } else {
                        anim = AnimID.NONE;
                    }
                    return false;
                }
                break;
            case AnimID.DROP:
                if (row < row_dropto) {
                    application.drop();
                } else {
                    anim = AnimID.NONE;
                    timeout = 0;
                    application.process_move3(c);
                    return false;
                }
                break;
            case AnimID.BLINK:
                application.draw_line(blink_r1, blink_c1, blink_r2, blink_c2, blink_on ? blink_t
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
    }

    void on_game_undo(SimpleAction action, Variant? parameter) {
        int r, c;

        if (timeout != 0)
            return;
        c = vstr[moves] - '0' - 1;
        r = Board.instance.first_empty_row(c) + 1;
        vstr[moves] = '0';
        vstr[moves + 1] = '\0';
        moves--;

        if (gameover) {
            score[winner]--;
            scorebox.update();
            gameover = false;
            prompt_player();
        } else {
            swap_player();
        }
        move_cursor(c);

        Board.instance.set(r, c, Tile.CLEAR);
        GameBoardView.instance.draw_tile(r, c);

        if (p.get_n_human_players() == 1 && !application.is_player_human()) {
            if (moves > 0) {
                c = vstr[moves] - '0' - 1;
                r = Board.instance.first_empty_row(c) + 1;
                vstr[moves] = '0';
                vstr[moves + 1] = '\0';
                moves--;
                swap_player();
                move_cursor(c);
                Board.instance.set(r, c, Tile.CLEAR);
                GameBoardView.instance.draw_tile(r, c);
            }
        }
    }


    void on_settings_preferences(SimpleAction action, Variant? parameter) {
        prefsbox_open();
    }

    void on_help_about(SimpleAction action, Variant? parameter) {
        const string authors[] = {"Tim Musson <trmusson@ihug.co.nz>",
            "David Neary <bolsh@gimp.org>",
            "Nikhar Agrawal <nikharagrawal2006@gmail.com>",
            "Jacob Humphrey <jacob.ryan.humphrey@gmail.com"
        };

        const string artists[] = { "Alan Horkan",
            "Anatol Drlicek",
            "Based on the Faenza icon theme by Matthieu James"
        };

        const string documenters[] = {"Timothy Musson"};

        Gtk.show_about_dialog(window,
            name: _(Config.APPNAME_LONG),
            version: Config.VERSION,
            copyright: "Copyright © 1999–2008 Tim Musson and David Neary\n" +
                       "Copyright © 2014 Michael Catanzaro\n" +
                       "Copyright © 2018 Jacob Humphrey",
            license_type: Gtk.License.GPL_3_0,
            comments: _("Connect four in a row to win"),
            authors: authors,
            documenters: documenters,
            artists: artists,
            translator_credits: _("translator-credits"),
            logo_icon_name: "four-in-a-row",
            website: "https://wiki.gnome.org/Apps/Four-in-a-row");
    }

    void on_help_contents(SimpleAction action, Variant? parameter) {
        try {
            Gtk.show_uri_on_window(window,
                "help:four-in-a-row",
                Gtk.get_current_event_time());
        } catch(Error error) {
            warning("Failed to show help: %s", error.message);
        }
    }

    void check_game_state() {
        if (Board.instance.is_line_at((Tile)player, row, column)) {
            gameover = true;
            winner = player;
            switch (p.get_n_human_players()) {
            case 1:
                play_sound(is_player_human() ? SoundID.YOU_WIN : SoundID.I_WIN);
                break;
            case 0:
            case 2:
                play_sound(SoundID.PLAYER_WIN);
                break;
            }
            blink_winner(6);
        } else if (moves == 42) {
            gameover = true;
            winner = NOBODY;
            play_sound(SoundID.DRAWN_GAME);
        }
    }

    protected override void startup() {
        base.startup();
        Gtk.AspectFrame frame;
        GLib.Menu app_menu, section;

        Gtk.Builder builder;
        Gtk.CssProvider css_provider;

        Gtk.Window.set_default_icon_name("four-in-a-row");

        css_provider = new Gtk.CssProvider();
        try {
            css_provider.load_from_data("GtkButtonBox {-GtkButtonBox-child-internal-pad-x:0;}\0");
        } catch (Error error) {
            stderr.printf("Could not load UI: %s\n", error.message);
            return;
        }
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(),
                                                 css_provider,
                                                 Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        builder = new Gtk.Builder.from_file(Config.DATA_DIRECTORY + "/four-in-a-row.ui");

        window = builder.get_object("fiar-window") as Gtk.ApplicationWindow;
        window.application = this;
        window.set_default_size(DEFAULT_WIDTH, DEFAULT_HEIGHT); /* TODO save size & state */

        headerbar = builder.get_object("headerbar") as Gtk.HeaderBar;

        add_actions();

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

        this.app_menu = app_menu;

        frame = builder.get_object("frame") as Gtk.AspectFrame;

        frame.add(GameBoardView.instance);

        hint_action.set_enabled(false);
        undo_action.set_enabled(false);
    }

    Gtk.HeaderBar headerbar;
}

SimpleAction hint_action;
SimpleAction undo_action;
SimpleAction new_game_action;

FourInARow? application;
Gtk.ApplicationWindow window;
Scorebox? scorebox = null;

PlayerID player;
PlayerID winner;
PlayerID who_starts;
int score[3];
AnimID anim;
char vstr[53];
int moves;
int column;
int column_moveto;
int row;
int row_dropto;
int blink_r1 = 0;
int blink_c1 = 0;
int blink_r2 = 0;
int blink_c2 = 0;
int blink_t = 0;
int blink_n = 0;
bool blink_on = false;
uint timeout = 0;

public int main(string[] argv) {
    Intl.setlocale();

    application = new FourInARow();

    Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
    Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain(Config.GETTEXT_PACKAGE);

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

    p = new Prefs();
    application.game_init();

    if (!GameBoardView.instance.load_pixmaps())
        return 1;

    var app_retval = application.run(argv);

    return app_retval;
}


