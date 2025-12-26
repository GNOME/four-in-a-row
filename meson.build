project('four-in-a-row', 'c', 'vala',
    version: '50.alpha'
)

project_id = 'org.gnome.Four-in-a-row'

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language: 'c')

# used to install help
gnome = import('gnome')
# used for internationalization
i18n = import('i18n')

application_id = 'org.gnome.Four-in-a-row'

valac = meson.get_compiler('vala')

gio_dependency      = dependency('gio-2.0',     version: '>= 2.80.0')
glib_dependency     = dependency('glib-2.0',    version: '>= 2.80.0')
gtk_dependency      = dependency('gtk4',        version: '>= 4.16.0')
adw_dependency      = dependency('libadwaita-1', version: '>= 1.7')
posix_dependency    = valac.find_library('posix')
rsvg_dependency     = dependency('librsvg-2.0', version: '>= 2.52.0')

appstream_cli          = find_program('appstreamcli',          required: false)
desktop_file_validate  = find_program('desktop-file-validate', required: false)
glib_compile_schema    = find_program('glib-compile-schemas',  required: true) # useful?

localedir   = join_paths(get_option('prefix'), get_option('localedir'))
datadir     = join_paths(get_option('prefix'), get_option('datadir'))
bindir      = join_paths(get_option('prefix'), get_option('bindir'))
pkgdatadir  = join_paths(datadir, meson.project_name())
soundsdir   = join_paths(pkgdatadir, 'sounds')

conf = configuration_data ()
conf.set_quoted('VERSION', meson.project_version())
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('SOUND_DIRECTORY', soundsdir)
conf.set_quoted('LOCALEDIR', localedir)
conf.set_quoted('DATA_DIRECTORY', pkgdatadir)

configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')


subdir('data')
subdir('help')
subdir('po')
subdir('src')

gnome.post_install(
    glib_compile_schemas: true,
    gtk_update_icon_cache: true,
    update_desktop_database: true,
)
