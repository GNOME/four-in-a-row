bin_PROGRAMS = gnect
ggzexecmod_PROGRAMS =

if GGZ_SERVER
ggzexecmod_PROGRAMS += gnectd
gnectd_SOURCES = server.h   \
		 server.c   \
		 main.h	    \
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

gnectd_CPPFLAGS = \
	-I$(top_srcdir) \
	$(AM_CPPFLAGS)

gnectd_CFLAGS = \
	$(GGZ_GTK_INCLUDES) $(GGZMOD_INCLUDES) $(GGZCORE_INCLUDES) \
	$(LIBGGZ_INCLUDES) $(GGZDMOD_INCLUDES) \
	$(GNOME_GAMES_CFLAGS) \
	$(AM_CFLAGS)

gnectd_LDADD = \
	$(top_builddir)/libgames-support/libgames-support.la         \
	$(GNOME_GAMES_LIBS)     \
	$(INTLLIBS) 		\
	$(LIB_GGZDMOD)
endif

if GGZ_CLIENT
GGZ_FILES =	connectx_client.h \
		connectx_client.c \
		ggz-network.h \
		ggz-network.c \
		$(NULL)
endif

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
                heurist.h  \
                heurist.c  \
                ia_main.c  \
                pbsolver.c \
                playgame.c \
                pnsearch.h \
                proto.h    \
                rules.h	   \
		$(GGZ_FILES)

gnect_CPPFLAGS = \
	-I$(top_srcdir) \
	$(AM_CPPFLAGS)

gnect_CFLAGS = \
	$(GGZ_GTK_INCLUDES) $(GGZMOD_INCLUDES) $(GGZCORE_INCLUDES) \
	$(LIBGGZ_INCLUDES) $(GGZDMOD_INCLUDES) \
	$(GNOME_GAMES_CFLAGS) \
	$(AM_CFLAGS)

gnect_LDADD = \
	$(top_builddir)/libgames-support/libgames-support.la \
	$(GNOME_GAMES_LIBS) \
	$(INTLLIBS) \
	$(LIB_GGZMOD) \
	$(LIB_GGZ_GTK)
