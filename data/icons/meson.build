themedir = join_paths(get_option('prefix'), get_option('datadir'), 'icons', 'hicolor')
install_data(
    join_paths('hicolor', 'scalable', '@0@.svg'.format(application_id)),
    install_dir: join_paths(themedir, 'scalable', 'apps')
)
install_data(
    join_paths('hicolor', 'symbolic', '@0@-symbolic.svg'.format(application_id)),
    install_dir: join_paths(themedir, 'symbolic', 'apps')
)
