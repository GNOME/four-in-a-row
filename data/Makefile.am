velenadir      = $(datadir)/gnect
velena_DATA    = white_ob.cn4.gz

Games_in_files = gnect.desktop.in.in
Gamesdir       = $(datadir)/applications
Games_DATA     = $(Games_in_files:.desktop.in.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

schemadir   = @GCONF_SCHEMA_FILE_DIR@
schema_in_files = gnect.schemas.in
schema_DATA = $(schema_in_files:.schemas.in=.schemas)
@INTLTOOL_SCHEMAS_RULE@

EXTRA_DIST = gnect-client.dsc.in \
	     gnect-server.dsc.in \
             gnect.room          \
	     $(velena_DATA)      \
             $(schema_in_files)

DISTCLEANFILES = $(schema_DATA) $(Games_DATA)

install-data-local:
if GCONF_SCHEMAS_INSTALL
	GCONF_CONFIG_SOURCE=$(GCONF_SCHEMA_CONFIG_SOURCE) $(GCONFTOOL) --makefile-install-rule $(top_builddir)/gnect/data/$(schema_DATA)
endif
if GGZ_CLIENT
	$(GGZ_CONFIG) -D --install --modfile=gnect-client.dsc --force
endif
uninstall-local:
if GGZ_CLIENT
	-$(GGZ_CONFIG) -D --remove --modfile=gnect-client.dsc
endif


if GGZ_SERVER
ggzroom_DATA = gnect.room
ggzroomdir = ${prefix}/etc/ggzd/rooms/

ggzgame_DATA = gnect-server.dsc
ggzgamedir = ${prefix}/etc/ggzd/games/
endif
