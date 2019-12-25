/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
   This file is part of GNOME Four-in-a-row.

   Copyright © 2014 Michael Catanzaro
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

private const uint8 NUMBER_GAMES = 5;
private const uint8 MAXIMUM_GAMES = 100;
private const uint8 THRESHOLD_DENOMINATOR = 4;

private int main (string [] args)
{
    Test.init (ref args);
    // test winning
    Test.add_func ("/AI/Take Win/Horizontal Win",           test_horizontal_win);
    Test.add_func ("/AI/Take Win/Vertical Win",             test_vertical_win);
    Test.add_func ("/AI/Take Win/Forward Diagonal Win",     test_forward_diagonal_win);
    Test.add_func ("/AI/Take Win/Backward Diagonal Win",    test_backward_diagonal_win);
    // test avoiding loss
    Test.add_func ("/AI/Avoid Loss/Horizontal Loss",        test_avoid_horizontal_loss);
    Test.add_func ("/AI/Avoid Loss/Vertical Loss",          test_avoid_vertical_loss);
    Test.add_func ("/AI/Avoid Loss/Forward Diagonal Loss",  test_avoid_forward_diagonal_loss);
    Test.add_func ("/AI/Avoid Loss/Backward Diagonal Loss", test_avoid_backward_diagonal_loss);
    // test AI relative ranking; FIXME I think these tests are crazy
    Test.add_func ("/AI/AI vs AI/Easy vs Medium",           test_easy_vs_medium);
    Test.add_func ("/AI/AI vs AI/Easy vs Hard",             test_easy_vs_hard);
    Test.add_func ("/AI/AI vs AI/Medium vs Hard",           test_medium_vs_hard);
    // various
    Test.add_func ("/AI/Draw", /* "draw" as in tie game! */ test_draw);
    Test.add_func ("/AI/Random",                            test_random);
    // run
    return Test.run ();
}

/* Tests if the AI makes moves so as to take up immediate horizontal wins. The argument to playgame function is the sequence of moves
 made until now. The return value of playgame function is the column number in which the AI should move.*/
private static inline void test_horizontal_win ()
{
    /*In the first statement below, the AI has made moves into the 1st, 2nd and 3rd columns. To win, AI must move in the 4th column.*/
    assert_true (AI.playgame (Difficulty.EASY, "1727370") == 3);
    assert_true (AI.playgame (Difficulty.EASY, "7315651311324420") == 5);
    assert_true (AI.playgame (Difficulty.EASY, "232225657223561611133440") == 3);
    assert_true (AI.playgame (Difficulty.EASY, "242215322574255543341746677453337710") == 0);
}

/* Tests if the AI makes moves so as to take up immediate vertical wins.*/
private static inline void test_vertical_win ()
{
    assert_true (AI.playgame (Difficulty.EASY, "1213140") == 0);
    assert_true (AI.playgame (Difficulty.EASY, "14456535526613130") == 0);
    assert_true (AI.playgame (Difficulty.EASY, "432334277752576710") == 6);
    assert_true (AI.playgame (Difficulty.EASY, "547477454544323321712116260") == 1);
}

/* Tests if the AI makes moves so as to take up immediate forward diagonal wins.*/
private static inline void test_forward_diagonal_win ()
{
    assert_true (AI.playgame (Difficulty.EASY, "54221164712446211622157570") == 6);
    assert_true (AI.playgame (Difficulty.EASY, "4256424426621271412117175776343330") == 2);
    assert_true (AI.playgame (Difficulty.EASY, "132565522322662666775443351131113540") == 3);
    assert_true (AI.playgame (Difficulty.EASY, "4571311334541225544112245262577767733360") == 5);
}

/* Tests if the AI makes moves so as to take up immediate backward diagonal wins.*/
private static inline void test_backward_diagonal_win ()
{
    assert_true (AI.playgame (Difficulty.EASY, "5422327343142110") == 0);
    assert_true (AI.playgame (Difficulty.EASY, "1415113315143220") == 1);
    assert_true (AI.playgame (Difficulty.EASY, "547323452213345110") == 0);
    assert_true (AI.playgame (Difficulty.EASY, "4256424426621271412117175776343330") == 2);
}

/* Tests if the AI makes moves which prevents HUMAN from taking immediate vertical victories. Consider that a HUMAN has 3 balls in the
   first column. The AI's next move should be in the 1st column or else, HUMAN will claim victory on his next turn.*/
private static inline void test_avoid_vertical_loss ()
{
    assert_true (AI.playgame (Difficulty.EASY, "42563117273430") == 2);
    assert_true (AI.playgame (Difficulty.EASY, "3642571541322340") == 3);
    assert_true (AI.playgame (Difficulty.EASY, "144566264475171137750") == 4);
    assert_true (AI.playgame (Difficulty.EASY, "54747745454432332171210") == 0);
}

/* Tests if the AI makes moves which prevents HUMAN from taking immediate forward diagonal victories*/
private static inline void test_avoid_forward_diagonal_loss ()
{
    assert_true (AI.playgame (Difficulty.EASY, "34256477331566570") == 6);
    assert_true (AI.playgame (Difficulty.EASY, "1445662644751711370") == 6);
    assert_true (AI.playgame (Difficulty.EASY, "43442235372115113340") == 3);
    assert_true (AI.playgame (Difficulty.EASY, "4143525567766443543125411170") == 6);
}

/* Tests if the AI makes moves which prevents HUMAN from taking immediate backward diagonal victories*/
private static inline void test_avoid_backward_diagonal_loss ()
{
    assert_true (AI.playgame (Difficulty.EASY, "47465234222530") == 2);
    assert_true (AI.playgame (Difficulty.EASY, "4344223537211510") == 0);
    assert_true (AI.playgame (Difficulty.EASY, "4141311525513520") == 1);
    assert_true (AI.playgame (Difficulty.EASY, "1445662644751711377553330") == 2);

}

/* Tests if the AI makes moves which prevents HUMAN from taking immediate horizontal victories*/
private static inline void test_avoid_horizontal_loss ()
{
    assert_true (AI.playgame (Difficulty.EASY, "445360") == 6);
    assert_true (AI.playgame (Difficulty.EASY, "745534131117114777720") == 1);
    assert_true (AI.playgame (Difficulty.EASY, "243466431217112323350") == 4);
    assert_true (AI.playgame (Difficulty.EASY, "24147356465355111336631615240") == 3);
}

/* Tests if AI can detect full boards, and thus draw games. */
private static inline void test_draw ()
{
    assert_true (AI.playgame (Difficulty.EASY, "1311313113652226667224247766737374455445550") == uint8.MAX);
    assert_true (AI.playgame (Difficulty.EASY, "6121151135432322433425566474425617635677770") == uint8.MAX);
    assert_true (AI.playgame (Difficulty.EASY, "4226111412113275256335534443264375577676670") == uint8.MAX);
    assert_true (AI.playgame (Difficulty.EASY, "4212116575717754775221133434432366655342660") == uint8.MAX);
}

/* Tests if AI makes valid moves, i.e., between column 1 and column 7. */
private static inline void test_random ()
{
    uint8 x = AI.playgame (Difficulty.EASY, "443256214350");
    assert_true (x <= 6);

    x = AI.playgame (Difficulty.EASY, "241473564653551113366316150");
    assert_true (x <= 6);

    x = AI.playgame (Difficulty.EASY, "24357315461711177416622623350");
    assert_true (x <= 6);

    x = AI.playgame (Difficulty.EASY, "1445662644751711377553333665775446110");
    assert_true (x <= 6);
}

/* Pits two AI's of varying difficulty levels against each other and returns the number of games won by easier AI.*/
private static inline uint8 test_ai_vs_ai (Difficulty easier_AI, Difficulty harder_AI)
{
    uint8 easier_wins = 0;
    uint8 draw = 0;
    uint8 harder_wins = 0;

    for (uint8 i = 0; i < NUMBER_GAMES; i++)
    {
        StringBuilder easier = new StringBuilder ();
        easier.append ("0");

        StringBuilder harder = new StringBuilder ();
        harder.append ("0");

        while (true)
        {
            uint8 move = AI.playandcheck (easier_AI, easier.str);
            if (move == uint8.MAX)
            {
                draw++;
                break;
            }

            if (move == 100)
            {
                easier_wins++;
                break;
            }

            easier.insert (easier.str.length - 1, (move + 1).to_string ());
            harder.insert (harder.str.length - 1, (move + 1).to_string ());

            move = AI.playandcheck (harder_AI, harder.str);

            if (move == uint8.MAX)
            {
                draw++;
                break;
            }

            if (move == 100)
            {
                harder_wins++;
                break;
            }
            easier.insert (easier.str.length - 1, (move + 1).to_string ());
            harder.insert (harder.str.length - 1, (move + 1).to_string ());
        }
    }
    return easier_wins;
}

/* Repeatedly contest between the two AI until either easier win ratio is less than a threshold
   or maximum numbers of contests have been played.*/
private static inline void repeat_contests (Difficulty easier_AI, Difficulty harder_AI, out uint8 games_contested, out uint8 easy_wins)
{
    easy_wins = test_ai_vs_ai (easier_AI, harder_AI);
    games_contested = NUMBER_GAMES;

    while (games_contested <= MAXIMUM_GAMES && easy_wins > games_contested / THRESHOLD_DENOMINATOR)
    {
        easy_wins += test_ai_vs_ai (easier_AI, harder_AI);
        games_contested += NUMBER_GAMES;
    }
}

private static inline void test_easy_vs_medium ()
{
    uint8 easy_wins;
    uint8 games_contested;
    repeat_contests (Difficulty.EASY, Difficulty.MEDIUM, out games_contested, out easy_wins);

    assert_true (easy_wins <= games_contested / THRESHOLD_DENOMINATOR);
}

private static inline void test_easy_vs_hard ()
{
    uint8 easy_wins;
    uint8 games_contested;
    repeat_contests (Difficulty.EASY, Difficulty.HARD, out games_contested, out easy_wins);

    assert_true (easy_wins <= games_contested / THRESHOLD_DENOMINATOR);
}

private static inline void test_medium_vs_hard ()
{
    uint8 medium_wins;
    uint8 games_contested;
    repeat_contests (Difficulty.MEDIUM, Difficulty.HARD, out games_contested, out medium_wins);

    assert_true (medium_wins <= games_contested / THRESHOLD_DENOMINATOR);
}
