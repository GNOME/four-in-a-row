four_in_a_row_tests = executable('four-in-a-row-tests', 
    [
        'ai.vala',
        'test-ai.vala'
    ],
    dependencies: [
        gio_dependency,
        glib_dependency
    ]
)
test('four-in-a-row-tests', 
    four_in_a_row_tests,
    timeout: 90)



sources = files(
    'vapi/config.vapi',
    'ai.vala',
    'four-in-a-row.vala',
    'game-board-view.vala',
    'game-board.vala',
    'games-controls-list.vala',
    'prefs-box.vala',
    'prefs.vala',
    'scorebox.vala',
    'theme.vala'
)

executable(
    meson.project_name(),
    sources,
    dependencies: [
        gtk_dependency,
        rsvg_dependency,
        canberra_dependency,
        canberra_gtk3_dependency,
        glib_dependency
    ],
    c_args: [
        '-include', 'config.h'
    ],
    vala_args: [
        '--target-glib', '2.44',
        '--vapidir', join_paths(meson.current_source_dir(), 'vapi')
    ],
    install: true,
    install_dir: get_option('bindir')
)
