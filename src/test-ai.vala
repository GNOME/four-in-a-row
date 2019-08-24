/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*-
 *
 * Copyright © 2014 Michael Catanzaro
 * Copyright © 2014 Nikhar Agrawal
 *
 * This file is part of Four-in-a-row.
 *
 * Four-in-a-row is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Four-in-a-row is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Four-in-a-row.  If not, see <http://www.gnu.org/licenses/>.
 */

private const int NUMBER_GAMES = 5;
private const int MAXIMUM_GAMES = 100;
private const int THRESHOLD_DENOMINATOR = 4;

private int main (string[] args)
{
    Test.init (ref args);
    Test.add_func ("/AI/Take Win/Horizontal Win", test_horizontal_win);
    Test.add_func ("/AI/Take Win/Vertical Win", test_vertical_win);
    Test.add_func ("/AI/Take Win/Forward Diagonal Win", test_forward_diagonal_win);
    Test.add_func ("/AI/Take Win/Backward Diagonal Win", test_backward_diagonal_win);
    Test.add_func ("/AI/Avoid Loss/Horizontal Loss", test_avoid_horizontal_loss);
    Test.add_func ("/AI/Avoid Loss/Vertical Loss", test_avoid_vertical_loss);
    Test.add_func ("/AI/Avoid Loss/Forward Diagonal Loss", test_avoid_forward_diagonal_loss);
    Test.add_func ("/AI/Avoid Loss/Backward Diagonal Loss", test_avoid_backward_diagonal_loss);
    Test.add_func ("/AI/AI vs AI/Easy vs Medium", test_easy_vs_medium);
    Test.add_func ("/AI/AI vs AI/Easy vs Hard", test_easy_vs_hard);
    Test.add_func ("/AI/AI vs AI/Medium vs Hard", test_medium_vs_hard);
    Test.add_func ("/AI/Draw", test_draw);
    Test.add_func ("/AI/Random", test_random);
    return Test.run ();
}

/* Tests if the AI makes moves so as to take up immediate horizontal wins. The argument to playgame function is the sequence of moves
 made until now. The return value of playgame function is the column number in which the AI should move.*/
private static inline void test_horizontal_win ()
{
    /*In the first statement below, the AI has made moves into the 1st, 2nd and 3rd columns. To win, AI must move in the 4th column.*/
    assert (playgame ("a1727370") == 4);
    assert (playgame ("a7315651311324420") == 6);
    assert (playgame ("a232225657223561611133440") == 4);
    assert (playgame ("a242215322574255543341746677453337710") == 1);
}

/* Tests if the AI makes moves so as to take up immediate vertical wins.*/
private static inline void test_vertical_win ()
{
    assert (playgame ("a1213140") == 1);
    assert (playgame ("a14456535526613130") == 1);
    assert (playgame ("a432334277752576710") == 7);
    assert (playgame ("a547477454544323321712116260") == 2);
}

/* Tests if the AI makes moves so as to take up immediate forward diagonal wins.*/
private static inline void test_forward_diagonal_win ()
{
    assert (playgame ("a54221164712446211622157570") == 7);
    assert (playgame ("a4256424426621271412117175776343330") == 3);
    assert (playgame ("a132565522322662666775443351131113540") == 4);
    assert (playgame ("a4571311334541225544112245262577767733360") == 6);
}

/* Tests if the AI makes moves so as to take up immediate backward diagonal wins.*/
private static inline void test_backward_diagonal_win ()
{
    assert (playgame ("5422327343142110") == 1);
    assert (playgame ("a1415113315143220") == 2);
    assert (playgame ("a547323452213345110") == 1);
    assert (playgame ("a4256424426621271412117175776343330") == 3);
}

/* Tests if the AI makes moves which prevents HUMAN from taking immediate vertical victories. Consider that a HUMAN has 3 balls in the
   first column. The AI's next move should be in the 1st column or else, HUMAN will claim victory on his next turn.*/
private static inline void test_avoid_vertical_loss ()
{
    assert (playgame ("a42563117273430") == 3);
    assert (playgame ("a3642571541322340") == 4);
    assert (playgame ("a144566264475171137750") == 5);
    assert (playgame ("a54747745454432332171210") == 1);
}

/* Tests if the AI makes moves which prevents HUMAN from taking immediate forward diagonal victories*/
private static inline void test_avoid_forward_diagonal_loss ()
{
    assert (playgame ("a34256477331566570") == 7);
    assert (playgame ("a1445662644751711370") == 7);
    assert (playgame ("a43442235372115113340") == 4);
    assert (playgame ("a4143525567766443543125411170") == 7);
}

/* Tests if the AI makes moves which prevents HUMAN from taking immediate backward diagonal victories*/
private static inline void test_avoid_backward_diagonal_loss ()
{
    assert (playgame ("a47465234222530") == 3);
    assert (playgame ("a4344223537211510") == 1);
    assert (playgame ("a4141311525513520") == 2);
    assert (playgame ("a1445662644751711377553330") == 3);

}

/* Tests if the AI makes moves which prevents HUMAN from taking immediate horizontal victories*/
private static inline void test_avoid_horizontal_loss ()
{
    assert (playgame ("a445360") == 7);
    assert (playgame ("a745534131117114777720") == 2);
    assert (playgame ("a243466431217112323350") == 5);
    assert (playgame ("a24147356465355111336631615240") == 4);
}

/* Tests if AI can detect full boards, and thus draw games.*/
private static inline void test_draw ()
{
    assert (playgame ("a1311313113652226667224247766737374455445550") == 0);
    assert (playgame ("a6121151135432322433425566474425617635677770") == 0);
    assert (playgame ("a4226111412113275256335534443264375577676670") == 0);
    assert (playgame ("a4212116575717754775221133434432366655342660") == 0);
}

/* Tests if AI makes valid moves, i.e., between column 1 and column 7*/
private static inline void test_random ()
{
    int x = playgame ("a443256214350");
    assert (x >= 1 && x <= 7);

    x = playgame ("a241473564653551113366316150");
    assert (x >= 1 && x <= 7);

    x = playgame ("a24357315461711177416622623350");
    assert (x >= 1 && x <= 7);

    x = playgame ("a1445662644751711377553333665775446110");
    assert (x >= 1 && x <= 7);
}

/* Pits two AI's of varying difficulty levels against each other and returns the number of games won by easier AI.*/
private static inline int test_ai_vs_ai (string easier, string harder)
{
    int easier_wins = 0;
    int draw = 0;
    int harder_wins = 0;

    for (int i = 0; i < NUMBER_GAMES; i++)
    {
        StringBuilder e = new StringBuilder ();
        e.append (easier);

        StringBuilder m = new StringBuilder ();
        m.append (harder);

        while (true)
        {
            int move;
            DecisionTree t = new DecisionTree ();
            move = t.playandcheck (e.str);
            if (move == 0)
            {
                draw++;
                break;
            }

            if (move == 1000)
            {
                easier_wins++;
                break;
            }

            e.insert (e.str.length - 1, move.to_string ());
            m.insert (m.str.length - 1, move.to_string ());

            DecisionTree d = new DecisionTree ();
            move = d.playandcheck (m.str);

            if (move == 0)
            {
                draw++;
                break;
            }

            if (move == 1000)
            {
                harder_wins++;
                break;
            }
            e.insert (e.str.length - 1, move.to_string ());
            m.insert (m.str.length - 1, move.to_string ());
        }
    }
    return easier_wins;
}

/* Repeatedly contest between the two AI until either easier win ratio is less than a threshold
   or maximum numbers of contests have been played.*/
private static inline void repeat_contests (string easier, string harder, out int games_contested, out int easy_wins)
{
    easy_wins = test_ai_vs_ai (easier, harder);
    games_contested = NUMBER_GAMES;

    while (games_contested <= MAXIMUM_GAMES && easy_wins > games_contested/THRESHOLD_DENOMINATOR)
    {
        easy_wins += test_ai_vs_ai (easier, harder);
        games_contested += NUMBER_GAMES;
    }
}

private static inline void test_easy_vs_medium ()
{
    int easy_wins;
    int games_contested;
    repeat_contests ("a0", "b0", out games_contested, out easy_wins);

    assert (easy_wins <= games_contested/THRESHOLD_DENOMINATOR);
}

private static inline void test_easy_vs_hard ()
{
    int easy_wins;
    int games_contested;
    repeat_contests ("a0", "c0", out games_contested, out easy_wins);

    assert (easy_wins <= games_contested/THRESHOLD_DENOMINATOR);
}

private static inline void test_medium_vs_hard ()
{
    int medium_wins;
    int games_contested;
    repeat_contests ("b0", "c0", out games_contested, out medium_wins);

    assert (medium_wins <= games_contested/THRESHOLD_DENOMINATOR);
}
