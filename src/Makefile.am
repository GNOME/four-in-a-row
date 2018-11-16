bin_PROGRAMS = four-in-a-row

check_PROGRAMS = ai-test

four_in_a_row_SOURCES = \
		games-controls.vala \
		ai.vala \
		main.vala \
		prefs.vala \
		gfx.vala \
		theme.vala

four_in_a_row_CPPFLAGS = \
	-I$(top_srcdir)

four_in_a_row_CFLAGS = \
	-DDATA_DIRECTORY=\"$(datadir)/four-in-a-row\" \
	-DSOUND_DIRECTORY=\"$(datadir)/four-in-a-row/sounds\" \
	-DLOCALEDIR=\"$(datadir)/locale\" \
	-DICON_THEME_DIRECTORY="\"$(datadir)/icons\"" \
	-DGETTEXT_PACKAGE=$GETTEXT_PACKAGE \
	$(FOUR_IN_A_ROW_CFLAGS)

four_in_a_row_LDADD = \
	$(FOUR_IN_A_ROW_LIBS)

four_in_a_row_VALAFLAGS = \
		--pkg gtk+-3.0 \
		--pkg libcanberra-gtk \
		--pkg libcanberra \
		--vapidir . \
		--pkg temp

ai_test_SOURCES = \
	ai.vala \
	test-ai.vala

ai_test_CPPFLAGS = \
	$(FOUR_IN_A_ROW_CFLAGS)

ai_test_LDADD = \
	$(FOUR_IN_A_ROW_LIBS)

check-local: $(check_PROGRAMS)
	$(GTESTER) --keep-going --verbose $(check_PROGRAMS)

EXTRA_DIST = $(BUILT_SOURCES)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	four_in_a_row_vala.stamp

-include $(top_srcdir)/git.mk
