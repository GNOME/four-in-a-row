/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* theme.vala
 *
 * Four-in-a-row for GNOME
 * Copyright © 2018 Jacob Humphrey
 *
 * This game is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

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

/*
 * Needed to force vala to include headers in the correct order.
 * See https://gitlab.gnome.org/GNOME/vala/issues/98
 */
const string theme_gettext_package = Config.GETTEXT_PACKAGE;

string theme_get_title (int id) {
    return theme[id].title;
}

string theme_get_player_turn (PlayerID who) {
    if (who == PlayerID.PLAYER1)
        return theme[p.theme_id].player1_turn;
    return theme[p.theme_id].player2_turn;
}

string theme_get_player_win (PlayerID who) {
    if (who == PlayerID.PLAYER1)
        return theme[p.theme_id].player1_win;
    return theme[p.theme_id].player2_win;
}

string theme_get_player (PlayerID who) {
    if (who == PlayerID.PLAYER1)
        return theme[p.theme_id].player1;
    return theme[p.theme_id].player2;
}


const Theme theme[] = {
    {
        N_("High Contrast"),
        "tileset_50x50_hcontrast.svg",
        null,
        "#000000",
        N_("Circle"), N_("Cross"),
        N_("Circle wins!"), N_("Cross wins!"),
        N_("Circle’s turn"), N_("Cross’s turn")
    },
    {
        N_("High Contrast Inverse"),
        "tileset_50x50_hcinverse.svg",
        null,
        "#FFFFFF",
        N_("Circle"), N_("Cross"),
        N_("Circle wins!"), N_("Cross wins!"),
        N_("Circle’s turn"), N_("Cross’s turn")
    },
    {
        N_("Red and Green Marbles"),
        "tileset_50x50_faenza-glines-icon1.svg",
        "bg_toplight.png",
        "#727F8C",
        N_("Red"), N_("Green"),
        N_("Red wins!"), N_("Green wins!"),
        N_("Red’s turn"), N_("Green’s turn")
    },
    {
        N_("Blue and Red Marbles"),
        "tileset_50x50_faenza-glines-icon2.svg",
        "bg_toplight.png",
        "#727F8C",
        N_("Blue"), N_("Red"),
        N_("Blue wins!"), N_("Red wins!"),
        N_("Blue’s turn"), N_("Red’s turn")
    },
    {
        N_("Stars and Rings"),
        "tileset_50x50_faenza-gnect-icon.svg",
        "bg_toplight.png",
        "#727F8C",
        N_("Red"), N_("Green"),
        N_("Red wins!"), N_("Green wins!"),
        N_("Red’s turn"), N_("Green’s turn")
    }
};
