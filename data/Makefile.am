SUBDIRS = icons

gsettings_SCHEMAS = org.gnome.four-in-a-row.gschema.xml
@GSETTINGS_RULES@

pixmapdir = $(datadir)/four-in-a-row
pixmap_DATA = \
    tileset_50x50_glassy.png \
    tileset_50x50_hcontrast.svg \
    tileset_50x50_hcinverse.svg \
    tileset_50x50_faenza-glines-icon1.svg \
    tileset_50x50_faenza-glines-icon2.svg \
    tileset_50x50_faenza-gnect-icon.svg \
    bg_toplight.png

soundsdir = $(datadir)/four-in-a-row/sounds
sounds_DATA = \
	bad.ogg \
	bonus.ogg \
	reverse.ogg \
	slide.ogg

velenadir      = $(datadir)/four-in-a-row
velena_DATA    = white_ob.cn4.gz

desktopdir       = $(datadir)/applications
desktop_in_files = gnect.desktop.in
desktop_DATA     = $(desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

appdatadir = $(datadir)/appdata
appdata_in_files = four-in-a-row.appdata.xml.in
appdata_DATA = $(appdata_in_files:.xml.in=.xml)
@INTLTOOL_XML_RULE@

man_MANS     = four-in-a-row.6

EXTRA_DIST = $(pixmap_DATA) \
             $(sounds_DATA) \
             $(velena_DATA) \
	     $(appdata_in_files) \
             $(desktop_in_files) \
             $(gsettings_SCHEMAS) \
             $(man_MANS)

CLEANFILES = \
	$(appdata_DATA) \
	$(desktop_DATA)

check-local: $(appdata_DATA) $(desktop_DATA)
	$(APPDATA_VALIDATE) $(appdata_DATA)
	$(DESKTOP_FILE_VALIDATE) $(desktop_DATA)

-include $(top_srcdir)/git.mk
