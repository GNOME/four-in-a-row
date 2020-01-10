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

private class Board : Object
{
    [CCode (notify = false)] public uint8 line { internal get; protected construct; default = 4; }
    [CCode (notify = false)] public uint8 size { internal get; protected construct; default = 7; }

    private static Player [,] gboard;

    construct
    {
        gboard = new Player [/* BOARD_COLUMNS */ size, /* BOARD_ROWS_PLUS_ONE */ size];
    }

    internal Board (uint8 size, uint8 line)
    {
        Object (size: size, line: line);
    }

    internal new void @set (uint8 x, uint8 y, Player tile)
    {
        gboard [x, y] = tile;
    }

    internal new Player @get (uint8 x, uint8 y)
    {
        return gboard [x, y];
    }

    internal void clear ()
    {
        for (uint8 row = 0; row < /* BOARD_ROWS_PLUS_ONE */ size; row++)
            for (uint8 col = 0; col < /* BOARD_COLUMNS */ size; col++)
                gboard [row, col] = Player.NOBODY;
    }

    internal uint8 first_empty_row (uint8 col)
    {
        uint8 row = 1;

        while (row < /* BOARD_ROWS_PLUS_ONE */ size && gboard [row, col] == Player.NOBODY)
            row++;
        return row - 1;
    }

    /*\
    * * check if there is a line passing by a given point
    \*/

    internal bool is_line_at (Player tile, uint8 row, uint8 col, out uint8 [,] lines = null)
    {
        uint8 n_lines = 0;
        uint8 [,] lines_tmp = new uint8 [4, 4];

        if (is_hline_at (tile, row, col, out lines_tmp [0, 0],
                                         out lines_tmp [0, 1],
                                         out lines_tmp [0, 2],
                                         out lines_tmp [0, 3]))
            n_lines++;
        if (is_vline_at (tile, row, col, out lines_tmp [n_lines, 0],
                                         out lines_tmp [n_lines, 1],
                                         out lines_tmp [n_lines, 2],
                                         out lines_tmp [n_lines, 3]))
            n_lines++;
        if (is_dline1_at(tile, row, col, out lines_tmp [n_lines, 0],
                                         out lines_tmp [n_lines, 1],
                                         out lines_tmp [n_lines, 2],
                                         out lines_tmp [n_lines, 3]))
            n_lines++;
        if (is_dline2_at(tile, row, col, out lines_tmp [n_lines, 0],
                                         out lines_tmp [n_lines, 1],
                                         out lines_tmp [n_lines, 2],
                                         out lines_tmp [n_lines, 3]))
            n_lines++;

        lines = new uint8 [n_lines, 4];
        for (uint8 x = 0; x < n_lines; x++)
            for (uint8 y = 0; y < 4; y++)
                lines [x, y] = lines_tmp [x, y];
        return n_lines != 0;
    }

    private inline bool is_hline_at (Player tile,     uint8 row,       uint8 col,
                                                  out uint8 row_1, out uint8 col_1,
                                                  out uint8 row_2, out uint8 col_2)
    {
        row_1 = row;
        row_2 = row;
        col_1 = col;
        col_2 = col;
        while (col_1 > 0 && gboard [row, col_1 - 1] == tile)
            col_1 = col_1 - 1;
        while (col_2 < /* BOARD_ROWS */ size - 1 && gboard [row, col_2 + 1] == tile)
            col_2 = col_2 + 1;
        return col_2 - col_1 >= line - 1;
    }

    private inline bool is_vline_at (Player tile,     uint8 row,       uint8 col,
                                                  out uint8 row_1, out uint8 col_1,
                                                  out uint8 row_2, out uint8 col_2)
    {
        row_1 = row;
        row_2 = row;
        col_1 = col;
        col_2 = col;
        while (row_1 > 1 && gboard [row_1 - 1, col] == tile)
            row_1 = row_1 - 1;
        while (row_2 < /* BOARD_ROWS */ size - 1 && gboard [row_2 + 1, col] == tile)
            row_2 = row_2 + 1;
        return row_2 - row_1 >= line - 1;
    }

    private inline bool is_dline1_at (Player tile,     uint8 row,       uint8 col,
                                                   out uint8 row_1, out uint8 col_1,
                                                   out uint8 row_2, out uint8 col_2)
    {
        /* upper left to lower right */
        row_1 = row;
        row_2 = row;
        col_1 = col;
        col_2 = col;
        while (col_1 > 0 && row_1 > 1 && gboard [row_1 - 1, col_1 - 1] == tile)
        {
            row_1 = row_1 - 1;
            col_1 = col_1 - 1;
        }
        while (col_2 < /* BOARD_COLUMNS_MINUS_ONE */ size - 1 && row_2 < /* BOARD_ROWS */ size - 1 && gboard [row_2 + 1, col_2 + 1] == tile)
        {
            row_2 = row_2 + 1;
            col_2 = col_2 + 1;
        }
        return row_2 - row_1 >= line - 1;
    }

    private inline bool is_dline2_at (Player tile,     uint8 row,       uint8 col,
                                                   out uint8 row_1, out uint8 col_1,
                                                   out uint8 row_2, out uint8 col_2)
    {
        /* upper right to lower left */
        row_1 = row;
        row_2 = row;
        col_1 = col;
        col_2 = col;
        while (col_1 < /* BOARD_COLUMNS_MINUS_ONE */ size - 1 && row_1 > 1 && gboard [row_1 - 1, col_1 + 1] == tile)
        {
            row_1 = row_1 - 1;
            col_1 = col_1 + 1;
        }
        while (col_2 > 0 && row_2 < /* BOARD_ROWS */ size - 1 && gboard [row_2 + 1, col_2 - 1] == tile)
        {
            row_2 = row_2 + 1;
            col_2 = col_2 - 1;
        }
        return row_2 - row_1 >= line - 1;
    }
}
