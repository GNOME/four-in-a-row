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
    private GLib.Settings settings = new GLib.Settings ("org.gnome.Four-in-a-row");

    /* Translators: application name, as used in the window manager, the window title, the about dialog... */
    private const string PROGRAM_NAME = _("Four-in-a-row");
    private const uint SPEED_BLINK = 150;
    private const uint SPEED_MOVE = 35;
    private const uint SPEED_DROP = 20;
    private const uint COMPUTER_INITIAL_DELAY = 1200;
    private const uint COMPUTER_MOVE_DELAY = 600;

    private enum AnimID {
        NONE,
        MOVE,
        DROP,
        BLINK,
        HINT
    }

    // game status
    private bool gameover = true;
    private Player player = Player.NOBODY;
    private Player winner = Player.NOBODY;
    private Player last_first_player = Player.NOBODY;
    private Board game_board;
    private bool one_player_game;
    private Difficulty ai_level;
    private uint playgame_timeout = 0;

    // widgets
    private Scorebox scorebox;
    private GameBoardView game_board_view;
    private GameWindow window;
    private NewGameScreen new_game_screen;
    private HistoryButton history_button_1;
    private HistoryButton history_button_2;

    // game state
    private string vstr;
    private uint8 moves;
    private uint8 column;
    private uint8 column_moveto;
    private uint8 row;
    private uint8 row_dropto;

    // animation
    private static AnimID anim = AnimID.NONE;
    private uint8 [,] blink_lines = {{}};
    private uint8 blink_line = 0;   // index of currently blinking line in blink_lines
    private Player blink_t = Player.NOBODY;    // garbage
    private uint8 blink_n = 0;
    private bool blink_on = false;
    private uint timeout = 0;

    /* settings */
    [CCode (notify = false)] internal int   keypress_drop   { private get; internal set; }
    [CCode (notify = false)] internal int   keypress_right  { private get; internal set; }
    [CCode (notify = false)] internal int   keypress_left   { private get; internal set; }
    [CCode (notify = false)] internal bool  sound_on        { private get; internal set; }

    private ThemeManager theme_manager;

    private static string? level = null;
    private static int size = 7;
    private static int target = 4;
    private static bool? sound = null;

    private const OptionEntry [] option_entries =
    {
        /* Translators: command-line option description, see 'four-in-a-row --help' */
        { "level", 'l', OptionFlags.NONE, OptionArg.STRING, ref level,          N_("Set the level of the computer’s AI"),

        /* Translators: in the command-line options description, text to indicate the user should specify a level, see 'four-in-a-row --help' */
                                                                                N_("LEVEL") },

        /* Translators: command-line option description, see 'four-in-a-row --help' */
        { "mute", 0, OptionFlags.NONE, OptionArg.NONE, null,                    N_("Turn off the sound"), null },

        /* Translators: command-line option description, see 'four-in-a-row --help' */
        { "size", 's', OptionFlags.NONE, OptionArg.INT, ref size,               N_("Size of the board"),

        /* Translators: in the command-line options description, text to indicate the user should specify a size, see 'four-in-a-row --help' */
                                                                                N_("SIZE") },

        /* Translators: command-line option description, see 'four-in-a-row --help' */
        { "target", 't', OptionFlags.NONE, OptionArg.INT, ref target,           N_("Length of a winning line"),

        /* Translators: in the command-line options description, text to indicate the user should specify the line length, see 'four-in-a-row --help' */
                                                                                N_("TARGET") },

        /* Translators: command-line option description, see 'four-in-a-row --help' */
        { "unmute", 0, OptionFlags.NONE, OptionArg.NONE, null,                  N_("Turn on the sound"), null },

        /* Translators: command-line option description, see 'four-in-a-row --help' */
        { "version", 'v', OptionFlags.NONE, OptionArg.NONE, null,               N_("Print release version and exit"), null },
        {}
    };

    private const GLib.ActionEntry app_entries [] =  // see also add_actions()
    {
        { "game-type",          null,       "s", "'dark'", change_game_type },
     // { "toggle-game-menu",   toggle_game_menu        },
        { "next-round",         on_next_round           },
        { "give-up",            on_give_up              },
        { "scores",             on_game_scores          },
        { "quit",               on_game_exit            },
        { "help",               on_help_contents        },
        { "about",              on_help_about           }
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

        add_main_option_entries (option_entries);
    }

    protected override int handle_local_options (GLib.VariantDict options)
    {
        if (options.contains ("version"))
        {
            /* NOTE: Is not translated so can be easily parsed */
            stdout.printf ("%1$s %2$s\n", "four-in-a-row", VERSION);
            return Posix.EXIT_SUCCESS;
        }

        if (size < 4)
        {
            /* Translators: command-line error message, displayed for an incorrect game size request; try 'four-in-a-row -s 2' */
            stderr.printf ("%s\n", _("Size must be at least 4."));
            return Posix.EXIT_FAILURE;
        }
        if (size > 16)
        {
            /* Translators: command-line error message, displayed for an incorrect game size request; try 'four-in-a-row -s 17' */
            stderr.printf ("%s\n", _("Size must not be more than 16."));
            return Posix.EXIT_FAILURE;
        }

        if (target < 3)
        {
            /* Translators: command-line error message, displayed for an incorrect line length request; try 'four-in-a-row -t 2' */
            stderr.printf ("%s\n", _("Lines must be at least 3 tiles."));
            return Posix.EXIT_FAILURE;
        }
        if (target > size - 1)
        {
            /* Translators: command-line error message, displayed for an incorrect line length request; try 'four-in-a-row -t 8' */
            stderr.printf ("%s\n", _("Lines cannot be longer than board height or width."));
            return Posix.EXIT_FAILURE;
        }

        if (options.contains ("mute"))
            sound = false;
        else if (options.contains ("unmute"))
            sound = true;

        /* Activate */
        return -1;
    }

    protected override void startup ()
    {
        base.startup ();

        if ((sound != null) || (level != null))
        {
            settings.delay ();

            if (sound != null)
                settings.set_boolean ("sound", (!) sound);

            if (level != null)
            {
                // TODO add a localized text option?
                switch ((!) level)
                {
                    case "1":
                    case "easy":
                    case "one":     settings.set_int ("opponent", 1); break;

                    case "2":
                    case "medium":
                    case "two":     settings.set_int ("opponent", 2); break;

                    case "3":
                    case "hard":
                    case "three":   settings.set_int ("opponent", 3); break;

                    default:
                        /* Translators: command-line error message, displayed for an incorrect level request; try 'four-in-a-row -l 5' */
                        stderr.printf ("%s\n", _("Level should be 1 (easy), 2 (medium) or 3 (hard). Settings unchanged."));
                        break;
                }
            }
            settings.apply ();
        }

        game_board = new Board ((uint8) size, (uint8) target);
        clear_board ();

        if (settings.get_boolean ("sound"))
            init_sound ();

        settings.bind ("key-drop",  this,   "keypress-drop",  SettingsBindFlags.GET | SettingsBindFlags.NO_SENSITIVITY);
        settings.bind ("key-right", this,   "keypress-right", SettingsBindFlags.GET | SettingsBindFlags.NO_SENSITIVITY);
        settings.bind ("key-left",  this,   "keypress-left",  SettingsBindFlags.GET | SettingsBindFlags.NO_SENSITIVITY);
        settings.bind ("sound",     this,   "sound-on",       SettingsBindFlags.GET | SettingsBindFlags.NO_SENSITIVITY);

        theme_manager = new ThemeManager ((uint8) size);
        settings.bind ("theme-id", theme_manager, "theme-id", SettingsBindFlags.GET | SettingsBindFlags.NO_SENSITIVITY);

        /* UI parts */
        new_game_screen = new NewGameScreen ();
        new_game_screen.show ();

        game_board_view = new GameBoardView (game_board, theme_manager);
        game_board_view.show ();

        GLib.Menu app_menu = new GLib.Menu ();

        GLib.Menu appearance_menu = new GLib.Menu ();
        string [] themes = theme_manager.get_themes ();
        for (uint8 i = 0; i < themes.length; i++)     // TODO default theme
            appearance_menu.append (themes [i], @"app.theme-id($i)");
        appearance_menu.freeze ();

        GLib.Menu section = new GLib.Menu ();
        /* Translators: hamburger menu entry; "Appearance" submenu (with a mnemonic that appears pressing Alt) */
        section.append_submenu (_("A_ppearance"), (!) appearance_menu);


        /* Translators: hamburger menu entry with checkbox, for activating or disactivating sound (with a mnemonic that appears pressing Alt) */
        section.append (_("_Sound"), "app.sound");
        section.freeze ();
        app_menu.append_section (null, section);

        section = new GLib.Menu ();
        /* Translators: hamburger menu entry; opens the Keyboard Shortcuts dialog (with a mnemonic that appears pressing Alt) */
        section.append (_("_Keyboard Shortcuts"), "win.show-help-overlay");


        /* Translators: hamburger menu entry; opens the application help (with a mnemonic that appears pressing Alt) */
        section.append (_("_Help"), "app.help");


        /* Translators: hamburger menu entry; opens the About dialog (with a mnemonic that appears pressing Alt) */
        section.append (_("_About Four-in-a-row"), "app.about");
        section.freeze ();
        app_menu.append_section (null, section);

        app_menu.freeze ();

        generate_game_menu ();
        history_button_1 = new HistoryButton (ref game_menu, theme_manager);
        history_button_2 = new HistoryButton (ref game_menu, theme_manager);

        /* Window */
        window = new GameWindow ("/org/gnome/Four-in-a-row/ui/four-in-a-row.css",
                                 PROGRAM_NAME,
                                 /* start_now */ true,
                                 GameWindowFlags.SHOW_START_BUTTON,
                                 (Box) new_game_screen,
                                 game_board_view,
                                 app_menu,
                                 (MenuButton) history_button_1,
                                 (MenuButton) history_button_2);

        scorebox = new Scorebox (window, this, theme_manager);

        settings.changed ["theme-id"].connect (prompt_player);

        add_actions ();

        /* various */
        game_board_view.column_clicked.connect (column_clicked_cb);
        init_keyboard ();

        window.play.connect (on_game_new);
        window.undo.connect (on_game_undo);
        window.hint.connect (on_game_hint);

        window.allow_hint (false);
        window.allow_undo (false);

        prompt_player ();
        game_reset (/* reload settings */ true);

        add_window (window);
    }
    private inline void add_actions ()
    {
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
     // set_accels_for_action ("app.toggle-game-menu",  {        "<Primary>F10"     });
     // set_accels_for_action ("app.help",              {                 "F1"      });
     // set_accels_for_action ("app.about",             {          "<Shift>F1"      });

        add_action_entries (app_entries, this);

        game_type_action  = (SimpleAction) lookup_action ("game-type");
        next_round_action = (SimpleAction) lookup_action ("next-round");
        next_round_action.set_enabled (false);

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
                if (solo)
                {
                    new_game_screen.update_sensitivity (true);
                    if (settings.get_string ("first-player") == "human")
                    {
                        game_type_action.set_state (new Variant.string ("human"));
                        last_first_player = Player.HUMAN;
                    }
                    else
                    {
                        game_type_action.set_state (new Variant.string ("computer"));
                        last_first_player = Player.OPPONENT;
                    }
                }
                else
                {
                    new_game_screen.update_sensitivity (false);
                    game_type_action.set_state (new Variant.string ("two"));
                    last_first_player = Player.NOBODY;
                }
            });
        bool solo = settings.get_int ("num-players") == 1;
        new_game_screen.update_sensitivity (solo);
        if (solo)
        {
            new_game_screen.update_sensitivity (true);
            if (settings.get_string ("first-player") == "human")
            {
                game_type_action.set_state (new Variant.string ("human"));
                last_first_player = Player.HUMAN;
            }
            else
            {
                game_type_action.set_state (new Variant.string ("computer"));
                last_first_player = Player.OPPONENT;
            }
        }
        else
        {
            new_game_screen.update_sensitivity (false);
            game_type_action.set_state (new Variant.string ("two"));
            last_first_player = Player.NOBODY;
        }
    }

    protected override void activate ()
    {
        window.present ();
    }

    /*\
    * * various
    \*/

    internal void game_reset (bool reload_settings)
    {
        stop_anim ();
        if (playgame_timeout != 0)
        {
            Source.remove (playgame_timeout);
            playgame_timeout = 0;
        }

        window.allow_undo (false);
        window.allow_hint (false);

        set_gameover (false);

        if (reload_settings)
        {
            one_player_game = settings.get_int ("num-players") == 1;
            scorebox.new_match (one_player_game);

            if (one_player_game)
            {
                player = settings.get_string ("first-player") == "computer" ? Player.OPPONENT : Player.HUMAN;
                // we keep inverting that, because it would be surprising that all people use the "next round" thing
                settings.set_string ("first-player", player == Player.HUMAN ? "computer" : "human");
                switch (settings.get_int ("opponent"))
                {
                    case 1 : ai_level = Difficulty.EASY;    break;
                    case 2 : ai_level = Difficulty.MEDIUM;  break;
                    case 3 : ai_level = Difficulty.HARD;    break;
                    default: assert_not_reached ();
                }
            }
            else
                switch_players ();
        }
        else
            switch_players ();

        winner = NOBODY;
        column = (/* BOARD_COLUMNS */ size % 2 == 0 && get_locale_direction () == TextDirection.LTR) ? /* BOARD_COLUMNS */ (uint8) size / 2 - 1
                                                                                                     : /* BOARD_COLUMNS */ (uint8) size / 2;
        column_moveto = column;
        row = 0;
        row_dropto = 0;

        clear_board ();
        set_status_message (null);
        game_board_view.queue_draw ();

        move_cursor (column);
        prompt_player ();
        if (!is_player_human ())
        {
            playgame_timeout = Timeout.add (COMPUTER_INITIAL_DELAY, () => {
                    uint8 c = AI.playgame ((uint8) size, ai_level, vstr, (uint8) target);
                    if (c >= /* BOARD_COLUMNS */ size) // c could be uint8.MAX if board is full
                        return Source.REMOVE;
                    process_move (c);
                    playgame_timeout = 0;
                    return Source.REMOVE;
                });
        }
    }
    private void switch_players ()
    {
        switch (last_first_player)
        {
            case Player.HUMAN   : player = Player.OPPONENT; break;
            case Player.OPPONENT:
            case Player.NOBODY  : player = Player.HUMAN; break;
        }
        last_first_player = player;
    }

    private void blink_winner (uint8 n)   /* blink the winner's line(s) n times */
     // requires (n < 128)
    {
        if (winner == Player.NOBODY)
            return;

        blink_t = winner;

        if (game_board.is_line_at (winner, row, column, out blink_lines))
        {
            anim = AnimID.BLINK;
            blink_on = false;
            blink_n = 2 * n;
            blink_line = 0;
            var temp = new Animate (0, this, 2 * n);
            timeout = Timeout.add (SPEED_BLINK, temp.exec);
            while (timeout != 0)
                main_iteration ();
        }
    }

    private inline void draw_line (uint8 _r1, uint8 _c1, uint8 _r2, uint8 _c2, Player owner)
    {
        /* draw a line of 'tile' from r1,c1 to r2,c2 */

        bool done = false;
        int8 d_row;
        int8 d_col;

        int8 r1 = (int8) _r1;
        int8 c1 = (int8) _c1;
        int8 r2 = (int8) _r2;
        int8 c2 = (int8) _c2;

        if (r1 < r2)        d_row =  1;
        else if (r1 > r2)   d_row = -1;
        else                d_row =  0;

        if (c1 < c2)        d_col =  1;
        else if (c1 > c2)   d_col = -1;
        else                d_col =  0;

        do
        {
            done = (r1 == r2 && c1 == c2);
            game_board [r1, c1] = owner;
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
        update_round_section (/* menu init */ false);

        if (one_player_game)
            window.allow_undo ((human && moves > 1) || (!human && gameover));
        else
            window.allow_undo (moves > 0);

        if (gameover && winner == Player.NOBODY)
        {
            if (scorebox.is_first_game ())
                set_status_message (null);
            else
                /* Translators: text displayed on game end in the headerbar/actionbar, if the game is a tie */
                set_status_message (_("It’s a draw!"));
            history_button_1.set_player (Player.NOBODY);
            history_button_2.set_player (Player.NOBODY);
            return;
        }

        if (one_player_game)
        {
            if (gameover)
            {
                history_button_1.set_player (Player.NOBODY);
                history_button_2.set_player (Player.NOBODY);
                if (human)
                    /* Translators: text displayed on a one-player game end in the headerbar/actionbar, if the human player won */
                    set_status_message (_("You win!"));
                else
                    /* Translators: text displayed on a one-player game end in the headerbar/actionbar, if the computer player won */
                    set_status_message (_("I win!"));
            }
            else
            {
                if (human)
                {
                    history_button_1.set_player (Player.HUMAN);
                    history_button_2.set_player (Player.HUMAN);
                    /* Translators: text displayed during a one-player game in the headerbar/actionbar, if it is the human player's turn */
                    set_status_message (_("Your Turn"));
                }
                else
                {
                    history_button_1.set_player (Player.OPPONENT);
                    history_button_2.set_player (Player.OPPONENT);
                    /* Translators: text displayed during a one-player game in the headerbar/actionbar, if it is the computer player's turn */
                    set_status_message (_("I’m Thinking…"));
                }
            }
        }
        else
        {
            string who;
            if (gameover)
            {
                history_button_1.set_player (Player.NOBODY);
                history_button_2.set_player (Player.NOBODY);
                who = theme_manager.get_player_win (player);
            }
            else
            {
                // player can be NOBODY
                Player current_player = player == HUMAN ? Player.HUMAN : Player.OPPONENT;
                history_button_1.set_player (current_player);
                history_button_2.set_player (current_player);
                who = theme_manager.get_player_turn (current_player);
            }

            set_status_message (_(who));
        }
    }

    private void swap_player ()
    {
        player = (player == Player.HUMAN) ? Player.OPPONENT : Player.HUMAN;
        move_cursor (3);
        prompt_player ();
    }

    private void process_move3 (uint8 c)
    {
        play_sound (SoundID.DROP);

        vstr += (c + 1).to_string ();
        moves++;

        check_game_state ();

        if (gameover)
        {
            scorebox.win (winner);
            prompt_player ();
            if (winner != Player.NOBODY)
                blink_winner (3);
        }
        else
        {
            swap_player ();
            if (!is_player_human ())
            {
                playgame_timeout = Timeout.add (COMPUTER_MOVE_DELAY, () => {
                        uint8 col = AI.playgame ((uint8) size, ai_level, vstr, (uint8) target);
                        if (col >= /* BOARD_COLUMNS */ size)   // c could be uint8.MAX if the board is full
                            set_gameover (true);
                        var nm = new NextMove (col, this);
                        Timeout.add (SPEED_DROP, nm.exec);
                        playgame_timeout = 0;
                        return Source.REMOVE;
                    });
            }
        }
    }
    private inline void check_game_state ()
    {
        if (game_board.is_line_at (player, row, column))
        {
            set_gameover (true);
            winner = player;
            if (one_player_game)
                play_sound (is_player_human () ? SoundID.YOU_WIN : SoundID.I_WIN);
            else
                play_sound (SoundID.PLAYER_WIN);
            window.allow_hint (false);
        }
        else if (moves == /* BOARD_ROWS */ (size - 1) * /* BOARD_COLUMNS */ size)
        {
            set_gameover (true);
            winner = NOBODY;
            play_sound (SoundID.DRAWN_GAME);
        }
    }

    private bool is_player_human ()
    {
        if (one_player_game)
            return player == Player.HUMAN;
        else
            return true;
    }

    private void process_move2 (uint8 c)
    {
        uint8 r = game_board.first_empty_row (c);
        if (r != 0)
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

    private void process_move (uint8 c)
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
        Player tile = player == Player.HUMAN ? Player.HUMAN : Player.OPPONENT;

        game_board [row, column] = Player.NOBODY;
        game_board_view.draw_tile (row, column);

        row++;
        game_board [row, column] = tile;
        game_board_view.draw_tile (row, column);
    }

    private inline void move (uint8 c)
    {
        game_board [0, column] = Player.NOBODY;
        game_board_view.draw_tile (0, column);

        column = c;
        game_board [0, c] = player == Player.HUMAN ? Player.HUMAN : Player.OPPONENT;

        game_board_view.draw_tile (0, c);
    }

    private void move_cursor (uint8 c)
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
        private uint8 c;
        private FourInARow application;

        internal NextMove (uint8 c, FourInARow application)
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
        moves = 0;
        vstr = "";
    }

    private inline void blink_tile (uint8 row, uint8 col, Player tile, uint8 n)
    {
        if (timeout != 0)
            return;
        blink_lines = {{ row, col, row, col }};
        blink_line = 0;
        blink_t = tile;
        blink_n = 2 * n;
        blink_on = false;
        anim = AnimID.BLINK;
        var temp = new Animate (0, this, 2 * n);
        timeout = Timeout.add (SPEED_BLINK, temp.exec);
    }

    private class Animate
    {
        private uint8 c;
        private FourInARow application;
        private uint8 blink_n_times;

        internal Animate (uint8 c, FourInARow application, uint8 blink_n_times = 0)
        {
            this.c = c;
            this.application = application;
            this.blink_n_times = blink_n_times;
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
                    application.draw_line (/* row 1 */ application.blink_lines [application.blink_line, 0],
                                           /* col 1 */ application.blink_lines [application.blink_line, 1],
                                           /* row 2 */ application.blink_lines [application.blink_line, 2],
                                           /* col 2 */ application.blink_lines [application.blink_line, 3],
                                           /* tile */  application.blink_on ? application.blink_t : Player.NOBODY);
                    application.blink_n--;
                    if (application.blink_n == 0 && application.blink_on)
                    {
                        if (application.blink_line >= application.blink_lines.length [0] - 1)
                        {
                            anim = AnimID.NONE;
                            application.timeout = 0;
                            return false;
                        }
                        else
                        {
                            application.blink_line++;
                            application.blink_n += blink_n_times;
                        }
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
        game_reset (/* reload settings */ true);
    }

    private inline void on_game_hint ()
    {
        if (timeout != 0)
            return;
        if (gameover)
            return;

        window.allow_hint (false);
        window.allow_undo (false);

        /* Translators: text *briefly* displayed in the headerbar/actionbar, when a hint is requested */
        set_status_message (_("I’m Thinking…"));

        uint8 c = AI.playgame ((uint8) size, Difficulty.HARD, vstr, (uint8) target);
        if (c >= /* BOARD_COLUMNS */ size)
            assert_not_reached ();  // c could be uint8.MAX if the board if full

        column_moveto = c;
        while (timeout != 0)
            main_iteration ();
        anim = AnimID.HINT;
        var temp = new Animate (0, this);
        timeout = Timeout.add (SPEED_MOVE, temp.exec);

        blink_tile (0, c, game_board [0, c], /* blink n times */ 3);

        /* Translators: text displayed in the headerbar/actionbar, when a hint is requested; the %d is replaced by the number of the suggested column */
        set_status_message (_("Hint: Column %d").printf (c + 1));

        if (moves <= 0 || (moves == 1 && is_player_human ()))
            window.allow_undo (false);
        else
            window.allow_undo (true);
    }

    private inline void on_game_undo ()
    {
        if (timeout != 0)
            return;

        moves--;
        uint8 c = (uint8) int.parse (vstr [moves].to_string ()) /* string indicates columns between 1 and BOARD_COLUMNS */ - 1;
        uint8 r = game_board.first_empty_row (c) + 1;
        vstr = vstr [0:moves];

        if (gameover)
        {
            scorebox.unwin ();
            set_gameover (false);
            prompt_player ();
        }
        else
            swap_player ();
        move_cursor (c);

        game_board [r, c] = Player.NOBODY;
        game_board_view.draw_tile (r, c);

        if (one_player_game
         && !is_player_human ()
         && moves > 0)
        {
            moves--;
            c = (uint8) int.parse (vstr [moves].to_string ()) /* string indicates columns between 1 and BOARD_COLUMNS */ - 1;
            r = game_board.first_empty_row (c) + 1;
            vstr = vstr [0:moves];
            swap_player ();
            move_cursor (c);
            game_board [r, c] = Player.NOBODY;
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
            case "human"    : settings.set_int      ("num-players", 1); new_game_screen.update_sensitivity (true);
                              settings.set_string   ("first-player", "human");                                      return;
            case "computer" : settings.set_int      ("num-players", 1); new_game_screen.update_sensitivity (true);
                              settings.set_string   ("first-player", "computer");                                   return;
            case "two"      : settings.set_int      ("num-players", 2); new_game_screen.update_sensitivity (false); return;
            default: assert_not_reached ();
        }
    }

    private SimpleAction next_round_action;
    private void set_gameover (bool new_value)
    {
        gameover = new_value;
        next_round_action.set_enabled (new_value);
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

    // for keeping in memory
    private EventControllerKey window_key_controller;
    private EventControllerKey board_key_controller;

    private inline void init_keyboard ()
    {
        window_key_controller = new EventControllerKey (window);
        window_key_controller.set_propagation_phase (PropagationPhase.CAPTURE);
        window_key_controller.key_pressed.connect (on_window_key_pressed);

        board_key_controller = new EventControllerKey (game_board_view);
        board_key_controller.key_pressed.connect (on_board_key_pressed);
    }

    private inline bool on_window_key_pressed (EventControllerKey _window_key_controller, uint keyval, uint keycode, Gdk.ModifierType state)
    {
        string name = (!) (Gdk.keyval_name (keyval) ?? "");

        if (name == "F1") // TODO fix dance done with the F1 & <Primary>F1 shortcuts that show help overlay
        {
            window.close_hamburger ();
            history_button_1.active = false;
            history_button_2.active = false;
            if ((state & Gdk.ModifierType.CONTROL_MASK) != 0)
                return false;                           // help overlay
            if ((state & Gdk.ModifierType.SHIFT_MASK) != 0)
            {
                on_help_about ();
                return true;
            }
            on_help_contents ();
            return true;
        }
        if (name == "F10") // TODO fix this dance also
        {
            if ((state & Gdk.ModifierType.CONTROL_MASK) != 0)
            {
                toggle_game_menu ();
                return true;
            }
            return false;   // ui.toggle-hamburger
        }
        return false;
    }

    private inline bool on_board_key_pressed (EventControllerKey _board_key_controller, uint keyval, uint keycode, Gdk.ModifierType state)
    {
        Gdk.Event? event = Gtk.get_current_event ();
        bool is_modifier;
        if (event != null && ((!) event).type == Gdk.EventType.KEY_PRESS)
            is_modifier = ((Gdk.EventKey) (!) event).is_modifier == 1;
        else    // ?
            is_modifier = false;

        string key = (!) (Gdk.keyval_name (keyval) ?? "");
        if (key == "" || key == "Tab" || is_modifier)
            return false;

        if (timeout != 0
         || (!gameover && !is_player_human ()))
            return true;

        if (gameover)
        {
            blink_winner (2);
            return true;
        }

        if (key == "Left" || keyval == keypress_left)
        {
            if (column == 0)
                return true;
            column_moveto--;
            move_cursor (column_moveto);
        }
        else if (key == "Right" || keyval == keypress_right)
        {
            if (column >= /* BOARD_COLUMNS_MINUS_ONE */ size - 1)
                return true;
            column_moveto++;
            move_cursor (column_moveto);
        }
        else if (key == "space" || key == "Return" || key == "KP_Enter" || key == "Down" || keyval == keypress_drop)
            process_move (column);
        else if (key == "1" || key == "2" || key == "3" || key == "4" || key == "5" || key == "6" || key == "7")
            process_move ((uint8) int.parse (key) - 1);

        return true;
    }

    private inline bool column_clicked_cb (uint8 column)
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
        try
        {
            show_uri_on_window (window, "help:four-in-a-row", get_current_event_time ());
        }
        catch (Error error)
        {
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
        try
        {
            sound_context = new GSound.Context ();
            sound_context_state = SoundContextState.WORKING;
        }
        catch (Error e)
        {
            warning (e.message);
            sound_context_state = SoundContextState.ERRORED;
        }
    }

    private void play_sound (SoundID id)
    {
        if (sound_on)
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

        switch (id)
        {
            case SoundID.DROP:          name = "slide";     break;
            case SoundID.I_WIN:         name = "reverse";   break;
            case SoundID.YOU_WIN:       name = "bonus";     break;
            case SoundID.PLAYER_WIN:    name = "bonus";     break;
            case SoundID.DRAWN_GAME:    name = "reverse";   break;
            case SoundID.COLUMN_FULL:   name = "bad";       break;
            default: assert_not_reached ();
        }

        name += ".ogg";
        string path = Path.build_filename (SOUND_DIRECTORY, name);

        try {
            sound_context.play_simple (null, GSound.Attribute.MEDIA_NAME, name,
                                             GSound.Attribute.MEDIA_FILENAME, path);
        } catch (Error e) {
            warning (e.message);
        }
    }

    /*\
    * * game menu
    \*/

    private GLib.Menu game_menu = new GLib.Menu ();
    private GLib.Menu round_section = new GLib.Menu ();

    private inline void generate_game_menu ()
    {
        GLib.Menu section = new GLib.Menu ();
        /* Translators: during a game, entry in the game menu, for undoing the last move */
        section.append (_("_Undo last move"), "ui.undo");


        /* Translators: during a game, entry in the game menu, for suggesting where to play */
        section.append (_("_Hint"), "ui.hint");
        section.freeze ();
        game_menu.append_section (null, section);

        update_round_section (/* menu init */ true);
        game_menu.append_section (null, round_section);
    }

    private void update_round_section (bool menu_init)
    {
        round_section.remove_all ();
        if (gameover)
            round_section.append (_("Next _Round"), "app.next-round");
        else
            round_section.append (_("_Give Up"), "app.give-up");

        if (menu_init || scorebox.is_first_game ())
            return;
        /* Translators: hamburger menu entry; opens the Scores dialog (with a mnemonic that appears pressing Alt) */
        round_section.append (_("_Scores"), "app.scores");
    }

    private inline void on_give_up (/* SimpleAction action, Variant? parameter */)
    {
        scorebox.give_up (player);
        game_reset (/* reload settings */ false);
    }

    private inline void on_next_round (/* SimpleAction action, Variant? parameter */)
    {
        game_reset (/* reload settings */ false);
    }

    private inline void toggle_game_menu ()
    {
        if (window.new_game_screen_visible ())
            return;
        window.close_hamburger ();
        if (window.is_extra_thin)
            history_button_2.active = !history_button_2.active;
        else
            history_button_1.active = !history_button_1.active;
    }
}
