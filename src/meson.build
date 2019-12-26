# Tests
four_in_a_row_tests = executable(
    'four-in-a-row-tests',
    [
        'ai.vala',
        'player.vala',
        'test-ai.vala'
    ],
    dependencies: [
        gio_dependency,
        glib_dependency
    ]
)
test('four-in-a-row-tests',
    four_in_a_row_tests,
    timeout: 180)

# Application
resources = gnome.compile_resources (meson.project_name(), 'four-in-a-row.gresource.xml')

sources = files(
    'adaptative-window.vala',
    'ai.vala',
    'four-in-a-row.vala',
    'game-actionbar.vala',
    'game-board-view.vala',
    'game-board.vala',
    'game-window.vala',
    'history-button.vala',
    'new-game-screen.vala',
    'player.vala',
    'scorebox.vala',
    'theme.vala',
    'vapi/config.vapi'
)

executable(
    meson.project_name(),
    sources + resources,
    dependencies: [
        glib_dependency,
        gsound_dependency,
        gtk_dependency,
        posix_dependency,
        rsvg_dependency
    ],
    c_args: [
        '-include', 'config.h'
    ],
    vala_args: [
        '--target-glib', '2.44',
        '--vapidir', join_paths(meson.current_source_dir(), 'vapi'),
        '--enable-experimental-non-null'
    ],
    install: true,
    install_dir: get_option('bindir')
)
