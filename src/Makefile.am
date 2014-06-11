bin_PROGRAMS = four-in-a-row

check_PROGRAMS = ai-test

four_in_a_row_SOURCES = main.h     \
                main.c     \
                gfx.h      \
                gfx.c      \
                prefs.h    \
                prefs.c    \
                theme.c    \
                theme.h    \
                games-controls.c \
                games-controls.h \
                games-gridframe.c \
                games-gridframe.h \
                games-stock.c \
                games-stock.h \
                rules.h \
                $(ai_C) \
                $(ai_HEADER)

four_in_a_row_CPPFLAGS = \
	-I$(top_srcdir)

four_in_a_row_CFLAGS = \
	-DDATA_DIRECTORY=\"$(datadir)/four-in-a-row\" \
	-DSOUND_DIRECTORY=\"$(datadir)/four-in-a-row/sounds\" \
	-DLOCALEDIR=\"$(datadir)/locale\" \
	-DICON_THEME_DIRECTORY="\"$(datadir)/icons\"" \
	$(FOUR_IN_A_ROW_CFLAGS)

four_in_a_row_LDADD = \
	$(FOUR_IN_A_ROW_LIBS)

ai_VALA = ai.vala

ai_HEADER = ai.h

ai_C = $(ai_VALA:.vala=.c)

$(ai_HEADER): $(ai_VALA)
	$(V_VALAC) $(VALAC) -C --basedir=$(srcdir) --directory=$(builddir) --header=ai.h \
		--pkg glib-2.0 --pkg gio-2.0 --pkg posix --use-header $(VALAFLAGS) $^

$(ai_C) : $(ai_HEADER)

ai_test_SOURCES = \
	ai.vala \
	test-ai.vala

ai_test_CPPFLAGS = \
	$(FOUR_IN_A_ROW_CFLAGS)

ai_test_LDADD = \
	$(FOUR_IN_A_ROW_LIBS)

check-local: $(check_PROGRAMS)
	$(GTESTER) --keep-going --verbose $(check_PROGRAMS)

BUILT_SOURCES = \
	$(ai_C) \
	$(ai_HEADER)

EXTRA_DIST = $(BUILT_SOURCES)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	four_in_a_row_vala.stamp

-include $(top_srcdir)/git.mk
