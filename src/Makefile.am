bin_PROGRAMS = gnect

gnect_SOURCES = main.h     \
                main.c     \
                gnect.h    \
                gnect.c    \
                dialog.h   \
                dialog.c   \
                gui.h      \
                gui.c      \
                gfx.h      \
                gfx.c      \
                prefs.h    \
                prefs.c    \
                theme.h    \
                theme.c    \
                sound.h    \
                sound.c    \
                brain.h    \
                brain.c    \
                adjmtrx.c  \
                bintree.c  \
                con4vals.h \
                connect4.h \
                connect4.c \
                evaluate.c \
                heurist.h  \
                heurist.c  \
                ia_main.c  \
                pbsolver.c \
                playgame.c \
                pnsearch.h \
                proto.h    \
                rules.h

INCLUDES = -I.. \
	-I$(top_srcdir)/libgames-support                \
	-DGNOMELOCALEDIR=\""$(datadir)/locale"\" \
	-DDATADIR=\""$(datadir)"\"		   \
	-DGNECT_DATA_DIR=\""$(datadir)/"\" \
	$(GNOME_GAMES_CFLAGS)

gnect_LDADD = \
	../../libgames-support/libgames-support.la         \
	$(GNOME_GAMES_LIBS)     \
	$(INTLLIBS)

