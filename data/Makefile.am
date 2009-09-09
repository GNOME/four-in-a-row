NULL =

velenadir      = $(pkgdatadir)/gnect
velena_DATA    = white_ob.cn4.gz

Games_in_files = gnect.desktop.in.in
Gamesdir       = $(datadir)/applications
Games_DATA     = $(Games_in_files:.desktop.in.in=.desktop)

schema_in_files = gnect.schemas.in
if HAVE_GNOME
schemadir = $(GCONF_SCHEMA_FILE_DIR)
schema_DATA = $(schema_in_files:.schemas.in=.schemas)
endif

man_MANS     = gnect.6

if GGZ_SERVER
ggzroom_in_files = gnect.room.in
ggzroom_DATA = $(ggzroom_in_files:.room.in=.room)
ggzroomdir = ${ggzdconfdir}/rooms/

ggzserver_dscdir = ${ggzdconfdir}/games/
ggzserver_dsc_in_files = gnect-server.dsc.in
ggzserver_dsc_DATA = $(ggzserver_dsc_in_files:.dsc.in=.dsc)
endif # GGZ_SERVER

if GGZ_CLIENT
ggzclient_dsc_in_files = gnect-client.dsc.in
endif # GGZ_CLIENT

EXTRA_DIST = gnect-client.dsc.in \
	     gnect-server.dsc.in \
             gnect.room.in \
	     $(velena_DATA) \
             $(schema_in_files) \
             $(man_MANS)


CLEANFILES = \
	$(ggzroom_DATA) \
	$(ggzserver_dsc_in_files:.dsc.in=.dsc) \
	$(ggzclient_dsc_in_files:.dsc.in=.dsc) \
	$(NULL)

DISTCLEANFILES = $(schema_DATA) $(Games_DATA)

install-data-local: $(ggzclient_dsc_in_files:.dsc.in=.dsc)
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

@INTLTOOL_DESKTOP_RULE@
@INTLTOOL_SCHEMAS_RULE@
@GNOME_GAMES_GGZ_INTLTOOL_ROOM_RULE@
@GNOME_GAMES_GGZ_DSC_RULE@
