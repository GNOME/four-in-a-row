velenadir      = $(datadir)/gnect
velena_DATA    = white_ob.cn4

Games_in_files = gnect.desktop.in
Gamesdir       = $(datadir)/applications
Games_DATA     = $(Games_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

schemadir      = $(sysconfdir)/gconf/schemas
schema_in_files = gnect.schemas.in
schema_DATA = $(schema_in_files:.schemas.in=.schemas)
@INTLTOOL_SCHEMAS_RULE@

soundlistdir       = $(sysconfdir)/sound/events
soundlist_in_files = gnect.soundlist.in
soundlist_DATA     = $(soundlist_in_files:.soundlist.in=.soundlist)
@INTLTOOL_SOUNDLIST_RULE@

themedir       = $(datadir)/gnect
theme_DATA     = default.gnect               \
                 clean_50x50.gnect           \
                 clean_40x40.gnect           \
                 classic_50x50.gnect         \
                 classic_40x40.gnect         \
                 catseyes_40x40.gnect        \
                 glassy_50x50.gnect          \
                 glassy_40x40.gnect          \
                 glassy_50x50_grotty.gnect   \
                 glassy_40x40_grotty.gnect   \
                 square_50x50.gnect          \
                 square_40x40.gnect          \
                 clean_50x50_nightfall.gnect \
                 clean_40x40_nightfall.gnect \
                 safari_45x45.gnect          \
                 emulator_48x32.gnect

EXTRA_DIST = $(theme_DATA)      \
             $(velena_DATA)     \
             $(Games_DATA)      \
             $(soundlist_DATA)  \
             $(schema_DATA)

