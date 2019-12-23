/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
   This file is part of GNOME Four-in-a-row.

   Copyright © 2018 Jacob Humphrey

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

private struct Theme
{
    public string title;
    public string fname_tileset;
    public string? fname_bground;
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
 * Cannot reproduce 08/2019, but the bug is not closed (2/2).
 */
private const string theme_gettext_package = GETTEXT_PACKAGE;

private static string theme_get_title (uint8 id)
{
    return _(theme [id].title); // FIXME this gettext call feels horrible
}

private static string theme_get_player_turn (PlayerID who, uint8 theme_id)
{
    if (who == PlayerID.PLAYER1)
        return theme [theme_id].player1_turn;
    else
        return theme [theme_id].player2_turn;
}

private static string theme_get_player_win (PlayerID who, uint8 theme_id)
{
    if (who == PlayerID.PLAYER1)
        return theme [theme_id].player1_win;
    else
        return theme [theme_id].player2_win;
}

private static string theme_get_player (PlayerID who, uint8 theme_id)
{
    if (who == PlayerID.PLAYER1)
        return theme [theme_id].player1;
    else
        return theme [theme_id].player2;
}

private const Theme theme [] = {
    {
        /* Translators: name of a black-on-white theme, for helping people with visual misabilities */
        N_("High Contrast"),
        "tileset_50x50_hcontrast.svg",
        null,
        "#000000",
        N_("Circle"),           N_("Cross"),
        N_("Circle wins!"),     N_("Cross wins!"),
        N_("Circle’s turn"),    N_("Cross’s turn")
    },
    {
        /* Translators: name of a white-on-black theme, for helping people with visual misabilities */
        N_("High Contrast Inverse"),
        "tileset_50x50_hcinverse.svg",
        null,
        "#FFFFFF",
        N_("Circle"),           N_("Cross"),
        N_("Circle wins!"),     N_("Cross wins!"),
        N_("Circle’s turn"),    N_("Cross’s turn")
    },
    {
        /* Translators: name of a red-versus-green theme */
        N_("Red and Green Marbles"),
        "tileset_50x50_faenza-glines-icon1.svg",
        "bg_toplight.png",
        "#727F8C",
        N_("Red"),              N_("Green"),
        N_("Red wins!"),        N_("Green wins!"),
        N_("Red’s turn"),       N_("Green’s turn")
    },
    {
        /* Translators: name of a blue-versus-red theme */
        N_("Blue and Red Marbles"),
        "tileset_50x50_faenza-glines-icon2.svg",
        "bg_toplight.png",
        "#727F8C",
        N_("Blue"),             N_("Red"),
        N_("Blue wins!"),       N_("Red wins!"),
        N_("Blue’s turn"),      N_("Red’s turn")
    },
    {
        /* Translators: name of a red-versus-green theme with drawing on the tiles */
        N_("Stars and Rings"),
        "tileset_50x50_faenza-gnect-icon.svg",
        "bg_toplight.png",
        "#727F8C",
        N_("Red"),              N_("Green"),
        N_("Red wins!"),        N_("Green wins!"),
        N_("Red’s turn"),       N_("Green’s turn")
    }
};
