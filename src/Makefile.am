bin_PROGRAMS = gnect

gnect_SOURCES = main.h     \
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
                games-fullscreen-action.c \
                games-fullscreen-action.h \
                games-gridframe.c \
                games-gridframe.h \
                heurist.h  \
                heurist.c  \
                ia_main.c  \
                pbsolver.c \
                playgame.c \
                pnsearch.h \
                proto.h    \
                rules.h

gnect_CPPFLAGS = \
	-I$(top_srcdir) \
	$(AM_CPPFLAGS)

gnect_CFLAGS = \
	-DDATA_DIRECTORY=\"$(datadir)/gnect\" \
	-DSOUND_DIRECTORY=\"$(datadir)/gnect/sounds\" \
	-DLOCALEDIR=\"$(datadir)/locale\" \
	$(GTK_CFLAGS) \
	$(RSVG_CFLAGS) \
	$(CANBERRA_GTK_CFLAGS) \
	$(AM_CFLAGS)

gnect_LDADD = \
	$(top_builddir)/libgames-support/libgames-support.la \
	$(GTK_LIBS) \
	$(RSVG_LIBS) \
	$(CANBERRA_GTK_LIBS) \
	$(INTLLIBS) \
	-lz

-include $(top_srcdir)/git.mk
