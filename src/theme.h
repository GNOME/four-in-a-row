/*
 * gnect theme.h
 *
 */



#ifndef _GNECT_THEME_H_
#define _GNECT_THEME_H_


typedef struct _Theme Theme;

struct _Theme {
	gint     id;
	gchar    *title;
	gchar    *fname;
	gchar    *fname_tileset;
	gchar    *fname_background;
	gchar    *descr_player1;
	gchar    *descr_player2;
	gchar    *tooltip;
	gchar    *gridRGB;
	gboolean is_user_theme;
	Theme    *prev;
	Theme    *next;
};


gboolean  theme_init(const gchar *fname_theme);
void      theme_free_all(void);
Theme     *theme_get_ptr_from_fname(const gchar *fname_theme);
gboolean  theme_load(Theme* theme);


#endif
