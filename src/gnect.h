/* -*-mode:c; c-style:k&r; c-basic-offset:4; -*-
 *
 * gnect gnect.h
 *
 */



#ifndef _GNECT_GNECT_H_
#define _GNECT_GNECT_H_


#include "connect4.h"


#define N_COLS                  7
#define N_ROWS                  7
#define LINE_LENGTH             4
#define MAX_LEN_VELENG_STR      (N_ROWS * N_COLS + 4)
#define CELL_AT(y, x)           gnect_get_cell(y, x)
#define TILE_AT(y, x)           gnect.board_state[CELL_AT(y, x)]


typedef struct _Gnect Gnect;

struct _Gnect {
	struct board *veleng_board;
	gchar        veleng_str[MAX_LEN_VELENG_STR];
	gint         board_state[N_ROWS * N_COLS];
	gint         who_starts;
	gint         cursor_col;
	gint         current_player;
	gint         winner;
	gint         row;              /* winning row */
	gint         col;              /* winning col */
	gint         score[3];
	gboolean     over;
};



void     gnect_cleanup(gint exit_code);
void     gnect_srand(guint seed);
gint     gnect_get_random_num(gint n);
gchar    *gnect_fname_expand(gchar *fname);
gboolean gnect_file_exists(const gchar *fname);
void     gnect_reset(gboolean with_display);
void     gnect_reset_display(void);
void     gnect_reset_scores(void);
gint     gnect_get_cell(gint row, gint col);
void     gnect_process_move(gint col);
gboolean gnect_undo_move(gboolean is_wipe);
gboolean gnect_is_full_column(gint col);
gboolean gnect_is_full_board(void);
gint     gnect_whois_player(gint player);
gboolean gnect_is_player_human(gint player);
gboolean gnect_is_player_computer(gint player);
gint     gnect_get_n_players(void);
gint     gnect_get_top_used_row(gint col);
gint     gnect_get_bottom_used_row(gint col);
void     gnect_hint(void);
gboolean gnect_is_line(gint counter, gint row, gint col, gint len);
gboolean gnect_is_line_horizontal(gint counter, gint row, gint col, gint len, gint *r1, gint *c1, gint *r2, gint *c2);
gboolean gnect_is_line_vertical(gint counter, gint row, gint col, gint len, gint *r1, gint *c1, gint *r2, gint *c2);
gboolean gnect_is_line_diagonal1(gint counter, gint row, gint col, gint len, gint *r1, gint *c1, gint *r2, gint *c2);
gboolean gnect_is_line_diagonal2(gint counter, gint row, gint col, gint len, gint *r1, gint *c1, gint *r2, gint *c2);


#endif
