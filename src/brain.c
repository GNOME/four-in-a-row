/* -*-mode:c; c-style:k&r; c-basic-offset:4; -*-
 *
 * gnect brain.c
 *
 * Tim Musson
 * <trmusson@ihug.co.nz>
 *
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * http://www.gnu.org/copyleft/gpl.html
 *
 *
 */




/* Welcome to Gnect's original brain - the first it ever had, and
 * pretty embarassing. It's still here because it happens to make
 * a half decent level for young children who might find the
 * Velena Engine a bit too hard.
 *
 */


#include "config.h"
#include "main.h"
#include "gnect.h"
#include "brain.h"
#include "prefs.h"
#include "gfx.h"


extern Gnect gnect;
extern Prefs prefs;


#define BRAIN_CHOICE_WIN           12 /* greatest incentive to drop counter */
#define BRAIN_CHOICE_THWART_1      11
#define BRAIN_CHOICE_THWART_2      10
#define BRAIN_CHOICE_GOOD_1         9
#define BRAIN_CHOICE_GOOD_2         8
#define BRAIN_CHOICE_GOOD_3         7
#define BRAIN_CHOICE_GOOD_4         6
#define BRAIN_CHOICE_NO_VALUE       5
#define BRAIN_CHOICE_BAD_2          4
#define BRAIN_CHOICE_BAD_1          3
#define BRAIN_CHOICE_MY_TRAP        2
#define BRAIN_CHOICE_OPPONENTS_TRAP 1
#define BRAIN_CHOICE_FULL_COLUMN    0 /* least incentive to drop counter    */


static void     brain_pass_1(void);
static void     brain_pass_2(void);
static void     brain_pass_3(void);
static void     brain_pass_4(void);
static gboolean brain_row_compare(gint row, gint col, const gchar *rowstr, const gchar *belowstr);
static gboolean brain_block_compare(gint row, gint col, const gchar *str1, const gchar *str2, const gchar *str3, const gchar *str4);
static gint     brain_test_drop(gint counter, gint col, gint len);
static gint     brain_has_multi_choice(gint val);
static gint     brain_col_is_trap(gint counter, gint col, gint len);
static gint     brain_best_choice(void);


static gint me, opponent, choice[N_COLS + 1];




gint brain_get_computer_move(void)
{
	/* Return the best move (column) Gnect can come up with */


	me = gnect.current_player;
	if (me == PLAYER_1) {
		opponent = PLAYER_2;
	}
	else {
		opponent = PLAYER_1;
	}

	brain_pass_1();
	brain_pass_2();
	brain_pass_3();
	brain_pass_4();

	return(brain_best_choice());
}



static void brain_pass_1(void)
{
	/* Work out the immediate value of dropping the computer's
	   counter into each column. Store in the 'choice' array */


	gint col = 0;


	while(col < N_COLS) {

		/*
		if (prefs.do_animate) {
			gfx_move_cursor(col);
		}
		*/

		if (gnect_is_full_column(col)) {
			/* Column full */
			choice[col] = BRAIN_CHOICE_FULL_COLUMN;
		}
		else if (brain_test_drop(me, col, LINE_LENGTH)) {
			/* I get an immediate win with this column */
			choice[col] = BRAIN_CHOICE_WIN;
		}
		else if (brain_test_drop(opponent, col, LINE_LENGTH)) {
			/* opponent wins with this column */
			choice[col] = BRAIN_CHOICE_THWART_1;
		}
		else if (brain_col_is_trap(me, col, LINE_LENGTH)) {
			/* if I drop counter here, opponent's next move could win */
			choice[col] = BRAIN_CHOICE_OPPONENTS_TRAP;
		}
		else if (brain_col_is_trap(opponent, col, LINE_LENGTH)) {
			/* if opponent drops counter here, I could win */
			choice[col] = BRAIN_CHOICE_MY_TRAP;
		}
		else {
			/* No immediate reason to drop a counter here */
			choice[col] = BRAIN_CHOICE_NO_VALUE;
		}
		col++;
	}
}



static void brain_pass_2(void)
{
	gint row, col;


	/* yes, well, I'm just a dummy too... */

	for (col = 0; col < N_COLS; col++) {
		if (choice[col] != BRAIN_CHOICE_FULL_COLUMN) {

			row = gnect_get_top_used_row(col) - 1;

			if (brain_row_compare(row, col, "*.11.", "xxxx.") ||
				brain_row_compare(row, col, "*.22.", "xxxx.")) {
				if (choice[col + 1] == BRAIN_CHOICE_NO_VALUE) {choice[col + 1] = BRAIN_CHOICE_GOOD_1;}
				if (choice[col + 4] == BRAIN_CHOICE_NO_VALUE) {choice[col + 4] = BRAIN_CHOICE_BAD_1;}
			}
			if (brain_row_compare(row, col, ".11.*", ".xxxx") ||
				brain_row_compare(row, col, ".22.*", ".xxxx")) {
				if (choice[col + 3] == BRAIN_CHOICE_NO_VALUE) {choice[col + 3] = BRAIN_CHOICE_GOOD_1;}
				if (choice[col] == BRAIN_CHOICE_NO_VALUE) {choice[col] = BRAIN_CHOICE_BAD_1;}
			}
			if (brain_row_compare(row, col, ".11..", "xxx.x") ||
				brain_row_compare(row, col, ".22..", "xxx.x")) {
				if (choice[col] == BRAIN_CHOICE_NO_VALUE) {choice[col] = BRAIN_CHOICE_GOOD_1;}
			}
			if (brain_row_compare(row, col, "..11.", "x.xxx") ||
				brain_row_compare(row, col, "..22.", "x.xxx")) {
				if (choice[col + 4] == BRAIN_CHOICE_NO_VALUE) {choice[col + 4] = BRAIN_CHOICE_GOOD_1;}
			}
			if (brain_row_compare(row, col, ".11..", "xxxxx") ||
				brain_row_compare(row, col, ".22..", "xxxxx")) {
				if (choice[col + 3] == BRAIN_CHOICE_NO_VALUE) {choice[col + 3] = BRAIN_CHOICE_GOOD_1;}
			}
			if (brain_row_compare(row, col, "..11.", "xxxxx") ||
				brain_row_compare(row, col, "..22.", "xxxxx")) {
				if (choice[col + 1] == BRAIN_CHOICE_NO_VALUE) {choice[col + 1] = BRAIN_CHOICE_GOOD_1;}
			}
			if (brain_row_compare(row, col, ".1.1.", ".xxxx") ||
				brain_row_compare(row, col, ".2.2.", ".xxxx")) {
				if (choice[col + 2] == BRAIN_CHOICE_NO_VALUE) {choice[col + 2] = BRAIN_CHOICE_GOOD_1;}
			}
			if (brain_row_compare(row, col, ".1.1.", "xxxx.") ||
				brain_row_compare(row, col, ".2.2.", "xxxx.")) {
				if (choice[col + 2] == BRAIN_CHOICE_NO_VALUE) {choice[col + 2] = BRAIN_CHOICE_GOOD_1;}
			}
			if (brain_row_compare(row, col, ".1.1.", "xxxxx") ||
				brain_row_compare(row, col, ".2.2.", "xxxxx")) {
				if (choice[col + 2] == BRAIN_CHOICE_NO_VALUE) {choice[col + 2] = BRAIN_CHOICE_GOOD_1;}
			}
			if (brain_row_compare(row, col, ".1.1.", "xx.xx") ||
				brain_row_compare(row, col, ".2.2.", "xx.xx")) {
				if (choice[col] == BRAIN_CHOICE_NO_VALUE) {choice[col] = BRAIN_CHOICE_GOOD_1;}
				if (choice[col + 4] == BRAIN_CHOICE_NO_VALUE) {choice[col + 4] = BRAIN_CHOICE_GOOD_1;}
			}
		}
	}
}



static void brain_pass_3(void)
{
	/* Where there's nothing worth doing, pretend it's Connect Three - not great, but hey. */


	gint col = 0;


	while(col < N_COLS) {

		if (choice[col] == BRAIN_CHOICE_NO_VALUE) {

			if (brain_test_drop(me, col, LINE_LENGTH - 1)) {
				choice[col] = BRAIN_CHOICE_GOOD_2;
			}
			if (brain_test_drop(opponent, col, LINE_LENGTH - 1)) {
				choice[col] = BRAIN_CHOICE_GOOD_2;
			}

			if (brain_col_is_trap(me, col, LINE_LENGTH - 1)) {
				choice[col] = BRAIN_CHOICE_BAD_2;
			}
			else if (brain_col_is_trap(opponent, col, LINE_LENGTH - 1)) {
				choice[col] = BRAIN_CHOICE_BAD_1;
			}

		}
		col++;

	}

}



static void brain_pass_4(void)
{

	gboolean test;
	gint col, row;


	for (row = 1; row < N_ROWS - 1; row++) {
		for (col = 0; col < N_COLS; col++) {

			if (brain_block_compare(row, col, "11..", "x11.", "1xxx", "xxxx") ||
				brain_block_compare(row, col, "22..", "x22.", "2xxx", "xxxx")) {
				if (choice[col+2] && choice[col+2] < BRAIN_CHOICE_GOOD_1) {choice[col+2] = BRAIN_CHOICE_GOOD_1;}
			}
			if (brain_block_compare(row, col, "..11", ".11x", "xxx1", "xxxx") ||
				brain_block_compare(row, col, "..22", ".22x", "xxx2", "xxxx")) {
				if (choice[col+1] && choice[col+1] < BRAIN_CHOICE_GOOD_1) {choice[col+1] = BRAIN_CHOICE_GOOD_1;}
			}
			if (brain_block_compare(row, col, ".11", "1xx", "1xx", "xxx") ||
				brain_block_compare(row, col, ".22", "2xx", "2xx", "xxx")) {
				if (choice[col] && choice[col] < BRAIN_CHOICE_GOOD_1) {choice[col] = BRAIN_CHOICE_GOOD_1;}
			}
			if (brain_block_compare(row, col, "11.", "xx1", "xx1", "xxx") ||
				brain_block_compare(row, col, "22.", "xx2", "xx2", "xxx")) {
				if (choice[col+2] && choice[col+2] < BRAIN_CHOICE_GOOD_1) {choice[col+2] = BRAIN_CHOICE_GOOD_1;}
			}
			if (brain_block_compare(row, col, ".1.", "1xx", "1xx", "xxx") ||
				brain_block_compare(row, col, ".2.", "2xx", "2xx", "xxx")) {
				if (choice[col+2] && choice[col+2] < BRAIN_CHOICE_GOOD_2) {choice[col+2] = BRAIN_CHOICE_GOOD_2;}
			}
			if (brain_block_compare(row, col, ".1.", "xx1", "xx1", "xxx") ||
				brain_block_compare(row, col, ".2.", "xx2", "xx2", "xxx")) {
				if (choice[col] && choice[col] < BRAIN_CHOICE_GOOD_2) {choice[col] = BRAIN_CHOICE_GOOD_2;}
			}
			if (brain_block_compare(row, col, "1.1", "x1x", "xxx", "xxx") ||
				brain_block_compare(row, col, "2.2", "x2x", "xxx", "xxx")) {
				if (choice[col+1] && choice[col+1] < BRAIN_CHOICE_THWART_2) {choice[col+1] = BRAIN_CHOICE_THWART_2;}
			}
			if (brain_block_compare(row, col, "1.1", "x1x", "xxx", "xxx") ||
				brain_block_compare(row, col, "2.2", "x2x", "xxx", "xxx")) {
				if (choice[col+1] && choice[col+1] < BRAIN_CHOICE_THWART_2) {choice[col+1] = BRAIN_CHOICE_THWART_2;}
			}
			if (brain_block_compare(row, col, ".*1", ".11", "xx1", "xxx") ||
				brain_block_compare(row, col, ".*2", ".22", "xx2", "xxx")) {
				if (choice[col] && choice[col] < BRAIN_CHOICE_GOOD_1) {choice[col] = BRAIN_CHOICE_GOOD_1;}
			}
			if (brain_block_compare(row, col, "1*.", "11.", "1xx", "xxx") ||
				brain_block_compare(row, col, "2*.", "22.", "2xx", "xxx")) {
				if (choice[col+2] && choice[col+2] < BRAIN_CHOICE_GOOD_1) {choice[col+2] = BRAIN_CHOICE_GOOD_1;}
			}
			if (brain_block_compare(row, col, ".1*", "111", "xxx", "xxx") ||
				brain_block_compare(row, col, ".2*", "222", "xxx", "xxx")) {
				if (choice[col] && choice[col] < BRAIN_CHOICE_GOOD_1) {choice[col] = BRAIN_CHOICE_GOOD_1;}
			}
			if (brain_block_compare(row, col, "*1.", "111", "xxx", "xxx") ||
				brain_block_compare(row, col, "*2.", "222", "xxx", "xxx")) {
				if (choice[col+2] && choice[col+2] < BRAIN_CHOICE_GOOD_1) {choice[col+2] = BRAIN_CHOICE_GOOD_1;}
			}
		}
	}



	/* try filling the middle columns */
	test = TRUE;
	for (col = 0; col < N_ROWS; col++) {
		if (choice[col] != BRAIN_CHOICE_NO_VALUE && choice[col] != BRAIN_CHOICE_FULL_COLUMN) {
			test = FALSE;
		}
	}
	if (test) {
		gint middle = N_COLS / 2;
		if (TILE_AT(N_ROWS - 1, middle) == TILE_CLEAR) {
			if (choice[middle] != BRAIN_CHOICE_FULL_COLUMN) {choice[middle] = BRAIN_CHOICE_GOOD_1;}
		}
		else {
			if (choice[middle] != BRAIN_CHOICE_FULL_COLUMN) {choice[middle] = BRAIN_CHOICE_GOOD_2;}
		}
		if (choice[middle-2] != BRAIN_CHOICE_FULL_COLUMN) {choice[middle-2] = BRAIN_CHOICE_GOOD_4;}
		if (choice[middle-1] != BRAIN_CHOICE_FULL_COLUMN) {choice[middle-1] = BRAIN_CHOICE_GOOD_3;}
		if (choice[middle+1] != BRAIN_CHOICE_FULL_COLUMN) {choice[middle+1] = BRAIN_CHOICE_GOOD_3;}
		if (choice[middle+2] != BRAIN_CHOICE_FULL_COLUMN) {choice[middle+2] = BRAIN_CHOICE_GOOD_4;}
	}

}



static gboolean brain_block_compare(gint row, gint col,	const gchar *str1, const gchar *str2, const gchar *str3, const gchar *str4)
{
	if (brain_row_compare(row, col, str1, str2) &&
		brain_row_compare(row + 2, col, str3, str4)) {
		return(TRUE);
	}
	return(FALSE);
}



static gboolean brain_row_compare(gint row, gint col, const gchar *rowstr, const gchar *belowstr)
{
	/* Return TRUE if board[row][col]..board[row][col + strlen rowstr] matches rowstr
	 * and board[row + 1][col]..board[row + 1][col + strlen rowstr] matches belowstr
	 */

	gboolean result = TRUE;
	gboolean ok;
	gint l, i;



	l = strlen(rowstr);

	if (col + l > N_COLS - 1) {
		return(FALSE);
	}


	/*
	 *    . = empty
	 *    1 = player 1
	 *    2 = player 2
	 *    x = 1 or 2
	 *    * = 1, 2 or .
	 */


	for (i = 0; i < l; i++) {
		ok = FALSE;
		switch(rowstr[i]) {
		case '.' :
			ok = (TILE_AT(row, col + i) == TILE_CLEAR);
			break;
		case '1' :
			ok = (TILE_AT(row, col + i) == TILE_PLAYER_1);
			break;
		case '2' :
			ok = (TILE_AT(row, col + i) == TILE_PLAYER_2);
			break;
		case 'x' :
			ok = (TILE_AT(row, col + i) != TILE_CLEAR);
			break;
		default :
			ok = TRUE;
			break;
		}

		if (ok) {

			if (row != N_ROWS - 1) {

				switch(belowstr[i]) {
				case '.' :
					if (TILE_AT(row + 1, col + i) != TILE_CLEAR) {
						result = FALSE;
					}
					break;
				case '1' :
					if (TILE_AT(row + 1, col + i) != TILE_PLAYER_1) {
						result = FALSE;
					}
					break;
				case '2' :
					if (TILE_AT(row + 1, col + i) != TILE_PLAYER_2) {
						result = FALSE;
					}
					break;
				case 'x' :
					if (TILE_AT(row + 1, col + i) == TILE_CLEAR) {
						result = FALSE;
					}
					break;
				default :
					break;
				}
			}
		}
		else {
			result = FALSE;
		}
	}


	return(result);
}



static gint brain_test_drop(gint counter, gint col, gint len)
{
	/* Simulate dropping counter into col to see if it gives
	   counter a winning line. Return TRUE if it does */


	gint result = FALSE;
	gint row = 1;


	if (TILE_AT(1 ,col) == TILE_CLEAR) {

		while(row < N_ROWS - 1 && TILE_AT(row + 1, col) == TILE_CLEAR) {
			row++;
		}
		gnect.board_state[CELL_AT(row, col)] = counter;
		result = gnect_is_line(counter, row, col, len);
		gnect.board_state[CELL_AT(row, col)] = TILE_CLEAR;

	}

	return(result);
}



static gint brain_has_multi_choice(gint val)
{
	/* Return TRUE if more than one column has a choice with
	 * weight 'val'.
	 */


	gint col = 0;
	gint result = 0;


	while(col < N_COLS) {
		if (choice[col] == val) {
			result++;
		}
		col++;
	}
	return(result > 1);
}



static gint brain_col_is_trap(gint counter, gint col, gint len)
{
	/* Return TRUE if dropping counter here lets the anti-counter's
	   next move win */


	gint isTrap = FALSE;
	gint row = 0;
	gint antiCounter = me;


	if (TILE_AT(2, col) == TILE_CLEAR) {

		if (counter == me) {
			antiCounter = opponent;
		}

		while (row < N_ROWS && TILE_AT(row + 1, col) == TILE_CLEAR) {
			row++;
		}

		gnect.board_state[CELL_AT(row, col)] = counter;
		gnect.board_state[CELL_AT(row - 1, col)] = antiCounter;

		isTrap = gnect_is_line(antiCounter, row - 1, col, len);

		gnect.board_state[CELL_AT(row - 1, col)] = TILE_CLEAR;
		gnect.board_state[CELL_AT(row, col)] = TILE_CLEAR;
	}

	return(isTrap);
}



static gint brain_best_choice(void)
{
	/* Based on the choice value of each column, return
	   the bestCol in which to drop my counter */


	gint best_col = 0;
	gint best_val = 0;
	gint col;
	gint done = FALSE;


	for (col = 0; col < N_COLS; col++) {

		if (best_val < choice[col]) {
			best_col = col;
			best_val = choice[best_col];
		}
	}

	/* Pick between columns of highest value at random.
	   (this method wastes time, but computers are speedy...) */
	if (brain_has_multi_choice(best_val)) {

		while(!done){
			best_col = gnect_get_random_num(N_COLS) - 1;
			if (choice[best_col] == best_val) {
				done = TRUE;
			}
		}
	}

	if (choice[best_col] == BRAIN_CHOICE_FULL_COLUMN) {

		/* best choice is a full column - shouldn't happen */

		ERROR_PRINT("dummy brain tried dropping into a full column\n");
		gnect_cleanup(1);
	}

	return(best_col);
}
