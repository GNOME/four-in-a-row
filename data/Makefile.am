SUBDIRS = icons

gsettings_in_file = org.gnome.four-in-a-row.gschema.xml.in
gsettings_SCHEMAS = $(gsettings_in_file:.xml.in=.xml)
@INTLTOOL_XML_NOMERGE_RULE@
@GSETTINGS_RULES@

pixmapdir = $(datadir)/four-in-a-row
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

soundsdir = $(datadir)/four-in-a-row/sounds
sounds_DATA = \
	bad.ogg \
	bonus.ogg \
	reverse.ogg \
	slide.ogg

velenadir      = $(datadir)/four-in-a-row
velena_DATA    = white_ob.cn4.gz

desktop_in_files = gnect.desktop.in.in
desktopdir       = $(datadir)/applications
desktop_DATA     = $(desktop_in_files:.desktop.in.in=.desktop)

man_MANS     = four-in-a-row.6

EXTRA_DIST = $(pixmap_DATA) \
             $(sounds_DATA) \
             $(velena_DATA) \
             $(desktop_in_files) \
             $(gsettings_in_file) \
             $(man_MANS)

CLEANFILES = $(gsettings_SCHEMAS) $(desktop_DATA)
DISTCLEANFILES = $(gsettings_SCHEMAS) $(desktop_DATA)

@INTLTOOL_DESKTOP_RULE@

-include $(top_srcdir)/git.mk
