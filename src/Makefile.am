if GGZ_SERVER
bin_PROGRAMS = gnect gnectd
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

gnectd_LDFLAGS = @GGZDMOD_LDFLAGS@

gnectd_LDADD = \
	../../libgames-support/libgames-support.la         \
	$(GNOME_GAMES_LIBS)     \
	$(INTLLIBS) 		\
	@LIB_GGZDMOD@
else
bin_PROGRAMS = gnect 
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

INCLUDES = -I.. \
	-I$(top_srcdir)/libgames-support                \
	-DGNOMELOCALEDIR=\""$(datadir)/locale"\" \
	-DDATADIR=\""$(datadir)"\"         \
	-DGNECT_DATA_DIR=\""$(datadir)/"\" \
	$(GNOME_GAMES_CFLAGS) \
	$(GGZMOD_INCLUDES) $(GGZ_GTK_INCLUDES) $(GGZCORE_INCLUDES)\
	$(LIBGGZ_INCLUDES) $(GGZDMOD_INCLUDES)

gnect_LDFLAGS = $(GGZMOD_LDFLAGS)
gnect_LDADD = \
	../../libgames-support/libgames-support.la         \
	$(GNOME_GAMES_LIBS)     \
	$(INTLLIBS) \
	$(LIB_GGZMOD) \
	$(LIB_GGZ_GTK)

