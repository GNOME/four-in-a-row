/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
   This file is part of GNOME Four-in-a-row.

   Copyright © 2014 Nikhar Agrawal

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

namespace AI
{
    /* Here NEGATIVE_INFINITY is supposed to be the lowest possible value.
       Do not forget int16.MIN ≠ - int16.MAX. */
    private const int16 POSITIVE_INFINITY           =  32000;
    private const int16 NEGATIVE_INFINITY           = -32000;
    private const int16 LESS_THAN_NEGATIVE_INFINITY = -32001;
    /* MAX_HEURIST_VALUE is the maximum value that the heuristic functions can return.
       It is returned when AI wins, and -1 * MAX_HEURIST_VALUE is returned when Human wins.
       MAX_HEURIST_VALUE < NEGATIVE_INFINITY/plies[level], as we balance results depending on depth */
    private const int16 MAX_HEURIST_VALUE           =   3200;
    /* Use plies [level]; EASY/MEDIUM/HARD */
    private const uint8 [] plies = { 4, 7, 7 };

    /*\
    * * internal methods
    \*/

    /* returns the column number in which the next move has to be made. Returns uint8.MAX if the board is full. */
    internal static uint8 playgame (uint8 size, Difficulty level, string vstr, uint8 line = 4)
    {
        Player [,] board;
        init_board_from_string (size, vstr, out board);

        /* if AI can win by making a move immediately, make that move */
        uint8 temp = immediate_win (Player.OPPONENT, line, ref board);
        if (temp < size)
            return temp;

        /* if HUMAN can win by making a move immediately,
           we make AI move in that column so as avoid loss */
        temp = immediate_win (Player.HUMAN, line, ref board);
        if (temp < size)
            return temp;

        /* call negamax tree on the current state of the board */
        uint8 next_move_in_column = uint8.MAX;
        negamax (plies [level], NEGATIVE_INFINITY, POSITIVE_INFINITY, Player.OPPONENT, level, line, ref board, ref next_move_in_column);

        /* return the column number in which next move should be made */
        return next_move_in_column;
    }

    /* utility function for testing purposes */
    internal static uint8 playandcheck (uint8 size, Difficulty level, string vstr, uint8 line = 4)
    {
        Player [,] board;
        init_board_from_string (size, vstr, out board);

        uint8 temp = immediate_win (Player.OPPONENT, line, ref board);
        if (temp < size)
            return 100;

        temp = immediate_win (Player.HUMAN, line, ref board);
        if (temp < size)
            return temp;

        /* call negamax tree on the current state of the board */
        uint8 next_move_in_column = uint8.MAX;
        negamax (plies [level], NEGATIVE_INFINITY, POSITIVE_INFINITY, Player.OPPONENT, level, line, ref board, ref next_move_in_column);

        return next_move_in_column;
    }

    /*\
    * * setting defaults
    \*/

    /* vstr is the sequence of moves made until now;  */
    private static void init_board_from_string (uint8 size, string vstr, out Player [,] board)
    {
        uint8 n_rows = size - 1;
        uint8 n_cols = size;
        /* empty board */
        board = new Player [n_rows, n_cols];
        for (uint8 i = 0; i < n_rows; i++)
            for (uint8 j = 0; j < n_cols; j++)
                board [i, j] = Player.NOBODY;

        /* AI will make the first move */
        if (vstr == "")
            return;

        /* update board from current string */
        update_board (vstr, ref board);
    }

    private static inline void update_board (string vstr, ref Player [,] board)
    {
        uint8 n_rows = (uint8) board.length [0];
        Player move = vstr.length % 2 == 0 ? Player.OPPONENT : Player.HUMAN;

        for (uint8 i = 0; i < vstr.length; i++)
        {
            uint8 column = (uint8) int.parse (vstr [i].to_string ()) - 1;

            /* find the cell on which the move is made */
            int8 row;
            for (row = n_rows - 1; row >= 0 && board [row, column] != Player.NOBODY; row--);

            board [row, column] = move;

            move = move == Player.HUMAN ? Player.OPPONENT : Player.HUMAN;
        }
    }

    /*\
    * * negamax
    \*/

    /* Recursively implements a negamax tree in memory with alpha-beta pruning. The function is first called for the root node.
       It returns the value of the current node. For nodes at height == 0, the value is determined by a heuristic function. */
    private static int16 negamax (uint8 height, int16 alpha, int16 beta, Player player, Difficulty level, uint8 line, ref Player [,] board, ref uint8 next_move_in_column)
    {
        uint8 n_cols = (uint8) board.length [1];
        /* base case of recursive function, returns if we have reached the lowest depth of DecisionTree or the board if full */
        if (height == 0 || board_full (ref board))
        {
            if (player == Player.OPPONENT)
                return heurist (level, line, ref board);
            else if (player == Player.HUMAN)
                return -1 * heurist (level, line, ref board);
            else
                assert_not_reached ();  // do not call AI on a full board, please
        }

        /* Local variable that stores the maximum value returned by the node's children so far.
           None of the children have returned anything so far, so initialize with minimal "NaN" value.
           The worst return value here is MAX_HEURIST_VALUE*plies[level], so never NEGATIVE_INFINITY anyway. */
        int16 max = LESS_THAN_NEGATIVE_INFINITY;

        /* Local variable that stores the column number in which next move is to be made.
           Initialized with uint8.MAX because we do not know the column number yet. */
        uint8 next = uint8.MAX;

        for (uint8 column = 0; column < n_cols; column++)
        {
            if (!move (player, column, ref board))
                continue;

            /* victory() checks if making a move in the i'th column results in a victory for the given player.
               If so, multiply MAX_HEURIST_VALUE by a height factor to avoid closer threats first.
               Or, we need to go further down the negamax tree. */
            int16 temp = victory (player, line, column, ref board) ? MAX_HEURIST_VALUE * height
                                                                   : -1 * negamax (height - 1, -1 * beta, -1 * alpha, player == Player.OPPONENT ? Player.HUMAN : Player.OPPONENT, level, line, ref board, ref next_move_in_column);

            unmove (column, ref board);

            if (temp > max)
            {
                next = column;
                max = temp;
            }

            if (temp > alpha)
                alpha = temp;

            if (alpha >= beta)
                break;
        }

        /* hackish: if it's the root node, return the value of the column where to play */
        if (height == plies [level])
            next_move_in_column = next;

        return max;
    }

    /*\
    * * checking victory
    \*/

    /* all these functions return true if the given player wins, or false */
    private static bool victory (Player player, uint8 line, uint8 column, ref Player [,] board)
    {
        uint8 n_rows = (uint8) board.length [0];
        /* find the cell on which the last move was made */
        uint8 row;
        for (row = 0; row < n_rows && board [row, column] == Player.NOBODY; row++);

        return vertical_win             (player, line, row, column, ref board)
            || horizontal_win           (player, line, row, column, ref board)
            || forward_diagonal_win     (player, line, row, column, ref board)
            || backward_diagonal_win    (player, line, row, column, ref board);
    }

    private static inline bool forward_diagonal_win (Player player, uint8 line, uint8 _i, uint8 _j, ref Player [,] board)
    {
        uint8 n_rows = (uint8) board.length [0];
        uint8 n_cols = (uint8) board.length [1];
        int8 i = (int8) _i;
        int8 j = (int8) _j;

        uint8 count = 0;

        for (int8 k = i, l = j; k >= 0 && l < n_cols && board [k, l] == player; k--, l++, count++);
        for (int8 k = i + 1, l = j - 1; k < n_rows && l >= 0 && board [k, l] == player; k++, l--, count++);

        return count >= line;
    }

    private static inline bool backward_diagonal_win (Player player, uint8 line, uint8 _i, uint8 _j, ref Player [,] board)
    {
        uint8 n_rows = (uint8) board.length [0];
        uint8 n_cols = (uint8) board.length [1];
        int8 i = (int8) _i;
        int8 j = (int8) _j;

        uint8 count = 0;

        for (int8 k = i, l = j; k >= 0 && l >= 0 && board [k, l] == player; k--, l--, count++);
        for (int8 k = i + 1, l = j + 1; k < n_rows && l < n_cols && board [k, l] == player; k++, l++, count++);

        return count >= line;
    }

    private static inline bool horizontal_win (Player player, uint8 line, uint8 _i, uint8 _j, ref Player [,] board)
    {
        uint8 n_cols = (uint8) board.length [1];
        int8 i = (int8) _i;
        int8 j = (int8) _j;

        uint8 count = 0;

        for (int8 k = j; k >= 0 && board [i, k] == player; k--, count++);
        for (int8 k = j + 1; k < n_cols && board [i, k] == player; k++, count++);

        return count >= line;
    }

    private static inline bool vertical_win (Player player, uint8 line, uint8 i, uint8 j, ref Player [,] board)
    {
        uint8 n_rows = (uint8) board.length [0];
        uint8 count = 0;

        for (uint8 k = i; k < n_rows && board [k, j] == player; k++, count++);

        return count >= line;
    }

    /*\
    * * various
    \*/

    /* returns true if the board is full, false if not */
    private static bool board_full (ref Player [,] board)
    {
        uint8 n_cols = (uint8) board.length [1];
        for (uint8 i = 0 ; i < n_cols; i++)
            if (board [0, i] == Player.NOBODY)
                return false;
        return true;
    }

    /* makes a move into the column'th column. Returns true if the move was successful, false if it wasn't */
    private static bool move (Player player, uint8 column, ref Player [,] board)
    {
        uint8 n_rows = (uint8) board.length [0];
        /* find the cell on which to move */
        int8 row;
        for (row = n_rows - 1; row >= 0 && board [row, column] != Player.NOBODY; row--);

        if (row < 0)
            return false;

        board [row, column] = player;
        return true;
    }

    /* unmove the last move made in the column'th column */
    private static void unmove (uint8 column, ref Player [,] board)
    {
        uint8 n_rows = (uint8) board.length [0];
        /* find the cell on which the last move was made */
        uint8 row;
        for (row = 0; row < n_rows && board [row, column] == Player.NOBODY; row++);

        board [row, column] = Player.NOBODY;
    }

    /* Check for immediate win of HUMAN or OPPONENT. It checks the current state of the board. Returns uint8.MAX if no immediate win for Player P.
       Otherwise returns the column number in which Player P should move to win. */
    private static uint8 immediate_win (Player player, uint8 line, ref Player [,] board)
    {
        uint8 n_cols = (uint8) board.length [1];
        for (uint8 i = 0; i < n_cols; i++)
        {
            if (!move (player, i, ref board))
                continue;

            bool player_wins = victory (player, line, i, ref board);
            unmove (i, ref board);

            if (player_wins)
                return i;
        }

        /* returns uint8.MAX if no immediate win for Player p */
        return uint8.MAX;
    }

    /* utility function for debugging purposes, prints a snapshot of current status of the board */
//    private static void print_board (ref Player [,] board)
//    {
//        uint8 n_rows = (uint8) board.length [0];
//        uint8 n_cols = (uint8) board.length [1];
//        for (uint8 i = 0; i < n_rows; i++)
//        {
//            for (uint8 j = 0; j < n_cols; j++)
//                stdout.printf ("%d\t", board [i, j]);
//            stdout.printf ("\n");
//        }
//        stdout.printf ("\n");
//    }

    /*\
    * * heuristics
    \*/

    /* The evaluation function to be called when we have reached the maximum depth in the DecisionTree */
    private static inline int16 heurist (Difficulty level, uint8 line, ref Player [,] board)
    {
        switch (level)
        {
            case Difficulty.EASY  : return heurist_easy (line, ref board);
            case Difficulty.MEDIUM: return heurist_medium ();
            case Difficulty.HARD  : return heurist_hard (line, ref board);
            default: assert_not_reached ();
        }
    }

    private static int16 heurist_easy (uint8 line, ref Player [,] board)
    {
        return -1 * heurist_hard (line, ref board);
    }

    private static inline int16 heurist_medium ()
    {
        return (int16) Random.int_range (1, 49);
    }

    private static int16 heurist_hard (uint8 line, ref Player [,] board)
    {
        int8 count = count_3_in_a_row (Player.OPPONENT, line, ref board) - count_3_in_a_row (Player.HUMAN, line, ref board);
        return count == 0 ? (int16) Random.int_range (1, 49) : (int16) count * 100;
    }

    /* Count the number of threes in a row for Player P. It counts all those 3
       which have an empty cell in the vicinity to make it four in a row. */
    private static int8 count_3_in_a_row (Player player, uint8 line, ref Player [,] board)
    {
        uint8 n_rows = (uint8) board.length [0];
        uint8 n_cols = (uint8) board.length [1];
        int8 count = 0;

        for (uint8 j = 0; j < n_cols; j++)
        {
            for (uint8 i = 0; i < n_rows; i++)
            {
                if (board [i, j] != Player.NOBODY)
                    break;

                if (all_adjacent_empty (i, j, ref board))
                    continue;

                board [i, j] = player;

                if (victory (player, line, j, ref board))
                {
                    if (count < int8.MAX)
                        count++;
                    else
                        warning ("Method count_3_in_a_row() exceeded its maximum count.");
                }

                board [i, j] = Player.NOBODY;
            }
        }
        return count;
    }

    /* checks if all adjacent cells to board [i, j] are empty */
    private static inline bool all_adjacent_empty (uint8 _i, uint8 _j, ref Player [,] board)
    {
        uint8 n_rows = (uint8) board.length [0];
        uint8 n_cols = (uint8) board.length [1];
        int8 i = (int8) _i;
        int8 j = (int8) _j;

        for (int8 k = -1 ; k <= 1; k++)
        {
            for (int8 l = -1; l <= 1; l++)
            {
                if (k == 0 && l == 0)
                    continue;
                if (i + k >= 0 && i + k < n_rows && j + l >= 0 && j + l < n_cols && board [i + k, j + l] != Player.NOBODY)
                    return false;
            }
        }

        return true;
    }
}
