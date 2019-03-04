project('four-in-a-row', 'c', 'vala',
    version: '3.31.92'
)

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language: 'c')

gnome = import('gnome')
i18n = import('i18n')
python3 = import('python3')

application_id = 'org.gnome.Four-in-a-row'

gio_dependency = dependency('gio-2.0', version: '>= 2.40.0')
glib_dependency = dependency('glib-2.0', version: '>= 2.40.0')
gtk_dependency = dependency('gtk+-3.0', version: '>= 3.13.2')
rsvg_dependency = dependency('librsvg-2.0', version: '>= 2.32.0')
canberra_dependency = dependency('libcanberra')
canberra_gtk3_dependency = dependency('libcanberra-gtk3', version: '>= 0.26')

datadir = join_paths(get_option('prefix'), get_option('datadir'), meson.project_name())

conf = configuration_data ()
conf.set_quoted('VERSION', meson.project_version())
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('SOUND_DIRECTORY', join_paths(datadir, 'sounds'))
conf.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
conf.set_quoted('DATA_DIRECTORY', datadir)

configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')


subdir('data')
subdir('help')
subdir('po')
subdir('src')

meson.add_install_script(python3.find_python().path(), join_paths(meson.source_root(), 
                                                                  'build-aux', 
                                                                  'meson_post_install.py'))
