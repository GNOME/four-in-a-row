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
	-DGNOMELOCALEDIR=\""$(datadir)/locale"\" \
    	-DGNECT_DATA_DIR=\""$(datadir)/"\" \
	$(GNOME_GAMES_CFLAGS) \
	-DG_DISABLE_DEPRECATED -DGDK_DISABLE_DEPRECATED \
	-DGTK_DISABLE_DEPRECATED -DGNOME_DISABLE_DEPRECATED

gnect_LDADD = \
	$(GNOME_GAMES_LIBS)     \
	$(INTLLIBS)

