/* -*- mode:C; indent-tabs-mode:nil; tab-width:8; c-basic-offset:8; -*- */

/*
 * gnect gnect.c
 *
 */



#include <stdlib.h>
#include <time.h>

#include "config.h"
#include "main.h"
#include "gnect.h"
#include "gfx.h"
#include "gui.h"
#include "dialog.h"
#include "theme.h"
#include "sound.h"
#include "prefs.h"
#include "brain.h"


extern gint     debugging;
extern Prefs    prefs;
extern Anim     anim;

Gnect  gnect;

static gint source_id = 0;


void  veleng_free(struct board *board);               /* connect4.c */
short playgame(char *input_str, struct board *board); /* playgame.c */



void
gnect_cleanup (gint exit_code)
{
        DEBUG_PRINT(1, "gnect_cleanup\n");

        if (anim.id) gtk_timeout_remove (anim.id);

        prefs_save ();
        gfx_free ();
        theme_free_all ();
        veleng_free (gnect.veleng_board);
        prefs_free ();

        DEBUG_PRINT(1, "exit(%d)\n", exit_code);
        gtk_exit (exit_code);
}



void
gnect_srand (guint seed)
{
        /*
         * Seed the random number generator.
         */

        if (seed != 0) {
                g_random_set_seed (seed);

                if (debugging & 4) {
                        g_printerr ("\n" APPNAME ": random number seed=%d\n\n", seed);
                }
        }
}



gint
gnect_get_random_num (gint n)
{
        /*
         * Return a random integer in the range 1..n
         */

        return (gint) g_random_int_range (1, n + 1);
}



gchar *
gnect_fname_expand (gchar *fname)
{
        gchar *str = NULL;


        if (fname && fname[0] == '~') {
                str = g_strdup_printf ("%s%s", g_getenv ("HOME"), &fname[1]);
                g_free (fname);
                return str;
        }
        return fname;
}



gboolean
gnect_file_exists (const gchar *fname)
{
        return g_file_test (fname, G_FILE_TEST_EXISTS);
        /* | G_FILE_TEST_IS_REGULAR */
}



static gchar
gnect_get_veleng_level_ch (gint player)
{
        /*
         * Return the character representing this player's Velena level.
         * Assumes player is one of PLAYER_VELENA_WEAK/MEDIUM/STRONG.
         */

        switch (player) {

        case PLAYER_VELENA_WEAK :
                return 'a';

        case PLAYER_VELENA_MEDIUM :
                return 'b';

        }
        return 'c';
}



gint
gnect_get_cell (gint row, gint col)
{
        return col + N_ROWS * row;
}



gboolean
gnect_is_full_column (gint col)
{
        return TILE_AT(1, col) != TILE_CLEAR;
}



gboolean
gnect_is_full_board (void)
{
        gint col;


        for (col = 0; col < N_COLS; col++) {
                if (!gnect_is_full_column (col)) return FALSE;
        }
        return TRUE;
}



gint
gnect_get_top_used_row (gint col)
{
        gint row = 1;


        while (row < N_ROWS && TILE_AT(row, col) == TILE_CLEAR) row++;
        return row;
}



gint
gnect_get_bottom_used_row (gint col)
{
        /* used by gfx_wipe() to wipe from the bottom up */

        gint row = N_ROWS - 1;


        while (row && TILE_AT(row, col) == TILE_CLEAR) row--;
        return row;
}



gint
gnect_whois_player (gint player)
{
        /*
         * Given a player (PLAYER_1 or PLAYER_2), return its current type.
         * (ie. PLAYER_HUMAN, PLAYER_GNECT, PLAYER_VELENA_WEAK, etc.)
         */

        switch (player) {

        case PLAYER_1 :
                return prefs.player1;

        case PLAYER_2 :
                return prefs.player2;

        }

        /* won't get this far */
        DEBUG_PRINT(1, "gnect_whois_player(%d)\n", player);
        return 0;
}



gboolean
gnect_is_player_human (gint player)
{
        return gnect_whois_player(player) == PLAYER_HUMAN;
}



gboolean
gnect_is_player_computer (gint player)
{
        return gnect_whois_player(player) != PLAYER_HUMAN;
}



static void
gnect_switch_players (void)
{
        if (gnect.current_player == PLAYER_1) gnect.current_player = PLAYER_2;
        else gnect.current_player = PLAYER_1;

        gfx_move_cursor (gnect.cursor_col);
}



gint
gnect_get_n_players (void)
{
        /* How many humans are playing? (0, 1 or 2) */

        if (prefs.player1 == PLAYER_HUMAN && prefs.player2 == PLAYER_HUMAN) return 2;
        if (prefs.player1 != PLAYER_HUMAN && prefs.player2 != PLAYER_HUMAN) return 0;
        return 1;
}



static gint
gnect_computer_move (void)
{
        /*
         * Call one of the computer players to make a move.
         * Assumes gnect.current_player is PLAYER_GNECT or
         * PLAYER_VELENA_WEAK/MEDIUM/STRONG.
         */

        gint player;


        player = gnect_whois_player (gnect.current_player);


        /* Non-Velena Engine */

        if (player == PLAYER_GNECT) return brain_get_computer_move ();


        /* Velena Engine */

        gui_set_status (_(" Thinking..."), STATUS_MSG_SET);

        gnect.veleng_str[0] = gnect_get_veleng_level_ch (player);

        return playgame (gnect.veleng_str, gnect.veleng_board) - 1;
}



void
gnect_reset_scores (void)
{
        gnect.score[0] = 0;
        gnect.score[1] = 0;
        gnect.score[2] = 0;

        dialog_score_update ();
}



void
gnect_reset_display (void)
{
        DEBUG_PRINT(1, "gnect_reset_display\n");

        gui_set_status (NULL, STATUS_MSG_CLEAR);
        gfx_redraw (TRUE);
        gui_update_hint_sensitivity ();
        gui_update_undo_sensitivity ();
}



static void
gnect_reset_board (void)
{
        gint i;


        DEBUG_PRINT(1, "gnect_reset_board\n");

        /* Gnect's board representation */
        for (i = 0; i < N_ROWS * N_COLS; i++) {
                gnect.board_state[i] = TILE_CLEAR;
        }

        /* string to be passed to Velena Engine */
        for (i = 0; i < MAX_LEN_VELENG_STR; i++) {
                gnect.veleng_str[i] = '\0';
        }
        sprintf (gnect.veleng_str, "%c0", gnect_get_veleng_level_ch (PLAYER_VELENA_STRONG));
}



void
gnect_reset (gboolean with_display)
{
        DEBUG_PRINT(1, "gnect_reset\n");

        gnect.over = TRUE;

        if (source_id != 0) {
                g_source_remove (source_id);
                source_id = 0;
        }
        if (anim.id) {
                gtk_timeout_remove (anim.id);
                anim.id = 0;
        }

        gnect.winner = -1;
        gnect.cursor_col = N_COLS / 2;


        /* who starts? */

        switch (prefs.start_mode) {

        case START_MODE_PLAYER_1 :
                gnect.current_player = PLAYER_1;
                break;

        case START_MODE_PLAYER_2 :
                gnect.current_player = PLAYER_2;
                break;

        case START_MODE_ALTERNATE :
                if (gnect.who_starts == PLAYER_1) {
                        gnect.current_player = PLAYER_2;
                }
                else {
                        gnect.current_player = PLAYER_1;
                }
                break;
        default:
                gnect.current_player = PLAYER_1;
                prefs.start_mode = START_MODE_ALTERNATE;
                break;
        }

        gnect.who_starts = gnect.current_player;

        gnect_reset_board ();

        if (with_display) {

                gnect.over = FALSE;

                /* reset the display */

                gnect_reset_display ();
                gfx_move_cursor (gnect.cursor_col);

                /* and start a new game */

                if (gnect_is_player_computer (gnect.current_player)) {
                        gnect_process_move (gnect_computer_move ());
                }
                else {
                        gui_set_status_prompt (gnect.current_player);
                }

        }
}



static gint
gnect_check_computer_move (gpointer data)
{
        /* Function to hook computer move calculations
         * into the idle loop (Dave, 2001.01.18)
         */


        gint col;


        if (anim.id) return TRUE;

        col = gnect_computer_move ();

        /* in case reset while thinking */
        if (gnect.over) return FALSE;

        gnect_process_move (col);

        return FALSE;
}



static void
gnect_game_over (gint winner, gint row, gint col)
{
        gnect.over   = TRUE;
        gnect.row    = row;
        gnect.col    = col;
        gnect.winner = winner;
        gnect.score[winner]++;


        dialog_score_update ();
        gui_set_status_winner (winner, TRUE);

        if (winner != DRAWN_GAME) gfx_blink_winner (4);
}



void
gnect_process_move (gint col)
{
        gint row;
        gint len_veleng_str;


        gui_set_status (NULL, STATUS_MSG_CLEAR);

        gfx_move_cursor (col);
        if (gnect.over) return; /* in case reset while moving */

        /* if the column's not full... */
        if (!gnect_is_full_column (col)) {

                /* add this move to the Velena Engine string */
                len_veleng_str = strlen (gnect.veleng_str);
                gnect.veleng_str[len_veleng_str - 1] = '1' + col;
                gnect.veleng_str[len_veleng_str] = '0';

                DEBUG_PRINT(8, "veleng_str: %s\n", gnect.veleng_str);

                /* drop counter */
                row = gfx_drop_counter (col);
                if (gnect.over) return; /* in case reset while dropping */

                sound_event (SOUND_DROP_COUNTER);
                if (gnect_get_n_players () && strlen (gnect.veleng_str) == 3) {
                        gui_set_undo_sensitive (TRUE);
                }

                /* check for a win */
                if (gnect_is_line (gnect.current_player, row, col, LINE_LENGTH)) {

                        gui_set_hint_sensitive (FALSE);
                        gnect_game_over (gnect.current_player, row, col);

                }
                else {

                        /* check for a draw */
                        if (gnect_is_full_board ()) {

                                gui_set_hint_sensitive (FALSE);
                                gnect_game_over (DRAWN_GAME, row, col);

                        }
                        else {

                                /* if nothing interesting happened, it's the next player's turn */
                                gnect_switch_players ();

                                /* Add computer move to idle loop. (Dave) */
                                if (!gnect.over && gnect_is_player_computer (gnect.current_player)) {
                                        if (source_id !=0) {
                                                g_source_remove (source_id);
                                        }
                                        source_id = g_idle_add (gnect_check_computer_move, NULL);
                                }
                                else if (!gnect.over) {
                                        gui_set_status_prompt (gnect.current_player);
                                }

                        }
                }
        }
        else {

                /* full column, complain */
                sound_event (SOUND_CANT_MOVE);
                gui_set_status (_(" Sorry, full column"), STATUS_MSG_FLASH);

        }

}



void
gnect_hint (void)
{
        if (!gnect_is_player_computer (gnect.current_player)) {

                gchar *hint_str;
                gchar level_ch = gnect.veleng_str[0];
                gint row, col;

                gui_set_status (_(" Thinking..."), STATUS_MSG_FLASH);

                gnect.veleng_str[0] = gnect_get_veleng_level_ch (PLAYER_VELENA_STRONG);
                col = playgame (gnect.veleng_str, gnect.veleng_board);
                hint_str = g_strdup_printf (_(" Hint: Column %d"), col);

                gnect.veleng_str[0] = level_ch;

                gui_set_status (hint_str, STATUS_MSG_FLASH);
                g_free (hint_str);

                if (prefs.do_animate) {
                        gfx_move_cursor (col - 1);
                        row = gnect_get_top_used_row (col - 1) - 1;
                        gfx_blink_counter (4, gnect.current_player, row, col - 1);
                }
        }
}



static gint
gnect_undo_veleng_str (void)
{
        gint undo = strlen (gnect.veleng_str);
        gint col = -1;


        if (undo > 2) {

                undo = undo - 2;

                col = gnect.veleng_str[undo] - '1'; /* translate char '1' to int 0, '7' to 6, etc. */
                gnect.veleng_str[undo] = '0';
                gnect.veleng_str[undo + 1] = '\0';
                undo--;

        }
        return col;
}



gboolean
gnect_undo_move (gboolean is_wipe)
{
        gint col;


        col = gnect_undo_veleng_str ();
        if (col == -1) return FALSE;

        gui_set_status (NULL, STATUS_MSG_CLEAR);

        if (!gnect.over) {
                gnect_switch_players ();
                gui_set_status_prompt (gnect.current_player);
        }
        else if (!is_wipe) {
                if (gnect.score[gnect.winner]) {
                        gnect.score[gnect.winner]--;
                }
                gnect.over = FALSE;
                gnect.winner = -1;
                dialog_score_update ();
                gui_set_status_prompt (gnect.current_player);
        }

        gfx_move_cursor (col);
        gfx_suck_counter (col, is_wipe);

        DEBUG_PRINT(8, "veleng_str: %s\n", gnect.veleng_str);

        if (gnect_get_n_players () == 1
            && gnect_is_player_computer (gnect.current_player)) {

                gnect_switch_players ();
                col = gnect_undo_veleng_str ();
                if (col != -1) {
                        gfx_move_cursor (col);
                        gfx_suck_counter (col, is_wipe);
                        DEBUG_PRINT(8, "veleng_str: %s\n", gnect.veleng_str);
                }

        }

        return gnect.veleng_str[2] != '\0';
}



gboolean
gnect_is_line (gint counter, gint row, gint col, gint len)
{
        /*
         * Return TRUE if there's a line of counter based on row, col
         */


        gint r1, r2, c1, c2;

        return gnect_is_line_horizontal(counter, row, col, len, &r1, &c1, &r2, &c2)
               || gnect_is_line_vertical(counter, row,col, len, &r1, &c1, &r2, &c2)
               || gnect_is_line_diagonal1(counter, row, col, len, &r1, &c1, &r2, &c2)
               || gnect_is_line_diagonal2(counter, row, col, len, &r1, &c1, &r2, &c2);
}



gboolean
gnect_is_line_horizontal (gint counter, gint row, gint col, gint len, gint *r1, gint *c1, gint *r2, gint *c2)
{
        *r1 = *r2 = row;
        *c1 = *c2 = col;
        while (*c1 > 0 && TILE_AT(row, *c1 - 1) == counter) *c1 = *c1 - 1;
        while (*c2 < N_COLS - 1 && TILE_AT(row, *c2 + 1) == counter) *c2 = *c2 + 1;
        if (*c2 - *c1 >= len - 1) return TRUE;
        return FALSE;
}



gboolean
gnect_is_line_vertical (gint counter, gint row, gint col, gint len, gint *r1, gint *c1, gint *r2, gint *c2)
{
        *r1 = *r2 = row;
        *c1 = *c2 = col;
        while (*r1 > 1 && TILE_AT(*r1 - 1, col) == counter) *r1 = *r1 - 1;
        while (*r2 < N_ROWS - 1 && TILE_AT(*r2 + 1, col) == counter) *r2 = *r2 + 1;
        if (*r2 - *r1 >= len - 1) return TRUE;
        return FALSE;
}



gboolean
gnect_is_line_diagonal1 (gint counter, gint row, gint col, gint len, gint *r1, gint *c1, gint *r2, gint *c2)
{
        /* upper left to lower right */

        *r1 = *r2 = row;
        *c1 = *c2 = col;
        while (*c1 > 0 && *r1 > 1 && TILE_AT(*r1 - 1, *c1 - 1) == counter) {*r1 = *r1 - 1; *c1 = *c1 - 1;}
        while (*c2 < N_COLS - 1 && *r2 < N_ROWS - 1 && TILE_AT(*r2 + 1, *c2 + 1) == counter) {*r2 = *r2 + 1; *c2 = *c2 + 1;}
        if (*r2 - *r1 >= len - 1) return TRUE;
        return FALSE;
}



gboolean
gnect_is_line_diagonal2 (gint counter, gint row, gint col, gint len, gint *r1, gint *c1, gint *r2, gint *c2)
{
        /* upper right to lower left */

        *r1 = *r2 = row;
        *c1 = *c2 = col;
        while (*c1 < N_COLS - 1 && *r1 > 1 && TILE_AT(*r1 - 1, *c1 + 1) == counter) {*r1 = *r1 - 1; *c1 = *c1 + 1;}
        while (*c2 > 0 && *r2 < N_ROWS - 1 && TILE_AT(*r2 + 1, *c2 - 1) == counter) {*r2 = *r2 + 1; *c2 = *c2 - 1;}
        if (*r2 - *r1 >= len - 1) return TRUE;
        return FALSE;
}

