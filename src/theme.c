/* -*-mode:c; c-style:k&r; c-basic-offset:4; -*-
 *
 * gnect theme.c
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



#include <sys/types.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <dirent.h>

#include "config.h"
#include "main.h"
#include "gfx.h"
#include "gnect.h"
#include "prefs.h"




#define THEME_KEYWORD_TITLE            "Title"
#define THEME_KEYWORD_PLAYER_1         "Player1"
#define THEME_KEYWORD_PLAYER_2         "Player2"
#define THEME_KEYWORD_TILE_SET         "Tileset"
#define THEME_KEYWORD_BACKGROUND       "Background"
#define THEME_KEYWORD_GRID_RGB         "GridRGB"
#define THEME_KEYWORD_NO_GRID          "NoGrid"
#define THEME_KEYWORD_TOOLTIP          "Tooltip"

#define DEFAULT_GRID_COLOUR            "#525F6C"
#define USER_THEME_DIR                 "~/.gnect/themes"
#define USER_PIXMAP_DIR                "~/.gnect/pixmaps"




extern gint      debugging; /* gnect.c */
extern Prefs     prefs;     /* prefs.c */


Theme *theme_base    = NULL;
Theme *theme_current = NULL;


static Theme *themes = NULL;


static void      theme_free(Theme *theme);
static void      theme_create_IDs(void);
static void      theme_add(Theme *new_theme);
static Theme     *theme_first(void);
static gboolean  theme_translate_player_description(Theme *theme, gint player, gchar *str);
static guint     theme_file_parse_symbols(GScanner *scanner, Theme *new_theme);
static gboolean  theme_file_parse(const gchar *filename, Theme *new_theme);
static Theme     *theme_file_read(const gchar *pathname_data, const gchar *filename);




static gchar *descr[] = {
	"Light",
	"Dark",
	"Black",
	"White",
	"Grey",
	"Yellow",
	"Red",
	"Blue",
	"Green",
	"Orange",
	"Purple",
	"Pink",
	"Violet",
	"Brown"
};
#define DESCR_LIGHT              0
#define DESCR_DARK               1
#define DESCR_BLACK              2
#define DESCR_WHITE              3
#define DESCR_GREY               4
#define DESCR_YELLOW             5
#define DESCR_RED                6
#define DESCR_BLUE               7
#define DESCR_GREEN              8
#define DESCR_ORANGE             9
#define DESCR_PURPLE             10
#define DESCR_PINK               11
#define DESCR_VIOLET             12
#define DESCR_BROWN              13
#define N_PLAYER_DESCRIPTIONS    14


typedef enum {
	THEME_TOKEN_FIRST = G_TOKEN_LAST,
	THEME_TOKEN_TITLE,
	THEME_TOKEN_TILE_SET,
	THEME_TOKEN_PLAYER_1,
	THEME_TOKEN_PLAYER_2,
	THEME_TOKEN_BACKGROUND,
	THEME_TOKEN_GRID_RGB,
	THEME_TOKEN_TOOLTIP,
	THEME_TOKEN_NO_GRID,
	THEME_TOKEN_LAST
} ThemeTokenType;


static const struct {
   gchar *name;
   guint  token;
}
symbols[] = {
   { THEME_KEYWORD_TITLE,      THEME_TOKEN_TITLE },
   { THEME_KEYWORD_TILE_SET,   THEME_TOKEN_TILE_SET },
   { THEME_KEYWORD_PLAYER_1,   THEME_TOKEN_PLAYER_1 },
   { THEME_KEYWORD_PLAYER_2,   THEME_TOKEN_PLAYER_2 },
   { THEME_KEYWORD_BACKGROUND, THEME_TOKEN_BACKGROUND },
   { THEME_KEYWORD_GRID_RGB,   THEME_TOKEN_GRID_RGB },
   { THEME_KEYWORD_TOOLTIP,    THEME_TOKEN_TOOLTIP },
   { THEME_KEYWORD_NO_GRID,    THEME_TOKEN_NO_GRID }
};



static const guint n_symbols = sizeof (symbols) / sizeof (symbols[0]);




gboolean theme_init(const gchar *fname_theme)
{
	/* build a list of available themes,
	 * try to set theme_current to the theme specified by fname_theme
	 * (if fname_theme isn't NULL) or prefs.fname_theme,
	 * return TRUE if at least one theme is available
	 */


	Theme         *theme = NULL;
	gchar         *dname;
	gint          reading;
	DIR           *dir;
	struct dirent *e;


	DEBUG_PRINT(1, "theme_init\n");

	theme_base = NULL;
	themes     = NULL;

	dname = g_strdup(PACKAGE_THEME_DIR);

	/* look for themes in PACKAGE_THEME_DIR (reading=2)
	 * and USER_THEME_DIR (reading=1)
	 */

	reading = 2;
	while(reading) {

		dir = opendir(dname);
		if (!dir) {

			if (reading == 2) WARNING_PRINT("opendir failed (%s)\n", dname);

		}
		else {

			while ((e = readdir(dir)) != NULL) {

				gchar *fname = g_strdup(e->d_name);

				if (strstr(e->d_name, ".gnect")) {
					if ((theme = theme_file_read(dname, fname))) {
						/* theme okay */
						theme_add(theme);
					}
				}

				g_free(fname);

			}

			closedir(dir);

		}

		g_free(dname);

		reading--;

		if (reading) {
			/* check for extra themes in home directory */
			dname = gnect_fname_expand(g_strdup(USER_THEME_DIR));
		}

	}

	theme_base = themes;

	if (theme_base) {

		theme_base = theme_first();
		theme_create_IDs();

		if (fname_theme) {
			if ( !(theme_current = theme_get_ptr_from_fname(fname_theme)) ) {
				WARNING_PRINT("theme not available (%s)\n", fname_theme);
			}
		}
		if ( !theme_current && !(theme_current = theme_get_ptr_from_fname(prefs.fname_theme)) ) {
			WARNING_PRINT("theme not available (%s)\n", prefs.fname_theme);
			theme_current = theme_base;
		}

		return(TRUE);

	}
	return(FALSE);
}



static void theme_free(Theme *theme)
{
	Theme *next;


	DEBUG_PRINT(1, "theme_free\n");
	if (theme) {

		while(theme->prev) theme = theme->prev; /* don't use theme_base here */

		while(theme) {

			DEBUG_PRINT(2, "  %d\t%s\n", theme->id, theme->title);
			g_free(theme->title);
			g_free(theme->fname);
			g_free(theme->fname_tileset);
			g_free(theme->fname_background);
			g_free(theme->descr_player1);
			g_free(theme->descr_player2);
			g_free(theme->gridRGB);
			g_free(theme->tooltip);

			next = theme->next;
			g_free(theme);
			theme = next;
		}

	}
}



void theme_free_all(void)
{
	theme_free(theme_base);
}



static Theme *theme_first(void)
{
	Theme *theme = theme_base;


	if (theme) {
		while(theme->prev) {
			theme = theme->prev;
		}
	}
	return(theme);
}



static void theme_create_IDs(void)
{
	Theme *theme = theme_base;
	gint theme_id = 0;


	DEBUG_PRINT(1, "theme_create_IDs\n");
	while(theme) {
		DEBUG_PRINT(2, "\t%d\t%s\n", theme_id, theme->title);
		theme->id = theme_id;
		theme_id++;
		theme = theme->next;
	}
}



static void theme_add(Theme *new_theme)
{
	/* insert new_theme alphabetically, according to title */


	if (!themes) {
		themes = new_theme;
		theme_base = new_theme;
	}
	else {

		gboolean end_of_list = FALSE;
		gboolean add_before  = FALSE;


		themes = theme_first();
		while(!end_of_list) {
			if ((add_before = strcasecmp(new_theme->title, themes->title) <= 0)) {
				break;
			}
			if (!(end_of_list = (themes->next == NULL))) {
				themes = themes->next;
			}
		}
		if (add_before) {
			new_theme->next = themes;
			new_theme->prev = themes->prev;
			if (themes->prev) {
				themes->prev->next = new_theme;
			}
			themes->prev = new_theme;
		}
		else {
			themes->next = new_theme;
			new_theme->prev = themes;
		}
	}
}



Theme *theme_get_ptr_from_fname(const gchar *fname)
{
	Theme *theme = theme_base;


	if (fname) {
		while(theme) {
			if (strcmp(fname, theme->fname) == 0) return(theme);
			theme = theme->next;
		}
	}
	return(NULL);
}



static gint theme_get_player_description_id(const gchar *str)
{
	gint i;


	for (i = 0; i < N_PLAYER_DESCRIPTIONS; i++) {
		if (!strcasecmp(str, descr[i])) return(i);
	}
	return(-1);
}



static gboolean theme_translate_player_description(Theme *theme, gint player, gchar *str)
{
	/* I don't think I understand gettext_noop(), so here's this... */

	gchar *descr_str;
	gint id;


	id = theme_get_player_description_id(str);

	switch(id) {
	case DESCR_LIGHT :
		descr_str = g_strdup(_("Light"));
		break;
	case DESCR_DARK :
		descr_str = g_strdup(_("Dark"));
		break;
	case DESCR_BLACK :
		descr_str = g_strdup(_("Black"));
		break;
	case DESCR_WHITE :
		descr_str = g_strdup(_("White"));
		break;
	case DESCR_GREY :
		descr_str = g_strdup(_("Grey"));
		break;
	case DESCR_YELLOW :
		descr_str = g_strdup(_("Yellow"));
		break;
	case DESCR_RED :
		descr_str = g_strdup(_("Red"));
		break;
	case DESCR_BLUE :
		descr_str = g_strdup(_("Blue"));
		break;
	case DESCR_GREEN :
		descr_str = g_strdup(_("Green"));
		break;
	case DESCR_ORANGE :
		descr_str = g_strdup(_("Orange"));
		break;
	case DESCR_PURPLE :
		descr_str = g_strdup(_("Purple"));
		break;
	case DESCR_PINK :
		descr_str = g_strdup(_("Pink"));
		break;
	case DESCR_VIOLET :
		descr_str = g_strdup(_("Violet"));
		break;
	case DESCR_BROWN :
		descr_str = g_strdup(_("Brown"));
		break;
	default :
		return(FALSE);
		break;
	}

	if (player == PLAYER_1) {
		g_free(theme->descr_player1);
		theme->descr_player1 = descr_str;
	}
	else {
		g_free(theme->descr_player2);
		theme->descr_player2 = descr_str;
	}

	return(TRUE);
}



static guint theme_file_parse_symbols(GScanner *scanner, Theme *new_theme)
{
	guint symbol;


	g_scanner_get_next_token(scanner);
	symbol = scanner->token;
	if (scanner->token == G_TOKEN_EQUAL_SIGN) {
		g_scanner_get_next_token(scanner);
		return(G_TOKEN_NONE);
	}
	else if (symbol < THEME_TOKEN_FIRST || symbol > THEME_TOKEN_LAST) {
		return(G_TOKEN_SYMBOL);
	}


	/* the "NoGrid" keyword takes no value... */

	if (symbol != THEME_TOKEN_NO_GRID) {

		/* ...all other keywords do */

		g_scanner_get_next_token(scanner);
		if (scanner->token != G_TOKEN_EQUAL_SIGN) {
			return(G_TOKEN_EQUAL_SIGN);
		}

		g_scanner_get_next_token(scanner);
		if (scanner->token != G_TOKEN_STRING) {
			return(G_TOKEN_STRING);
		}

	}


	switch (symbol) {
	case THEME_TOKEN_TITLE :
		g_free(new_theme->title); /* free'd in case of duplicate entries */
		new_theme->title = g_strstrip(g_strdup(scanner->value.v_string));
		break;
	case THEME_TOKEN_TILE_SET :
		g_free(new_theme->fname_tileset);
		new_theme->fname_tileset = g_strstrip(g_strdup(scanner->value.v_string));
		break;
	case THEME_TOKEN_PLAYER_1 :
		if (!theme_translate_player_description(new_theme, PLAYER_1, g_strstrip(g_strdup(scanner->value.v_string)))) {
			WARNING_PRINT("illegal value for Player1 in theme file\n");
		}
		break;
	case THEME_TOKEN_PLAYER_2 :
		if (!theme_translate_player_description(new_theme, PLAYER_2, g_strstrip(g_strdup(scanner->value.v_string)))) {
			WARNING_PRINT("illegal value for Player1 in theme file\n");
		}
		break;
	case THEME_TOKEN_BACKGROUND :
		g_free(new_theme->fname_background);
		new_theme->fname_background = g_strstrip(g_strdup(scanner->value.v_string));
		break;
	case THEME_TOKEN_GRID_RGB :
		g_free(new_theme->gridRGB);
		new_theme->gridRGB = g_strstrip(g_strdup(scanner->value.v_string));
		break;
	case THEME_TOKEN_TOOLTIP :
		g_free(new_theme->tooltip);
		new_theme->tooltip = g_strstrip(g_strdup(scanner->value.v_string));
		break;
	case THEME_TOKEN_NO_GRID :
		g_free(new_theme->gridRGB);
		new_theme->gridRGB = NULL;
		break;
	default:
		break;
	}

   return(G_TOKEN_NONE);
}



static gboolean theme_file_parse(const gchar *fname, Theme *new_theme)
{
	GScanner *scanner;
	guint i, expected;
	gint fd;


	if ( (fd = open(fname, O_RDONLY)) < 0 ) return(FALSE);

	scanner = g_scanner_new(NULL);

	scanner->config->cset_identifier_nth   = (G_CSET_a_2_z G_CSET_A_2_Z "~/&()-_+:.%#0123456789");
	scanner->config->cset_identifier_first = (G_CSET_a_2_z G_CSET_A_2_Z "~/&()-_+:.%0123456789");
	scanner->config->scan_identifier       = TRUE;
	scanner->config->scan_symbols          = TRUE;
	scanner->config->scan_string_dq        = TRUE;
	scanner->config->symbol_2_token        = TRUE;
	scanner->config->identifier_2_string   = TRUE;
	scanner->config->case_sensitive        = FALSE;
	scanner->input_name = fname;

	for (i = 0; i < n_symbols; i++) {
		g_scanner_scope_add_symbol(scanner, 0, symbols[i].name, 
                                           GINT_TO_POINTER(symbols[i].token));
	}

	g_scanner_input_file(scanner, fd);

	do {

		expected = theme_file_parse_symbols(scanner, new_theme);

		if (expected == G_TOKEN_SYMBOL) {
			g_scanner_unexp_token(scanner, expected, NULL, "symbol", NULL, NULL, FALSE);
		}
		else if (expected == G_TOKEN_STRING) {
			g_scanner_unexp_token(scanner, expected, NULL, "string", NULL, NULL, FALSE);
		}
		else if (expected == G_TOKEN_EQUAL_SIGN) {
			g_scanner_unexp_token(scanner, expected, NULL, "=", NULL, NULL, FALSE);
		}
		g_scanner_peek_next_token(scanner);

	} while (scanner->next_token != G_TOKEN_EOF && scanner->next_token != G_TOKEN_ERROR);


	if (expected != G_TOKEN_NONE) {
		g_scanner_unexp_token(scanner, expected, NULL, "symbol", NULL, NULL, TRUE);
	}


	g_scanner_destroy(scanner);
	close(fd);

	return(TRUE);
}



static Theme *theme_file_read(const gchar *pathname_data, const gchar *filename)
{
	/* create a new empty theme,
	 *   build a complete file name,
	 *   call theme_file_parse to fill in the new theme,
	 *   check the values obtained,
	 *   return the new theme if all okay, else NULL
	 */

	Theme     *theme;
	gchar     *fname;
	gchar     *user_data_dir = gnect_fname_expand(g_strdup(USER_THEME_DIR));
	gchar     *user_pixmap_dir = gnect_fname_expand(g_strdup(USER_PIXMAP_DIR));
	gboolean  tileset_exists = TRUE, background_exists = TRUE;



	/* allocate a new, NULL-filled theme info structure */
	theme = g_new0(Theme, 1);
	theme->gridRGB = g_strdup(DEFAULT_GRID_COLOUR);
	theme->is_user_theme = (strcasecmp(pathname_data, user_data_dir) == 0);


	/* get the new theme's full filename */
	fname = g_strdup_printf("%s/%s", pathname_data, filename);


	/* open and parse the file, filling in the new theme */
	if (!theme_file_parse(fname, theme)) {
		WARNING_PRINT("theme_file_read failed (%s)\n", fname);
		g_free(fname);
		g_free(user_data_dir);
		g_free(user_pixmap_dir);
		theme_free(theme);
		return(NULL);
	}


	/* make sure the specified tile set exists */
	if (theme->fname_tileset && theme->fname_tileset[0] != '\0') {
		if (theme->is_user_theme) {
			fname = g_strdup_printf("%s%s%s", user_pixmap_dir, G_DIR_SEPARATOR_S, theme->fname_tileset);
			tileset_exists = gnect_file_exists(fname);
			if (!tileset_exists) {
				/* not in user dir - try installed pixmap dir */
				g_free(fname);
				fname = g_strdup_printf("%s%s", PACKAGE_PIXMAP_DIR, theme->fname_tileset);
				tileset_exists = gnect_file_exists(fname);
			}
		}
		else {
			fname = g_strdup_printf("%s%s", PACKAGE_PIXMAP_DIR, theme->fname_tileset);
			tileset_exists = gnect_file_exists(fname);
		}
		g_free(fname);
	}


	/* check that the specified background exists */
	if (tileset_exists) {
		if (theme->fname_background && theme->fname_background[0] != '\0') {
			if (theme->is_user_theme) {
				fname = g_strdup_printf("%s%s%s", user_pixmap_dir, G_DIR_SEPARATOR_S, theme->fname_background);
				background_exists = gnect_file_exists(fname);
				if (!background_exists) {
					/* not in user dir - try installed pixmap dir */
					g_free(fname);
					fname = g_strdup_printf("%s%s", PACKAGE_PIXMAP_DIR, theme->fname_background);
					background_exists = gnect_file_exists(fname);
				}
			}
			else {
				fname = g_strdup_printf("%s%s", PACKAGE_PIXMAP_DIR, theme->fname_background);
				background_exists = gnect_file_exists(fname);
			}
			g_free(fname);
		}
		if (!background_exists) {
			/* complain, but continue anyway, if we can't get the background image */
			WARNING_PRINT("background image (%s) for theme (%s) does not exist\n", theme->fname_background, filename);
			g_free(theme->fname_background);
			theme->fname_background = NULL;
		}
	}

	g_free(user_data_dir);
	g_free(user_pixmap_dir);


	/* check that required items were found  */
	if (theme->title == NULL || theme->title[0] == '\0' ||
		theme->descr_player1 == NULL || theme->descr_player1[0] == '\0' ||
		theme->descr_player2 == NULL || theme->descr_player2[0] == '\0' ||
		theme->fname_tileset == NULL || theme->fname_tileset[0] == '\0' ||
		!tileset_exists ) {

		if (tileset_exists) {
			WARNING_PRINT("error in theme (%s) (required item missing?)\n", filename);
		}
		else {
			WARNING_PRINT("tile set specified in theme (%s) does not exist\n", filename);
		}

		/* required items missing - toss this theme */
		theme_free(theme);

		return(NULL);
	}

	/* all okay */
	theme->fname = g_strdup(filename);

	return(theme);
}



gboolean theme_load(Theme* theme)
{
	/* Get image filenames then switch to the new theme */

	gchar     *user_pixmap_dir;
	gchar     *fname_tileset;
	gchar     *fname_background = NULL;
	gboolean  okay;


	if (!theme) {
		/* should never happen */
		ERROR_PRINT("theme_load(NULL)\n");
		return(FALSE);
	}

	DEBUG_PRINT(1, "theme_load (%s)\n", theme->fname);

	if (theme->is_user_theme) {

		user_pixmap_dir = gnect_fname_expand(g_strdup(USER_PIXMAP_DIR));
		fname_tileset = g_strdup_printf("%s%s%s", user_pixmap_dir, G_DIR_SEPARATOR_S, theme->fname_tileset);
		if (!gnect_file_exists(fname_tileset)) {
			g_free(fname_tileset);
			fname_tileset = g_strdup_printf("%s%s", PACKAGE_PIXMAP_DIR, theme->fname_tileset);
		}

		if (theme->fname_background) {

			fname_background = g_strdup_printf("%s%s%s", user_pixmap_dir, G_DIR_SEPARATOR_S, theme->fname_background);
			if (!gnect_file_exists(fname_background)) {
				g_free(fname_background);
				fname_background = g_strdup_printf("%s%s", PACKAGE_PIXMAP_DIR, theme->fname_background);
			}

		}
		g_free(user_pixmap_dir);

	}
	else {

		fname_tileset = g_strdup_printf("%s%s", PACKAGE_PIXMAP_DIR, theme->fname_tileset);
		if (!gnect_file_exists(fname_tileset)) {
			g_free(fname_tileset);
			return(FALSE);
		}

		if (theme->fname_background) {

			fname_background = g_strdup_printf("%s%s", PACKAGE_PIXMAP_DIR, theme->fname_background);
			if (!gnect_file_exists(fname_background)) {
				g_free(fname_background);
				fname_background = NULL;
			}

		}

	}

	if ( (okay = gfx_load(theme, fname_tileset, fname_background)) ) {
		prefs.descr_player1 = theme->descr_player1;
		prefs.descr_player2 = theme->descr_player2;
		theme_current = theme;
	}

	g_free(fname_tileset);
	g_free(fname_background);


	return(okay);
}
