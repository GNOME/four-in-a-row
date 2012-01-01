SUBDIRS = icons

pixmapdir = $(datadir)/gnect
pixmap_DATA = \
    tileset_50x50_sunspot.svg \
    tileset_50x50_catseyes.png \
    tileset_50x50_square.png \
    tileset_50x50_glassy.png \
    tileset_50x50_hcontrast.svg \
    tileset_50x50_hcinverse.svg \
    bg_grotty.jpg \
    bg_nightfall.jpg \
    bg_toplight.png

velenadir      = $(datadir)/gnect
velena_DATA    = white_ob.cn4.gz

desktop_in_files = gnect.desktop.in.in
desktopdir       = $(datadir)/applications
desktop_DATA     = $(desktop_in_files:.desktop.in.in=.desktop)

schema_in_files = gnect.schemas.in
if HAVE_GNOME
schemadir = $(GCONF_SCHEMA_FILE_DIR)
schema_DATA = $(schema_in_files:.schemas.in=.schemas)
endif

man_MANS     = gnect.6

EXTRA_DIST = $(pixmap_DATA) \
             $(velena_DATA) \
             $(desktop_in_files) \
             $(schema_in_files) \
             $(man_MANS)

DISTCLEANFILES = $(schema_DATA) $(desktop_DATA)

install-data-local: 
if GCONF_SCHEMAS_INSTALL
	GCONF_CONFIG_SOURCE=$(GCONF_SCHEMA_CONFIG_SOURCE) $(GCONFTOOL) --makefile-install-rule $(top_builddir)/gnect/data/$(schema_DATA)
endif

@INTLTOOL_DESKTOP_RULE@
@INTLTOOL_SCHEMAS_RULE@

-include $(top_srcdir)/git.mk
