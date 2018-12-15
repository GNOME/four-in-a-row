/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* game_board.vala
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

class Board : Object {
    static Tile[,] gboard;
    const int BOARD_SIZE = 7;
    static Once<Board> _instance;
    public static Board instance {
        get {
            return _instance.once(() => {return new Board();});
        }
    }

    public Board() {
        gboard = new Tile[BOARD_SIZE, BOARD_SIZE];
    }

    public new void @set(int x, int y, Tile tile) {
        gboard[x,y] = tile;
    }

	public new Tile @get(int x, int y) {
        return gboard[x, y];
    }

    public void clear() {
        for (var r = 0; r < BOARD_SIZE; r++) {
            for (var c = 0; c < BOARD_SIZE; c++) {
                gboard[r, c] = Tile.CLEAR;
            }
        }
    }

    public int first_empty_row(int c) {
        int r = 1;

        while (r < BOARD_SIZE && gboard[r, c] == Tile.CLEAR)
            r++;
        return r - 1;
    }

    bool is_hline_at(Tile p, int r, int c, out int r1, out int c1, out int r2, out int c2) {
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

    public bool is_line_at(Tile p, int r, int c, out int r1 = null,
                           out int c1 = null, out int r2 = null, out int c2 = null) {
        return is_hline_at(p, r, c, out r1, out c1, out r2, out c2) ||
            is_vline_at(p, r, c, out r1, out c1, out r2, out c2) ||
            is_dline1_at(p, r, c, out r1, out c1, out r2, out c2) ||
            is_dline2_at(p, r, c, out r1, out c1, out r2, out c2);
    }

    bool is_vline_at(Tile p, int r, int c, out int r1 , out int c1, out int r2, out int c2) {
        r1 = r;
        r2 = r;
        c1 = c;
        c2 = c;
        while (r1 > 1 && get(r1 - 1, c) == p)
            r1 = r1 - 1;
        while (r2 < 6 && get(r2 + 1, c) == p)
            r2 = r2 + 1;
        if (r2 - r1 >= 3)
            return true;
        return false;
    }

    bool is_dline1_at(Tile p, int r, int c, out int r1, out int c1, out int r2, out int c2) {
        /* upper left to lower right */
        r1 = r;
        r2 = r;
        c1 = c;
        c2 = c;
        while (c1 > 0 && r1 > 1 && get(r1 - 1, c1 - 1) == p) {
            r1 = r1 - 1;
            c1 = c1 - 1;
        }
        while (c2 < 6 && r2 < 6 && get(r2 + 1, c2 + 1) == p) {
            r2 = r2 + 1;
            c2 = c2 + 1;
        }
        if (r2 - r1 >= 3)
            return true;
        return false;
    }

    bool is_dline2_at(Tile p, int r, int c, out int r1, out int c1, out int r2, out int c2) {
        /* upper right to lower left */
        r1 = r;
        r2 = r;
        c1 = c;
        c2 = c;
        while (c1 < 6 && r1 > 1 && get(r1 - 1, c1 + 1) == p) {
            r1 = r1 - 1;
            c1 = c1 + 1;
        }
        while (c2 > 0 && r2 < 6 && get(r2 + 1, c2 - 1) == p) {
            r2 = r2 + 1;
            c2 = c2 - 1;
        }
        if (r2 - r1 >= 3)
            return true;
        return false;
    }
}
