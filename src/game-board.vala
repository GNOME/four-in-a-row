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

private class Board : Object {
    private static Tile[,] gboard;
    private const int BOARD_SIZE = 7;

    internal Board() {
        gboard = new Tile[BOARD_SIZE, BOARD_SIZE];
    }

    internal new void @set(int x, int y, Tile tile) {
        gboard[x, y] = tile;
    }

    internal new Tile @get(int x, int y) {
        return gboard[x, y];
    }

    internal void clear() {
        for (int r = 0; r < BOARD_SIZE; r++) {
            for (int c = 0; c < BOARD_SIZE; c++) {
                gboard[r, c] = Tile.CLEAR;
            }
        }
    }

    internal int first_empty_row(int c) {
        int r = 1;

        while (r < BOARD_SIZE && gboard[r, c] == Tile.CLEAR)
            r++;
        return r - 1;
    }

    /*\
    * * check if there is a line passing by a given point
    \*/

    internal bool is_line_at(Tile tile, int row, int col, out int [,] lines = null) {
        uint8 n_lines = 0;
        int [,] lines_tmp = new int [4, 4];

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

        lines = new int [n_lines, 4];
        for (int x = 0; x < n_lines; x++)
            for (int y = 0; y < 4; y++)
                lines [x, y] = lines_tmp [x, y];
        return n_lines != 0;
    }

    private inline bool is_hline_at(Tile p, int r, int c,
                                    out int r1, out int c1,
                                    out int r2, out int c2) {
        r1 = r;
        r2 = r;
        c1 = c;
        c2 = c;
        while (c1 > 0 && gboard[r, c1 - 1] == p)
            c1 = c1 - 1;
        while (c2 < 6 && gboard[r, c2 + 1] == p)
            c2 = c2 + 1;
        if (c2 - c1 >= 3)
            return true;
        return false;
    }

    private inline bool is_vline_at(Tile p, int r, int c,
                                    out int r1 , out int c1,
                                    out int r2, out int c2) {
        r1 = r;
        r2 = r;
        c1 = c;
        c2 = c;
        while (r1 > 1 && @get(r1 - 1, c) == p)
            r1 = r1 - 1;
        while (r2 < 6 && @get(r2 + 1, c) == p)
            r2 = r2 + 1;
        if (r2 - r1 >= 3)
            return true;
        return false;
    }

    private inline bool is_dline1_at(Tile p, int r, int c,
                                     out int r1, out int c1,
                                     out int r2, out int c2) {
        /* upper left to lower right */
        r1 = r;
        r2 = r;
        c1 = c;
        c2 = c;
        while (c1 > 0 && r1 > 1 && @get(r1 - 1, c1 - 1) == p) {
            r1 = r1 - 1;
            c1 = c1 - 1;
        }
        while (c2 < 6 && r2 < 6 && @get(r2 + 1, c2 + 1) == p) {
            r2 = r2 + 1;
            c2 = c2 + 1;
        }
        if (r2 - r1 >= 3)
            return true;
        return false;
    }

    private inline bool is_dline2_at(Tile p, int r, int c,
                                     out int r1, out int c1,
                                     out int r2, out int c2) {
        /* upper right to lower left */
        r1 = r;
        r2 = r;
        c1 = c;
        c2 = c;
        while (c1 < 6 && r1 > 1 && @get(r1 - 1, c1 + 1) == p) {
            r1 = r1 - 1;
            c1 = c1 + 1;
        }
        while (c2 > 0 && r2 < 6 && @get(r2 + 1, c2 - 1) == p) {
            r2 = r2 + 1;
            c2 = c2 - 1;
        }
        if (r2 - r1 >= 3)
            return true;
        return false;
    }
}
