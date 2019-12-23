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

private enum Difficulty { EASY, MEDIUM, HARD; }

private uint8 playgame (string moves_until_now)
{
    DecisionTree t = new DecisionTree ();
    return t.playgame (moves_until_now);
}

private class DecisionTree
{
    /* Here NEG_INF is supposed to be the lowest possible int value. int.MIN
    MAX_HEURIST_VALUE is the maximum value that the heuristic functions can return.
    It is returned when AI wins. -1*MAX_HEURIST_VALUE is returned when Human wins
    MAX_HEURIST_VALUE < NEG_INF/plies */
    private const int NEG_INF = -100000;
    private const int MAX_HEURIST_VALUE = 10000;

    /* to mantain the status of the board, to be used by the heuristic function, the top left cell is [0, 0] */
    private Player [,] board = new Player [BOARD_ROWS, BOARD_COLUMNS];
    /* plies - depth of the DecisionTree */
    private uint8 plies = 8;
    /* last_moving_player - The player who made the last move, set to Player.NOBODY if no one has made a move yet */
    private Player last_moving_player = Player.NOBODY;
    /* next_move_in_column - stores the column number in which next move is to be made */
    private uint8 next_move_in_column = uint8.MAX;
    /* stores the difficulty level of the game */
    private Difficulty level;

    /* Initializes an empty board */
    internal DecisionTree ()
    {
        for (uint8 i = 0; i < BOARD_ROWS; i++)
            for (uint8 j = 0; j < BOARD_COLUMNS; j++)
                board [i, j] = Player.NOBODY;
    }

    /* utility function for debugging purposes, prints a snapshot of current status of the board */
    internal void print_board ()
    {
        for (uint8 i = 0; i < BOARD_ROWS; i++)
        {
            for (uint8 j = 0; j < BOARD_COLUMNS; j++)
                stdout.printf ("%d\t", board [i, j]);
            stdout.printf ("\n");
        }
        stdout.printf ("\n");
    }

    /* Recursively implements a negamax tree in memory with alpha-beta pruning. The function is first called for the root node.
       It returns the value of the current node. For nodes at height == 0, the value is determined by a heuristic function. */
    private int negamax (uint8 height, int alpha, int beta)
    {
        /* base case of recursive function, returns if we have reached the lowest depth of DecisionTree or the board if full */
        if (height == 0 || board_full ())
        {
            if (last_moving_player == Player.HUMAN)
                return heurist ();
            else if (last_moving_player == Player.OPPONENT)
                return -1 * heurist ();
            else
                return 0;
        }

        /* Local variable that stores the maximum value returned by the node's children so far.
           None of the children have returned anything so far. Hence, it is initialized with NEG_INF. */
        int max = NEG_INF;

        /* Local variable that stores the column number in which next move is to be made.
           Initialized with -1 because we do not know the column number yet. */
        uint8 next = uint8.MAX;

        for (uint8 column = 0; column < BOARD_COLUMNS; column++)
        {
            /* make a move into the i'th column */
            if (!move (column))
                continue;

            /* victory() checks if making a move in the i'th column results in a victory for last_moving_player.
               If so, multiply MAX_HEURIST_VALUE by a height factor to avoid closer threats first.
               Or, we need to go further down the negamax tree. */
            int temp = victory (column) ? MAX_HEURIST_VALUE * height : -1 * negamax (height - 1, -1 * beta, -1 * alpha);

            unmove (column);

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

        /* If it's the root node, asign the value of next to next_move_in_column */
        if (height == plies)
            next_move_in_column = next;

        return max;
    }

    /* all these functions return true if last_moving_player wins, or false */
    private bool victory (uint8 column)
    {
        /* find the cell on which the last move was made */
        uint8 row;
        for (row = 0; row < BOARD_ROWS && board [row, column] == Player.NOBODY; row++);

        return vertical_win (row, column)
            || horizontal_win (row, column)
            || forward_diagonal_win (row, column)
            || backward_diagonal_win (row, column);
    }

    private inline bool forward_diagonal_win (uint8 _i, uint8 _j)
    {
        int8 i = (int8) _i;
        int8 j = (int8) _j;

        uint8 count = 0;

        for (int8 k = i, l = j; k >= 0 && l < BOARD_COLUMNS && board [k, l] == last_moving_player; k--, l++, count++);
        for (int8 k = i + 1, l = j - 1; k < BOARD_ROWS && l >= 0 && board [k, l] == last_moving_player; k++, l--, count++);

        return count >= 4;
    }

    private inline bool backward_diagonal_win (uint8 _i, uint8 _j)
    {
        int8 i = (int8) _i;
        int8 j = (int8) _j;

        uint8 count = 0;

        for (int8 k = i, l = j; k >= 0 && l >= 0 && board [k, l] == last_moving_player; k--, l--, count++);
        for (int8 k = i + 1, l = j + 1; k < BOARD_ROWS && l < BOARD_COLUMNS && board [k, l] == last_moving_player; k++, l++, count++);

        return count >= 4;
    }

    private inline bool horizontal_win (uint8 _i, uint8 _j)
    {
        int8 i = (int8) _i;
        int8 j = (int8) _j;

        uint8 count = 0;

        for (int8 k = j; k >= 0 && board [i, k] == last_moving_player; k--, count++);
        for (int8 k = j + 1; k < BOARD_COLUMNS && board [i, k] == last_moving_player; k++, count++);

        return count >= 4;
    }

    private inline bool vertical_win (uint8 i, uint8 j)
    {
        uint8 count = 0;

        for (uint8 k = i; k < BOARD_ROWS && board [k, j] == last_moving_player; k++, count++);

        return count >= 4;
    }

    /* returns true if the board is full, false if not */
    private bool board_full ()
    {
        for (uint8 i = 0 ; i < BOARD_COLUMNS ; i++)
            if (board [0, i] == Player.NOBODY)
                return false;
        return true;
    }

    /* makes a move into the column'th column. Returns true if the move was succesful, false if it wasn't */
    private bool move (uint8 column)
    {
        /* find the cell on which to move */
        int8 row;
        for (row = BOARD_ROWS - 1; row >= 0 && board [row, column] != Player.NOBODY; row--);

        if (row < 0)
            return false;

        /* don't forget AI could make the first move */
        Player player = last_moving_player != Player.OPPONENT ? Player.OPPONENT : Player.HUMAN;
        board [row, column] = player;
        last_moving_player = player;

        return true;
    }

    /* unmove the last move made in the column'th column */
    private void unmove (uint8 column)
        requires (last_moving_player != Player.NOBODY)
    {
        /* find the cell on which the last move was made */
        uint8 row;
        for (row = 0; row < BOARD_ROWS && board [row, column] == Player.NOBODY; row++);

        board [row, column] = Player.NOBODY;

        last_moving_player = last_moving_player == Player.OPPONENT ? Player.HUMAN : Player.OPPONENT;
    }

    /* vstr is the sequence of moves made until now. We update DecisionTree::board to reflect these sequence of moves. */
    private void update_board (string vstr)
    {
        next_move_in_column = uint8.MAX;

        /* AI will make the first move, nothing to add to the board */
        if (vstr.length == 2) return;

        Player move = vstr.length % 2 == 0 ? Player.OPPONENT : Player.HUMAN;

        for (uint8 i = 1; i < vstr.length - 1; i++)
        {
            uint8 column = (uint8) int.parse (vstr [i].to_string ()) - 1;

            /* find the cell on which the move is made */
            int8 row;
            for (row = BOARD_ROWS - 1; row >= 0 && board [row, column] != Player.NOBODY; row--);

            board [row, column] = move;

            move = move == Player.HUMAN ? Player.OPPONENT : Player.HUMAN;
        }

        last_moving_player = Player.HUMAN;
    }

    /* Check for immediate win of HUMAN or OPPONENT. It checks the current state of the board. Returns uint8.MAX if no immediate win for Player P.
       Otherwise returns the column number in which Player P should move to win. */
    private uint8 immediate_win (Player p)
    {
        Player old_last_moving_player = last_moving_player;

        last_moving_player = p == Player.OPPONENT ? Player.HUMAN : Player.OPPONENT;

        bool player_wins = false;
        uint8 i;
        for (i = 0; i < BOARD_COLUMNS; i++)
        {
            if (!move (i))
                continue;

            player_wins = victory (i);
            unmove (i);

            if (player_wins)
                break;
        }

        last_moving_player = old_last_moving_player;

        /* returns uint8.MAX if no immediate win for Player p */
        return player_wins ? i : uint8.MAX;
    }

    /* returns the column number in which the next move has to be made. Returns uint8.MAX if the board is full. */
    internal uint8 playgame (string vstr)
    {
        /* set the Difficulty level */
        set_level (vstr);

        /* update DecisionTree::board to reflect the moves made until now */
        update_board (vstr);

        /* if AI can win by making a move immediately, make that move */
        uint8 temp = immediate_win (Player.OPPONENT);
        if (temp < BOARD_COLUMNS)
            return temp;

        /* if HUMAN can win by making a move immediately,
           we make AI move in that column so as avoid loss */
        temp = immediate_win (Player.HUMAN);
        if (temp < BOARD_COLUMNS)
            return temp;

        /* call negamax tree on the current state of the board */
        negamax (plies, NEG_INF, -1 * NEG_INF);

        /* return the column number in which next move should be made */
        return next_move_in_column;
    }

    /* The evaluation function to be called when we have reached the maximum depth in the DecisionTree */
    private int heurist ()
    {
        if (level == Difficulty.EASY)
            return heurist_easy ();
        else if (level == Difficulty.MEDIUM)
            return heurist_medium ();
        else
            return heurist_hard ();
    }

    private int heurist_easy ()
    {
        return -1 * heurist_hard ();
    }

    private int heurist_medium ()
    {
        return Random.int_range (1, 49);
    }

    private int heurist_hard ()
    {
        int count = count_3_in_a_row (Player.OPPONENT) - count_3_in_a_row (Player.HUMAN);
        return count == 0 ? (int) Random.int_range (1, 49) : count * 100;
    }

    /* Count the number of threes in a row for Player P. It counts all those 3 which have an empty cell in the vicinity to make it
       four in a row. */
    private int count_3_in_a_row (Player p)
    {
        int count = 0;

        Player old_last_moving_player = last_moving_player;

        last_moving_player = p;

        for (uint8 j = 0; j < BOARD_COLUMNS; j++)
        {
            for (uint8 i = 0; i < BOARD_ROWS; i++)
            {
                if (board [i, j] != Player.NOBODY)
                    break;

                if (all_adjacent_empty (i, j))
                    continue;

                board [i, j] = p;

                if (victory (j))
                    count++;

                board [i, j] = Player.NOBODY;
            }
        }
        last_moving_player = old_last_moving_player;
        return count;
    }

    /* checks if all adjacent cells to board [i, j] are empty */
    private inline bool all_adjacent_empty (uint8 _i, uint8 _j)
    {
        int8 i = (int8) _i;
        int8 j = (int8) _j;

        for (int8 k = -1 ; k <= 1; k++)
        {
            for (int8 l = -1; l <= 1; l++)
            {
                if (k == 0 && l == 0)
                    continue;
                if (i + k >= 0 && i + k < BOARD_ROWS && j + l >= 0 && j + l < BOARD_COLUMNS && board [i + k, j + l] != Player.NOBODY)
                    return false;
            }
        }

        return true;
    }

    /* set the number of plies and the difficulty level */
    private void set_level (string vstr)
    {
        if (vstr [0] == 'a')
        {
            level = Difficulty.EASY;
            plies = 4;
        }
        else if (vstr [0] == 'b')
        {
            level = Difficulty.MEDIUM;
            plies = 7;
        }
        else // TODO if (vstr [0] == 'c') / else assert_not_reached ();
        {
            level = Difficulty.HARD;
            plies = 7;
        }
    }

    /* utility function for testing purposes */
    internal uint8 playandcheck (string vstr)
    {
        set_level (vstr);
        update_board (vstr);

        uint8 temp = immediate_win (Player.OPPONENT);
        if (temp < BOARD_COLUMNS)
            return 100;

        temp = immediate_win (Player.HUMAN);
        if (temp < BOARD_COLUMNS)
            return temp;

        negamax (plies, NEG_INF, -1 * NEG_INF);

        return next_move_in_column;
    }
}
