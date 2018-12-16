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

public enum SoundID {
    DROP,
    I_WIN,
    YOU_WIN,
    PLAYER_WIN,
    DRAWN_GAME,
    COLUMN_FULL
}

public int main(string[] argv) {
    Intl.setlocale();

    var application = new FourInARow();

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

    Environment.set_application_name(_(APPNAME_LONG));

    application.game_init();

    var app_retval = application.run(argv);

    return app_retval;
}


