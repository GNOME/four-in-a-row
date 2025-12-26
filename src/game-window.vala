/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
   This file is part of GNOME Four-in-a-row.

   Copyright © 2015, 2016, 2019 Arnaud Bonatti
   Copyright © 2025 Andrey Kutejko

   GNOME Four-in-a-row is free software: you can redistribute it and/or
   modify it under the terms of the GNU General Public License as published
   by the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   GNOME Four-in-a-row is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along
   with GNOME Four-in-a-row.  If not, see <https://www.gnu.org/licenses/>.
*/

using Gtk;

[Flags]
private enum GameWindowFlags {
    SHOW_UNDO,
 // SHOW_REDO,
 // SHOW_HINT,
    SHOW_START_BUTTON;
}

[GtkTemplate (ui = "/org/gnome/Four-in-a-row/ui/game-window.ui")]
private class GameWindow : AdaptativeWindow, AdaptativeWidget
{
    private bool game_finished = false;

    private string program_name = "";

    /* private widgets */
    [GtkChild] private unowned Adw.HeaderBar headerbar;
    [GtkChild] private unowned Adw.WindowTitle window_title;
    [GtkChild] private unowned Overlay overlay;
    [GtkChild] private unowned Stack stack;

    private Button? start_game_button = null;
    [GtkChild] private unowned Button new_game_button;
    [GtkChild] private unowned Button back_button;
    [GtkChild] private unowned Button unfullscreen_button;

    [GtkChild] private unowned Box game_box;
    [GtkChild] private unowned Box new_game_box;

    private Widget view;
    [GtkChild] private unowned MenuButton history_button_1;
    [GtkChild] private unowned MenuButton history_button_2;
    [GtkChild] private unowned Label title_2;
    [GtkChild] private unowned ActionBar actionbar;

    private GLib.Settings settings;

    /* signals */
    internal signal void play ();
    internal signal void wait ();
    internal signal void back ();

    internal signal void undo ();
 // internal signal void redo ();
    internal signal void hint ();

    internal GameWindow (Adw.Application application,
                         string? css_resource,
                         string name,
                         bool start_now,
                         GameWindowFlags flags,
                         Box new_game_screen,
                         Widget _view,
                         GLib.Menu app_menu,
                         Widget game_widget_1,
                         Widget game_widget_2,
                         GLib.Menu game_menu)
    {
        Object (application: application);

        settings = new GLib.Settings.with_path ("org.gnome.Four-in-a-row.Lib", "/org/gnome/Four-in-a-row/");

        if (css_resource != null)
        {
            CssProvider css_provider = new CssProvider ();
            css_provider.load_from_resource ((!) css_resource);
            StyleContext.add_provider_for_display (get_display (), css_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
        }

        view = _view;

        /* window config */
        install_ui_action_entries ();
        program_name = name;
        set_title (name);
        window_title.set_title (name);
        info_button.set_menu_model (app_menu);

        /* add widgets */
        history_button_1.menu_model = game_menu;
        history_button_1.child = game_widget_1;

        history_button_2.menu_model = game_menu;
        history_button_2.child = game_widget_2;

        new_game_box.append (new_game_screen);

        game_box.prepend (view);
        game_box.set_focus_child (view);            // TODO test if necessary; note: view could grab focus from application
        view.vexpand = true;
        view.halign = Align.FILL;
        view.can_focus = true;

        if (GameWindowFlags.SHOW_START_BUTTON in flags)
        {
            /* Translators: when configuring a new game, label of the blue Start button (with a mnemonic that appears pressing Alt) */
            Button _start_game_button = new Button.with_mnemonic (_("_Start Game"));
//            _start_game_button.width_request = 222;
//            _start_game_button.height_request = 60;
            _start_game_button.add_css_class ("start-game-button");
            _start_game_button.halign = Align.CENTER;
            _start_game_button.set_action_name ("ui.start-game");
            /* Translators: when configuring a new game, tooltip text of the blue Start button */
            // _start_game_button.set_tooltip_text (_("Start a new game as configured"));
            _start_game_button.add_css_class ("suggested-action");
            new_game_box.append (_start_game_button);
            start_game_button = _start_game_button;
        }

        add_adaptative_child ((AdaptativeWidget) new_game_screen);
        add_adaptative_child ((AdaptativeWidget) this);

        settings.bind ("window-width", this, "default-width", SettingsBindFlags.DEFAULT);
        settings.bind ("window-height", this, "default-height", SettingsBindFlags.DEFAULT);
        settings.bind ("window-is-maximized", this, "maximized", SettingsBindFlags.DEFAULT);

        bind_property ("fullscreened", unfullscreen_button, "visible", BindingFlags.SYNC_CREATE);

        /* start or not */
        if (start_now)
            show_view ();
        else
            show_new_game_screen ();
    }

    /*\
    * * actions
    \*/

    private SimpleAction back_action;
    private SimpleAction undo_action;
 // private SimpleAction redo_action;
    private SimpleAction hint_action;

    private void install_ui_action_entries ()
    {
        SimpleActionGroup action_group = new SimpleActionGroup ();
        action_group.add_action_entries (ui_action_entries, this);
        insert_action_group ("ui", action_group);

        back_action = (SimpleAction) action_group.lookup_action ("back");
        undo_action = (SimpleAction) action_group.lookup_action ("undo");
     // redo_action = (SimpleAction) action_group.lookup_action ("redo");
        hint_action = (SimpleAction) action_group.lookup_action ("hint");

        back_action.set_enabled (false);
        undo_action.set_enabled (false);
     // redo_action.set_enabled (false);
        hint_action.set_enabled (false);
    }

    private const GLib.ActionEntry [] ui_action_entries =
    {
        { "new-game", new_game_cb },
        { "start-game", start_game_cb },
        { "back", back_cb },

        { "undo", undo_cb },
     // { "redo", redo_cb },
        { "hint", hint_cb },

        { "toggle-hamburger", toggle_hamburger },
        { "unfullscreen", unfullscreen }
    };

    /*\
    * * Some internal calls
    \*/

    internal void cannot_undo_more ()
    {
        undo_action.set_enabled (false);
        view.grab_focus ();
    }

//    internal void new_turn_start (bool can_undo)
//    {
//        undo_action.set_enabled (can_undo);
//        headerbar.set_subtitle (null);
//    }

    internal void set_window_title (string? title)
    {
        if (title != null)
        {
            window_title.set_subtitle ((!) title);
            title_2.label = (!) title;
        }
        else
        {
            window_title.set_subtitle ("");
            title_2.label = "";
        }
    }

    internal void set_subtitle (string? subtitle)
    {
        set_window_title (subtitle);
        last_subtitle = subtitle;
    }

    internal void finish_game ()
    {
        game_finished = true;
        new_game_button.grab_focus ();
    }

    /* internal void about ()
    {
        TODO
    } */

    internal void allow_hint (bool allow)
    {
        string? stack_child = stack.get_visible_child_name ();
        if (stack_child == null || (!) stack_child != "game-box")
            return;
        hint_action.set_enabled (allow);
    }

    internal void allow_undo (bool allow)
    {
        string? stack_child = stack.get_visible_child_name ();
        if (stack_child == null || (!) stack_child != "game-box")
            return;
        undo_action.set_enabled (allow);
    }

    /*\
    * * adaptative stuff
    \*/

    private bool is_quite_thin = false;
    protected override void set_window_size (AdaptativeWidget.WindowSize new_size)
    {
        is_quite_thin = AdaptativeWidget.WindowSize.is_quite_thin (new_size);
    }

    /*\
    * * Showing the Stack
    \*/

    private string? last_subtitle = null;
    private void show_new_game_screen ()
    {
        set_window_title (null);

        stack.set_visible_child_name ("start-box");
        new_game_button.hide ();

        if (!game_finished && back_button.visible)
            back_button.grab_focus ();
        else if (start_game_button != null)
            ((!) start_game_button).grab_focus ();
    }

    private void show_view ()
    {
        set_window_title (last_subtitle);

        stack.set_visible_child_name ("game-box");
        back_button.hide ();        // TODO transition?
        new_game_button.show ();

        if (game_finished)
            new_game_button.grab_focus ();
        else
            view.grab_focus ();
    }

    /*\
    * * Switching the Stack
    \*/

    private void new_game_cb ()
    {
        string? stack_child = stack.get_visible_child_name ();
        if (stack_child == null || (!) stack_child != "game-box")
            return;

        wait ();

        stack.set_transition_type (StackTransitionType.SLIDE_LEFT);
        stack.set_transition_duration (800);

        back_button.show ();
        back_action.set_enabled (true);

        show_new_game_screen ();
    }

    private void start_game_cb ()
    {
        string? stack_child = stack.get_visible_child_name ();
        if (stack_child == null || (!) stack_child != "start-box")
            return;

        last_subtitle = null;
        game_finished = false;

        undo_action.set_enabled (false);
     // redo_action.set_enabled (false);
        hint_action.set_enabled (true);

        play ();        // FIXME lag (see in Taquin…)

        if (is_quite_thin)
            stack.set_transition_type (StackTransitionType.SLIDE_DOWN);
        else
            stack.set_transition_type (StackTransitionType.OVER_DOWN_UP);
        stack.set_transition_duration (1000);
        show_view ();
    }

    private void back_cb ()
    {
        string? stack_child = stack.get_visible_child_name ();
        if (stack_child == null || (!) stack_child != "start-box")
            return;
        // TODO change back headerbar subtitle?
        stack.set_transition_type (StackTransitionType.SLIDE_RIGHT);
        stack.set_transition_duration (800);
        show_view ();

        back ();
    }

    /*\
    * * Game menu actions
    \*/

    private void undo_cb ()
    {
        string? stack_child = stack.get_visible_child_name ();
        if (stack_child == null)
            return;
        if ((!) stack_child != "game-box")
        {
            if (back_action.get_enabled ())
                back_cb ();
            return;
        }

        game_finished = false;

        if (!back_button.has_focus)
            view.grab_focus();
     // redo_action.set_enabled (true);
        undo ();
    }

/*    private void redo_cb ()
    {
        string? stack_child = stack.get_visible_child_name ();
        if (stack_child == null || (!) stack_child != "game-box")
            return;

        if (!back_button.is_focus)
            view.grab_focus();
        undo_action.set_enabled (true);
        redo ();
    } */

    private void hint_cb ()
    {
        string? stack_child = stack.get_visible_child_name ();
        if (stack_child == null || (!) stack_child != "game-box")
            return;
        hint ();
    }

    /*\
    * * hamburger menu
    \*/

    [GtkChild] private unowned MenuButton info_button;

    private inline void toggle_hamburger (/* SimpleAction action, Variant? variant */)
    {
        info_button.active = !info_button.active;
    }

    internal inline void close_hamburger () // TODO manage also the HistoryButton here?
    {
        info_button.active = false;
    }
}
