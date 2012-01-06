SUBDIRS = icons

gsettings_in_file = org.gnome.gnect.gschema.xml.in
gsettings_SCHEMAS = $(gsettings_in_file:.xml.in=.xml)
@INTLTOOL_XML_NOMERGE_RULE@
@GSETTINGS_RULES@

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

man_MANS     = gnect.6

EXTRA_DIST = $(pixmap_DATA) \
             $(velena_DATA) \
             $(desktop_in_files) \
             $(gsettings_in_file) \
             $(man_MANS)

DISTCLEANFILES = $(gsettings_SCHEMAS) $(desktop_DATA)

@INTLTOOL_DESKTOP_RULE@

-include $(top_srcdir)/git.mk
