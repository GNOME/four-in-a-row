/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
   This file is part of GNOME Four-in-a-row.

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

// private const uint8 BOARD_COLUMNS = 7;
// private const uint8 BOARD_COLUMNS_MINUS_ONE = 6;
// private const uint8 BOARD_ROWS = 6;
// private const uint8 BOARD_ROWS_PLUS_ONE = 7;
// private const uint8 BOARD_SIZE = 7; // as long as that is needed, impossible to have n_rows != n_cols - 1

private enum Player
{
    NOBODY,
    HUMAN,
    OPPONENT;
}

private enum Difficulty
{
    EASY,
    MEDIUM,
    HARD;
}
