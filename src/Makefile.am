bin_PROGRAMS = four-in-a-row

four_in_a_row_SOURCES = main.h     \
                main.c     \
                gfx.h      \
                gfx.c      \
                prefs.h    \
                prefs.c    \
                theme.c    \
                theme.h    \
                adjmtrx.c  \
                bintree.c  \
                con4vals.h \
                connect4.h \
                connect4.c \
                evaluate.c \
                games-controls.c \
                games-controls.h \
                games-fullscreen-action.c \
                games-fullscreen-action.h \
                games-gridframe.c \
                games-gridframe.h \
                games-stock.c \
                games-stock.h \
                heurist.h  \
                heurist.c  \
                ia_main.c  \
                pbsolver.c \
                playgame.c \
                pnsearch.h \
                proto.h    \
                rules.h

four_in_a_row_CPPFLAGS = \
	-I$(top_srcdir) \
	$(AM_CPPFLAGS)

four_in_a_row_CFLAGS = \
	-DDATA_DIRECTORY=\"$(datadir)/four-in-a-row\" \
	-DSOUND_DIRECTORY=\"$(datadir)/four-in-a-row/sounds\" \
	-DLOCALEDIR=\"$(datadir)/locale\" \
	-DICON_THEME_DIRECTORY="\"$(datadir)/icons\"" \
	$(FOUR_IN_A_ROW_CFLAGS)

four_in_a_row_LDADD = \
	$(FOUR_IN_A_ROW_LIBS)
	-lz

-include $(top_srcdir)/git.mk
