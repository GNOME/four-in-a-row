SUBDIRS = icons

gsettings_SCHEMAS = org.gnome.four-in-a-row.gschema.xml
@GSETTINGS_RULES@

uidir = $(datadir)/four-in-a-row
ui_DATA = four-in-a-row.ui

pixmapdir = $(datadir)/four-in-a-row
pixmap_DATA = \
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

desktopdir       = $(datadir)/applications
desktop_in_files = four-in-a-row.desktop.in
desktop_DATA     = $(desktop_in_files:.desktop.in=.desktop)
$(desktop_DATA): $(desktop_in_files)
	$(AM_V_GEN)$(MSGFMT) --desktop --template $< -d $(top_srcdir)/po -o $@

appstream_in_files = four-in-a-row.appdata.xml.in
appstream_XML = $(appstream_in_files:.xml.in=.xml)
$(appstream_XML): $(appstream_in_files)
	$(AM_V_GEN)$(MSGFMT) --xml --template $< -d $(top_srcdir)/po -o $@

man_MANS     = four-in-a-row.6

EXTRA_DIST = $(ui_DATA) \
             $(pixmap_DATA) \
             $(sounds_DATA) \
             $(appstream_in_files) \
             $(desktop_in_files) \
             $(gsettings_SCHEMAS) \
             $(man_MANS)

CLEANFILES = \
	$(appstream_XML) \
	$(desktop_DATA)

check-local: $(desktop_DATA)
	$(DESKTOP_FILE_VALIDATE) $(desktop_DATA)

DISTCHECK_CONFIGURE_FLAGS = --enable-appdata-check

-include $(top_srcdir)/git.mk
