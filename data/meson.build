# Make D-Bus activatable
service_conf = configuration_data()
service_conf.set('bindir', bindir)

service = project_id + '.service'

configure_file(
  input: service + '.in',
  output: service,
  install: true,
  install_dir: join_paths(datadir, 'dbus-1', 'services'),
  configuration: service_conf
)

# Desktop file
desktop_file = i18n.merge_file(
    input: '@0@.desktop.in'.format(application_id),
    output: '@0@.desktop'.format(application_id),
    po_dir: join_paths(meson.source_root(), 'po'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

# Validate desktop file
if desktop_file_validate.found()
  test(
    'validate-desktop',
    desktop_file_validate,
    args: [
      desktop_file.full_path()
    ]
  )
endif

# AppData file
appdata_file = i18n.merge_file(
    input: '@0@.appdata.xml.in'.format(application_id),
    output: '@0@.appdata.xml'.format(application_id),
    po_dir: join_paths(meson.source_root(), 'po'),
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

# Validate AppData file
if appstream_cli.found()
  test(
    'validate-metainfo', appstream_cli,
    args: [
      'validate', '--no-net', '--explain', appdata_file.full_path()
    ]
  )
endif

# Install man page
install_man('@0@.6'.format(meson.project_name()))

# Install GSchema file
install_data(
  '@0@.gschema.xml'.format(application_id),
  install_dir : join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

install_data(
    [
        'sounds/bad.ogg',
        'sounds/bonus.ogg',
        'sounds/reverse.ogg',
        'sounds/slide.ogg'
    ],
    install_dir: soundsdir
)
subdir('icons')
