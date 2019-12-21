/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
   This file is part of GNOME Four-in-a-row.

   Copyright © 2018 Jacob Humphrey
   Copyright © 2019 Arnaud Bonatti

   GNOME Four-in-a-row is free software: you can redistribute it and/or
   modify it under the terms of the GNU General Public License as published
   by the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   GNOME Four-in-a-row is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along
   with GNOME Four-in-a-row.  If not, see <https://www.gnu.org/licenses/>.
*/

using Gtk;

private class FourInARow : Gtk.Application
{
    /* Translators: application name, as used in the window manager, the window title, the about dialog... */
    private const string PROGRAM_NAME = _("Four-in-a-row");
    private const int SIZE_VSTR = 53;
    private const int SPEED_BLINK = 150;
    private const int SPEED_MOVE = 35;
    private const int SPEED_DROP = 20;
    private const char vlevel [] = { '0','a','b','c' };

    private enum AnimID {
        NONE,
        MOVE,
        DROP,
        BLINK,
        HINT
    }

    // game status
    private bool gameover = true;
    private PlayerID player = PlayerID.PLAYER1;
    private PlayerID winner = PlayerID.NOBODY;
    private PlayerID last_first_player = PlayerID.NOBODY;
    private Board game_board = new Board ();
    private bool one_player_game;
    private int ai_level;
    /**
     * score:
     *
     * The scores for the current instance (Player 1, Player 2, Draw)
     */
    private int [] score = { 0, 0, 0 };
    private bool reset_score = false;

    // widgets
    private Scorebox scorebox;
    private GameBoardView game_board_view;
    private GameWindow window;
    private NewGameScreen new_game_screen;

    // game state
    private char vstr [53];
    private int moves;
    private int column;
    private int column_moveto;
    private int row;
    private int row_dropto;

    // animation
    private static AnimID anim = AnimID.NONE;
    private int blink_r1 = 0;
    private int blink_c1 = 0;
    private int blink_r2 = 0;
    private int blink_c2 = 0;
    private int blink_t = 0;
    private int blink_n = 0;
    private bool blink_on = false;
    private uint timeout = 0;

    private const GLib.ActionEntry app_entries [] =  // see also add_actions()
    {
        { "game-type",      null,           "s", "'dark'", change_game_type },
        { "scores",         on_game_scores          },
        { "quit",           on_game_exit            },
        { "help",           on_help_contents        },
        { "about",          on_help_about           }
    };

    private static int main (string [] args)
    {
        Intl.setlocale ();
        Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (GETTEXT_PACKAGE);

        Environment.set_application_name (PROGRAM_NAME);
        Window.set_default_icon_name ("org.gnome.Four-in-a-row");

        return new FourInARow ().run (args);
    }

    private FourInARow ()
    {
        Object (application_id: "org.gnome.Four-in-a-row", flags: ApplicationFlags.FLAGS_NONE);

        clear_board ();
    }

    protected override void startup ()
    {
        base.startup ();

        /* UI parts */
        new_game_screen = new NewGameScreen ();
        new_game_screen.show ();

        game_board_view = new GameBoardView (game_board);
        game_board_view.show ();

        GLib.Menu app_menu = new GLib.Menu ();

        GLib.Menu appearance_menu = new GLib.Menu ();
        for (uint8 i = 0; i < theme.length; i++)     // TODO default theme
            appearance_menu.append (theme_get_title (i), @"app.theme-id($i)");
        appearance_menu.freeze ();

        GLib.Menu section = new GLib.Menu ();
        /* Translators: hamburger menu entry; "Appearance" submenu (with a mnemonic that appears pressing Alt) */
        section.append_submenu (_("A_ppearance"), (!) appearance_menu);


        /* Translators: hamburger menu entry with checkbox, for activating or disactivating sound (with a mnemonic that appears pressing Alt) */
        section.append (_("_Sound"), "app.sound");
        section.freeze ();
        app_menu.append_section (null, section);

        section = new GLib.Menu ();
        /* Translators: hamburger menu entry; opens the Scores dialog */
        section.append (_("_Scores"), "app.scores");
        section.freeze ();
        app_menu.append_section (null, section);

        section = new GLib.Menu ();
        /* Translators: hamburger menu entry; opens the application help */
        section.append (_("_Help"), "app.help");


        /* Translators: hamburger menu entry; opens the About dialog */
        section.append (_("_About Four-in-a-row"), "app.about");
        section.freeze ();
        app_menu.append_section (null, section);

        app_menu.freeze ();

        MenuButton history_button_1 = new HistoryButton (/* direction: down */ false);
        MenuButton history_button_2 = new HistoryButton (/* direction: up   */ true);

        /* Window */
        window = new GameWindow ("/org/gnome/Four-in-a-row/ui/four-in-a-row.css",
                                 PROGRAM_NAME,
                                 /* start_now */ true,
                                 GameWindowFlags.SHOW_START_BUTTON,
                                 (Box) new_game_screen,
                                 game_board_view,
                                 app_menu,
                                 history_button_1,
                                 history_button_2);

        scorebox = new Scorebox (window, this);
        scorebox.update (score, one_player_game);    /* update visible player descriptions */

        add_actions ();

        /* various */
        game_board_view.column_clicked.connect (column_clicked_cb);
        window.key_press_event.connect (on_key_press);

        window.play.connect (on_game_new);
        window.undo.connect (on_game_undo);
        window.hint.connect (on_game_hint);

        window.allow_hint (false);
        window.allow_undo (false);

        prompt_player ();
        game_reset ();

        add_window (window);
    }
    private inline void add_actions ()
    {
        GLib.Settings settings = Prefs.instance.settings;

        add_action (settings.create_action ("sound"));
        add_action (settings.create_action ("theme-id"));
        add_action (settings.create_action ("num-players"));
        add_action (settings.create_action ("first-player"));
        add_action (settings.create_action ("opponent"));

        set_accels_for_action ("ui.new-game",           {        "<Primary>n"       });
        set_accels_for_action ("ui.start-game",         { "<Shift><Primary>n"       });
        set_accels_for_action ("app.quit",              {        "<Primary>q"       });
        set_accels_for_action ("ui.hint",               {        "<Primary>h"       });
        set_accels_for_action ("ui.undo",               {        "<Primary>z"       });
     // set_accels_for_action ("ui.redo",               { "<Shift><Primary>z"       });
        set_accels_for_action ("ui.back",               {                 "Escape"  });
        set_accels_for_action ("ui.toggle-hamburger",   {                 "F10"     });
        set_accels_for_action ("app.help",              {                 "F1"      });
        set_accels_for_action ("app.about",             {          "<Shift>F1"      });

        add_action_entries (app_entries, this);

        game_type_action = (SimpleAction) lookup_action ("game-type");

        settings.changed ["first-player"].connect (() => {
                if (settings.get_int ("num-players") == 2)
                    return;
                if (settings.get_string ("first-player") == "human")
                    game_type_action.set_state (new Variant.string ("human"));
                else
                    game_type_action.set_state (new Variant.string ("computer"));
            });

        settings.changed ["num-players"].connect (() => {
                bool solo = settings.get_int ("num-players") == 1;
                new_game_screen.update_sensitivity (solo);
                reset_score = true;
                if (!solo)
                    game_type_action.set_state (new Variant.string ("two"));
                else if (settings.get_string ("first-player") == "human")
                    game_type_action.set_state (new Variant.string ("human"));
                else
                    game_type_action.set_state (new Variant.string ("computer"));
                if (solo)
                    last_first_player = PlayerID.NOBODY;
            });
        bool solo = settings.get_int ("num-players") == 1;
        new_game_screen.update_sensitivity (solo);

        if (settings.get_int ("num-players") == 2)
            game_type_action.set_state (new Variant.string ("two"));
        else if (settings.get_string ("first-player") == "human")
            game_type_action.set_state (new Variant.string ("human"));
        else
            game_type_action.set_state (new Variant.string ("computer"));

        settings.changed ["opponent"].connect (() => {
                if (settings.get_int ("num-players") != 1)
                    return;
                reset_score = true;
            });
    }

    protected override void activate ()
    {
        window.present ();
    }

    /*\
    * * various
    \*/

    internal void game_reset ()
    {
        stop_anim ();

        window.allow_undo (false);
        window.allow_hint (false);

        one_player_game = Prefs.instance.settings.get_int ("num-players") == 1;
        if (reset_score)
        {
            score = { 0, 0, 0 };
            scorebox.update (score, one_player_game);
            reset_score = false;
        }
        if (one_player_game)
        {
            player = Prefs.instance.settings.get_string ("first-player") == "computer" ? PlayerID.PLAYER2 : PlayerID.PLAYER1;
            Prefs.instance.settings.set_string ("first-player", player == PlayerID.PLAYER1 ? "computer" : "human");
            ai_level = Prefs.instance.settings.get_int ("opponent");
        }
        else
        {
            switch (last_first_player)
            {
                case PlayerID.PLAYER1: player = PlayerID.PLAYER2; break;
                case PlayerID.PLAYER2:
                case PlayerID.NOBODY : player = PlayerID.PLAYER1; break;
            }
            last_first_player = player;
        }

        gameover = true;
        winner = NOBODY;
        column = 3;
        column_moveto = 3;
        row = 0;
        row_dropto = 0;

        clear_board ();
        set_status_message (null);
        game_board_view.queue_draw ();

        move_cursor (column);
        gameover = false;
        prompt_player ();
        if (!is_player_human ())
        {
            vstr [0] = vlevel [ai_level];
            process_move (playgame ((string) vstr) - 1);
        }
    }

    private void blink_winner (int n)   /* blink the winner's line(s) n times */
    {
        if (winner == NOBODY)
            return;

        blink_t = winner;

        if (game_board.is_line_at ((Tile) winner, row, column,
                               out blink_r1, out blink_c1,
                               out blink_r2, out blink_c2))
        {
            anim = AnimID.BLINK;
            blink_on = false;
            blink_n = n;
            var temp = new Animate (0, this);
            timeout = Timeout.add (SPEED_BLINK, temp.exec);
            while (timeout != 0)
                main_iteration ();
        }
    }

    private inline void draw_line (int r1, int c1, int r2, int c2, int tile)
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

        do
        {
            done = (r1 == r2 && c1 == c2);
            game_board[r1, c1] = (Tile) tile;
            game_board_view.draw_tile (r1, c1);
            if (r1 != r2)
                r1 += d_row;
            if (c1 != c2)
                c1 += d_col;
        }
        while (!done);
    }

    private void prompt_player ()
    {
        bool human = is_player_human ();

        window.allow_hint (human && !gameover);

        if (one_player_game)
            window.allow_undo ((human && moves >1) || (!human && gameover));
        else
            window.allow_undo (moves > 0);

        if (gameover && winner == PlayerID.NOBODY)
        {
            if (score [PlayerID.NOBODY] == 0)
                set_status_message (null);
            else
                /* Translators: text displayed on game end in the headerbar/actionbar, if the game is a tie */
                set_status_message (_("It’s a draw!"));
            return;
        }

        if (one_player_game)
        {
            if (human)
            {
                if (gameover)
                    /* Translators: text displayed on a one-player game end in the headerbar/actionbar, if the human player won */
                    set_status_message (_("You win!"));
                else
                    /* Translators: text displayed during a one-player game in the headerbar/actionbar, if it is the human player's turn */
                    set_status_message (_("Your Turn"));
            }
            else
            {
                if (gameover)
                    /* Translators: text displayed on a one-player game end in the headerbar/actionbar, if the computer player won */
                    set_status_message (_("I win!"));
                else
                    /* Translators: text displayed during a one-player game in the headerbar/actionbar, if it is the computer player's turn */
                    set_status_message (_("I’m Thinking…"));
            }
        }
        else
        {
            string who;
            if (gameover)
                who = player == PLAYER1 ? theme_get_player_win (PlayerID.PLAYER1)
                                        : theme_get_player_win (PlayerID.PLAYER2);
            else
                who = player == PLAYER1 ? theme_get_player_turn (PlayerID.PLAYER1)
                                        : theme_get_player_turn (PlayerID.PLAYER2);

            set_status_message (_(who));
        }
    }

    private void swap_player ()
    {
        player = (player == PlayerID.PLAYER1) ? PlayerID.PLAYER2 : PlayerID.PLAYER1;
        move_cursor (3);
        prompt_player ();
    }

    private void process_move3 (int c)
    {
        play_sound (SoundID.DROP);

        vstr [++moves] = '1' + (char) c;
        vstr [moves + 1] = '0';

        check_game_state ();

        if (gameover)
        {
            score [winner]++;
            scorebox.update (score, one_player_game);
            prompt_player ();
        }
        else
        {
            swap_player ();
            if (!is_player_human ())
            {
                vstr [0] = vlevel [ai_level];
                c = playgame ((string) vstr) - 1;
                if (c < 0)
                    gameover = true;
                var nm = new NextMove (c, this);
                Timeout.add (SPEED_DROP, nm.exec);
            }
        }
    }
    private inline void check_game_state ()
    {
        if (game_board.is_line_at ((Tile) player, row, column))
        {
            gameover = true;
            winner = player;
            if (one_player_game)
                play_sound (is_player_human () ? SoundID.YOU_WIN : SoundID.I_WIN);
            else
                play_sound (SoundID.PLAYER_WIN);
            window.allow_hint (false);
            blink_winner (6);
        }
        else if (moves == 42)
        {
            gameover = true;
            winner = NOBODY;
            play_sound (SoundID.DRAWN_GAME);
        }
    }

    private bool is_player_human ()
    {
        if (one_player_game)
            return player == PlayerID.PLAYER1;
        else
            return true;
    }

    private void process_move2 (int c)
    {
        int r = game_board.first_empty_row (c);
        if (r > 0)
        {
            row = 0;
            row_dropto = r;
            anim = AnimID.DROP;
            var temp = new Animate (c, this);
            timeout = Timeout.add (SPEED_DROP, temp.exec);
        }
        else
            play_sound (SoundID.COLUMN_FULL);
    }

    private void process_move (int c)
    {
        if (timeout != 0)
        {
            var temp = new Animate (c, this);
            Timeout.add (SPEED_DROP, temp.exec);
            return;
        }

        column_moveto = c;
        anim = AnimID.MOVE;
        var temp = new Animate (c, this);
        timeout = Timeout.add (SPEED_DROP, temp.exec);
    }

    private inline void drop ()
    {
        Tile tile = player == PLAYER1 ? Tile.PLAYER1 : Tile.PLAYER2;

        game_board [row, column] = Tile.CLEAR;
        game_board_view.draw_tile (row, column);

        row++;
        game_board [row, column] = tile;
        game_board_view.draw_tile (row, column);
    }

    private inline void move (int c)
    {
        game_board [0, column] = Tile.CLEAR;
        game_board_view.draw_tile (0, column);

        column = c;
        game_board [0, c] = player == PlayerID.PLAYER1 ? Tile.PLAYER1 : Tile.PLAYER2;

        game_board_view.draw_tile (0, c);
    }

    private void move_cursor (int c)
    {
        move (c);
        column = column_moveto = c;
        row = row_dropto = 0;
    }

    private void set_status_message (string? message)
    {
        window.set_subtitle (message);
    }

    private class NextMove
    {
        int c;
        FourInARow application;

        internal NextMove (int c, FourInARow application)
        {
            this.c = c;
            this.application = application;
        }

        internal bool exec ()
        {
            application.process_move (c);
            return false;
        }
    }

    private void stop_anim ()
    {
        if (timeout == 0)
            return;
        anim = AnimID.NONE;
        Source.remove (timeout);
        timeout = 0;
    }

    private void clear_board ()
    {
        game_board.clear ();

        for (var i = 0; i < SIZE_VSTR; i++)
            vstr [i] = '\0';

        vstr [0] = vlevel [/* weak */ 1];
        vstr [1] = '0';
        moves = 0;
    }

    private inline void blink_tile (int r, int c, int t, int n)
    {
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
        var temp = new Animate (0, this);
        timeout = Timeout.add (SPEED_BLINK, temp.exec);
    }

    private class Animate
    {
        int c;
        FourInARow application;
        internal Animate (int c, FourInARow application)
        {
            this.c = c;
            this.application = application;
        }

        internal bool exec ()
        {
            switch (anim)
            {
                case AnimID.NONE:
                    return false;

                case AnimID.HINT:
                case AnimID.MOVE:
                    if (application.column < application.column_moveto)
                        application.move (application.column + 1);
                    else if (application.column > application.column_moveto)
                        application.move (application.column - 1);
                    else
                    {
                        application.timeout = 0;
                        if (anim == AnimID.MOVE)
                        {
                            anim = AnimID.NONE;
                            application.process_move2 (c);
                        }
                        else
                            anim = AnimID.NONE;
                        return false;
                    }
                    return true;

                case AnimID.DROP:
                    if (application.row < application.row_dropto)
                        application.drop ();
                    else
                    {
                        anim = AnimID.NONE;
                        application.timeout = 0;
                        application.process_move3 (c);
                        return false;
                    }
                    return true;

                case AnimID.BLINK:
                    application.draw_line (application.blink_r1, application.blink_c1,
                                           application.blink_r2, application.blink_c2,
                                           application.blink_on ? application.blink_t : Tile.CLEAR);
                    application.blink_n--;
                    if (application.blink_n <= 0 && application.blink_on)
                    {
                        anim = AnimID.NONE;
                        application.timeout = 0;
                        return false;
                    }
                    application.blink_on = !application.blink_on;
                    return true;

                default: assert_not_reached ();
            }
        }
    }

    /*\
    * * game window callbacks
    \*/

    private inline void on_game_new ()
    {
        stop_anim ();
        game_reset ();
    }

    private inline void on_game_hint ()
    {
        string s;
        int c;

        if (timeout != 0)
            return;
        if (gameover)
            return;

        window.allow_hint (false);
        window.allow_undo (false);

        /* Translators: text *briefly* displayed in the headerbar/actionbar, when a hint is requested */
        set_status_message (_("I’m Thinking…"));

        vstr [0] = vlevel [/* strong */ 3];
        c = playgame ((string) vstr) - 1;

        column_moveto = c;
        while (timeout != 0)
            main_iteration ();
        anim = AnimID.HINT;
        var temp = new Animate (0, this);
        timeout = Timeout.add (SPEED_MOVE, temp.exec);

        blink_tile (0, c, game_board [0, c], 6);

        /* Translators: text displayed in the headerbar/actionbar, when a hint is requested; the %d is replaced by the number of the suggested column */
        s = _("Hint: Column %d").printf (c + 1);
        set_status_message (s);

        if (moves <= 0 || (moves == 1 && is_player_human ()))
            window.allow_undo (false);
        else
            window.allow_undo (true);
    }

    private inline void on_game_undo ()
    {
        if (timeout != 0)
            return;

        int c = vstr [moves] - '0' - 1;
        int r = game_board.first_empty_row (c) + 1;
        vstr [moves] = '0';
        vstr [moves + 1] = '\0';
        moves--;

        if (gameover)
        {
            score [winner]--;
            scorebox.update (score, one_player_game);
            gameover = false;
            prompt_player ();
        }
        else
            swap_player ();
        move_cursor (c);

        game_board [r, c] = Tile.CLEAR;
        game_board_view.draw_tile (r, c);

        if (one_player_game
         && !is_player_human ()
         && moves > 0)
        {
            c = vstr [moves] - '0' - 1;
            r = game_board.first_empty_row (c) + 1;
            vstr [moves] = '0';
            vstr [moves + 1] = '\0';
            moves--;
            swap_player ();
            move_cursor (c);
            game_board [r, c] = Tile.CLEAR;
            game_board_view.draw_tile (r, c);
        }
    }

    /*\
    * * actions
    \*/

    private SimpleAction game_type_action;
    private void change_game_type (SimpleAction action, Variant? gvariant)
        requires (gvariant != null)
    {
        string type = ((!) gvariant).get_string ();
//        game_type_action.set_state ((!) gvariant);
        switch (type)
        {
            case "human"    : Prefs.instance.settings.set_int    ("num-players", 1); new_game_screen.update_sensitivity (true);
                              Prefs.instance.settings.set_string ("first-player", "human");                                      return;
            case "computer" : Prefs.instance.settings.set_int    ("num-players", 1); new_game_screen.update_sensitivity (true);
                              Prefs.instance.settings.set_string ("first-player", "computer");                                   return;
            case "two"      : Prefs.instance.settings.set_int    ("num-players", 2); new_game_screen.update_sensitivity (false); return;
            default: assert_not_reached ();
        }
    }

    private inline void on_game_scores (/* SimpleAction action, Variant? parameter */)
    {
        scorebox.present ();
        return;
    }

    private inline void on_game_exit (/* SimpleAction action, Variant? parameter */)
    {
        stop_anim ();
        quit ();
    }

    /*\
    * * game interaction
    \*/

    private inline bool on_key_press (Gdk.EventKey e)
    {
        if (timeout != 0
         || (e.keyval != Prefs.instance.keypress_left
          && e.keyval != Prefs.instance.keypress_right
          && e.keyval != Prefs.instance.keypress_drop))
            return false;

        if (gameover)
        {
            blink_winner (2);
            return true;
        }

        if (e.keyval == Prefs.instance.keypress_left && column != 0)
        {
            column_moveto--;
            move_cursor (column_moveto);
        }
        else if (e.keyval == Prefs.instance.keypress_right && column < 6)
        {
            column_moveto++;
            move_cursor (column_moveto);
        }
        else if (e.keyval == Prefs.instance.keypress_drop)
            process_move (column);

        return true;
    }

    private inline bool column_clicked_cb (int column)
    {
        if (gameover && timeout == 0)
            blink_winner (2);
        else if (is_player_human () && timeout == 0)
            process_move (column);
        return true;
    }

    /*\
    * * help and about
    \*/

    private inline void on_help_about (/* SimpleAction action, Variant? parameter */)
    {
        string [] authors = {
            /* Translators: in the About dialog, name of an author of the game */
            _("Tim Musson") + " <trmusson@ihug.co.nz>",


            /* Translators: in the About dialog, name of an author of the game */
            _("David Neary") + " <bolsh@gimp.org>",


            /* Translators: in the About dialog, name of an author of the game */
            _("Nikhar Agrawal") + " <nikharagrawal2006@gmail.com>",


            /* Translators: in the About dialog, name of an author of the game */
            _("Jacob Humphrey") + " <jacob.ryan.humphrey@gmail.com>",


            /* Translators: in the About dialog, name of an author of the game */
            _("Arnaud Bonatti") + " <arnaud.bonatti@gmail.com>"
        };

        string [] artists = {
            /* Translators: in the About dialog, name of a theme designer */
            _("Alan Horkan"),


            /* Translators: in the About dialog, name of a theme designer */
            _("Anatol Drlicek"),


            /* Translators: in the About dialog, indication about some themes origin */
            _("Based on the Faenza icon theme by Matthieu James")
        };

        /* Translators: in the About dialog, name of a documenter */
        string [] documenters = { _("Timothy Musson") };


        /* Translators: text crediting a maintainer, in the about dialog text */
        string copyright = _("Copyright \xc2\xa9 1999-2008 – Tim Musson and David Neary") + "\n"


        /* Translators: text crediting a maintainer, in the about dialog text */
                         + _("Copyright \xc2\xa9 2014 – Michael Catanzaro") + "\n"


        /* Translators: text crediting a maintainer, in the about dialog text */
                         + _("Copyright \xc2\xa9 2018 – Jacob Humphrey") + "\n"


        /* Translators: text crediting a maintainer, in the about dialog text; the %u are replaced with the years of start and end */
                         + _("Copyright \xc2\xa9 %u-%u – Arnaud Bonatti").printf (2019, 2020);

        show_about_dialog (window,
            name: PROGRAM_NAME,
            version: VERSION,
            copyright: copyright,
            license_type: License.GPL_3_0,
            /* Translators: about dialog text, introducing the game */
            comments: _("Connect four in a row to win"),
            authors: authors,
            documenters: documenters,
            artists: artists,
            /* Translators: about dialog text; this string should be replaced by a text crediting yourselves and your translation team, or should be left empty. Do not translate literally! */
            translator_credits: _("translator-credits"),
            logo_icon_name: "org.gnome.Four-in-a-row",
            website: "https://wiki.gnome.org/Apps/Four-in-a-row");
    }

    private inline void on_help_contents (/* SimpleAction action, Variant? parameter */)
    {
        try {
            show_uri_on_window (window, "help:four-in-a-row", get_current_event_time ());
        } catch (Error error) {
            warning ("Failed to show help: %s", error.message);
        }
    }

    /*\
    * * sound
    \*/

    private GSound.Context sound_context;
    private SoundContextState sound_context_state = SoundContextState.INITIAL;

    private enum SoundID {
        DROP,
        I_WIN,
        YOU_WIN,
        PLAYER_WIN,
        DRAWN_GAME,
        COLUMN_FULL;
    }

    private enum SoundContextState {
        INITIAL,
        WORKING,
        ERRORED;
    }

    private inline void init_sound ()
    {
        try {
            sound_context = new GSound.Context ();
            sound_context_state = SoundContextState.WORKING;
        } catch (Error e) {
            warning (e.message);
            sound_context_state = SoundContextState.ERRORED;
        }
    }

    private void play_sound (SoundID id)
    {
        if (Prefs.instance.settings.get_boolean ("sound"))
        {
            if (sound_context_state == SoundContextState.INITIAL)
                init_sound ();
            if (sound_context_state == SoundContextState.WORKING)
                do_play_sound (id, sound_context);
        }
    }

    private static void do_play_sound (SoundID id, GSound.Context sound_context)
    {
        string name;

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

        name += ".ogg";
        string path = Path.build_filename (SOUND_DIRECTORY, name);

        try {
            sound_context.play_simple (null, GSound.Attribute.MEDIA_NAME, name,
                                             GSound.Attribute.MEDIA_FILENAME, path);
        } catch (Error e) {
            warning(e.message);
        }
    }
}

private enum PlayerID {
    PLAYER1 = 0,
    PLAYER2,
    NOBODY;
}

private enum Tile {
    PLAYER1 = 0,
    PLAYER2,
    CLEAR,
    CLEAR_CURSOR,
    PLAYER1_CURSOR,
    PLAYER2_CURSOR;
}
