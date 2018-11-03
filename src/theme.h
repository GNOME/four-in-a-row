/* theme.h */
#ifndef THEME_H
#define THEME_H

#include "main.h"

typedef struct _Theme Theme;
struct _Theme {
  const gchar *title;
  const gchar *fname_tileset;
  const gchar *fname_bground;
  const gchar *grid_color;
  const gchar *player1;
  const gchar *player2;
  const gchar *player1_win;
  const gchar *player2_win;
  const gchar *player1_turn;
  const gchar *player2_turn;
};


const gchar *theme_get_player (PlayerID who);
const gchar *theme_get_player_win (PlayerID who);
const gchar *theme_get_player_turn (PlayerID who);
const gchar *theme_get_title (gint id);

#endif
