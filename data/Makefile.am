velenadir      = $(datadir)/gnect
velena_DATA    = white_ob.cn4

Games_in_files = gnect.desktop.in
Gamesdir       = $(datadir)/applications
Games_DATA     = $(Games_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

schemadir   = @GCONF_SCHEMA_FILE_DIR@
schema_in_files = gnect.schemas.in
schema_DATA = $(schema_in_files:.schemas.in=.schemas)
@INTLTOOL_SCHEMAS_RULE@

soundlistdir       = $(sysconfdir)/sound/events
soundlist_in_files = gnect.soundlist.in
soundlist_DATA     = $(soundlist_in_files:.soundlist.in=.soundlist)
@INTLTOOL_SOUNDLIST_RULE@

EXTRA_DIST = $(velena_DATA)     \
             $(Games_DATA)      \
             $(soundlist_DATA)  \
             $(schema_in_files)

CLEANFILES = $(schema_DATA)

install-data-local:
if GCONF_SCHEMAS_INSTALL
    GCONF_CONFIG_SOURCE=$(GCONF_SCHEMA_CONFIG_SOURCE) $(GCONFTOOL) --makefile-install-rule $(top_builddir)/gnect/data/$(schema_DATA)
endif

