/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
   This file is part of GNOME Four-in-a-row.

   Copyright © 2015, 2016, 2019 Arnaud Bonatti

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
    [GtkChild] private HeaderBar headerbar;
    [GtkChild] private Overlay overlay;
    [GtkChild] private Stack stack;

    private Button? start_game_button = null;
    [GtkChild] private Button new_game_button;
    [GtkChild] private Button back_button;
    [GtkChild] private Button unfullscreen_button;

    [GtkChild] private Box game_box;
    [GtkChild] private Box new_game_box;

    private Widget view;
    private Widget? game_widget_1;
    private GameActionBar actionbar;

    /* signals */
    internal signal void play ();
    internal signal void wait ();
    internal signal void back ();

    internal signal void undo ();
 // internal signal void redo ();
    internal signal void hint ();

    internal GameWindow (string? css_resource, string name, bool start_now, GameWindowFlags flags, Box new_game_screen, Widget _view, GLib.Menu app_menu, Widget? _game_widget_1, Widget? game_widget_2)
    {
        Object (window_title: name,
                specific_css_class_or_empty: "",
                schema_path: "/org/gnome/Four-in-a-row/");

        if (css_resource != null)
        {
            CssProvider css_provider = new CssProvider ();
            css_provider.load_from_resource ((!) css_resource);
            Gdk.Screen? gdk_screen = Gdk.Screen.get_default ();
            if (gdk_screen != null) // else..?
                StyleContext.add_provider_for_screen ((!) gdk_screen, css_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
        }

        view = _view;
        game_widget_1 = _game_widget_1;

        /* window config */
        install_ui_action_entries ();
        program_name = name;
        set_title (name);
        if (!is_extra_thin)
            headerbar.set_title (name);
        info_button.set_menu_model (app_menu);

        /* add widgets */
        if (game_widget_1 != null)
        {
            headerbar.pack_end ((!) game_widget_1);
            add_adaptative_child ((AdaptativeWidget) (!) game_widget_1);
        }
        actionbar = new GameActionBar (name, game_widget_2, /* show actionbar */ start_now);
        actionbar.show ();
        actionbar.valign = Align.END;
        overlay.add_overlay (actionbar);

        GameActionBarPlaceHolder actionbar_placeholder = new GameActionBarPlaceHolder (actionbar);
        actionbar_placeholder.show ();
        game_box.pack_end (actionbar_placeholder, /* expand */ false, /* fill */ true, /* padding */ 0);

        new_game_box.pack_start (new_game_screen, true, true, 0);
        add_adaptative_child ((AdaptativeWidget) new_game_screen);
        add_adaptative_child ((AdaptativeWidget) actionbar);
        add_adaptative_child ((AdaptativeWidget) actionbar_placeholder);
        add_adaptative_child ((AdaptativeWidget) this);
        if (GameWindowFlags.SHOW_START_BUTTON in flags)
        {
            /* Translators: when configuring a new game, label of the blue Start button (with a mnemonic that appears pressing Alt) */
            Button _start_game_button = new Button.with_mnemonic (_("_Start Game"));
//            _start_game_button.width_request = 222;
//            _start_game_button.height_request = 60;
            _start_game_button.get_style_context ().add_class ("start-game-button");
            _start_game_button.halign = Align.CENTER;
            _start_game_button.set_action_name ("ui.start-game");
            /* Translators: when configuring a new game, tooltip text of the blue Start button */
            // _start_game_button.set_tooltip_text (_("Start a new game as configured"));
            ((StyleContext) _start_game_button.get_style_context ()).add_class ("suggested-action");
            _start_game_button.show ();
            new_game_box.pack_end (_start_game_button, false, false, 0);
            start_game_button = _start_game_button;
        }

        game_box.pack_start (view, true, true, 0);
        game_box.set_focus_child (view);            // TODO test if necessary; note: view could grab focus from application
        view.halign = Align.FILL;
        view.can_focus = true;
        view.show ();

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
    * * Window events
    \*/

    protected override void on_fullscreen ()
    {
        unfullscreen_button.show ();
    }

    protected override void on_unfullscreen ()
    {
        unfullscreen_button.hide ();
    }

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

    internal void set_subtitle (string? subtitle)
    {
        if (!is_extra_thin)
            headerbar.set_title (subtitle);
        last_subtitle = subtitle;
        if (subtitle == null)
            actionbar.set_visibility (false);
        else
        {
            actionbar.update_title ((!) subtitle);
            actionbar.set_visibility (true);
        }
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

    internal bool is_extra_thin { internal get; private set; default = false; }
    private bool is_quite_thin = false;
    protected override void set_window_size (AdaptativeWidget.WindowSize new_size)
    {
        is_quite_thin = AdaptativeWidget.WindowSize.is_quite_thin (new_size);

        bool _is_extra_thin = AdaptativeWidget.WindowSize.is_extra_thin (new_size);
        if (_is_extra_thin == is_extra_thin)
            return;
        is_extra_thin = _is_extra_thin;

        if (is_extra_thin)
        {
            headerbar.set_title (null);
            if (game_widget_1 != null)
                ((!) game_widget_1).hide ();
        }
        else
        {
            if (game_widget_1 != null && (!) stack.get_visible_child_name () == "game-box")
                ((!) game_widget_1).show ();
            string? panel_name = stack.get_visible_child_name ();
            if (panel_name != null && (!) panel_name == "start-box")
                headerbar.set_title (program_name);
            else
                headerbar.set_title (last_subtitle);
        }
    }

    /*\
    * * Showing the Stack
    \*/

    private string? last_subtitle = null;
    private void show_new_game_screen ()
    {
        if (!is_extra_thin)
            headerbar.set_title (program_name);
        actionbar.set_visibility (false);

        stack.set_visible_child_name ("start-box");
        if (game_widget_1 != null)
            ((!) game_widget_1).hide ();
        new_game_button.hide ();

        if (!game_finished && back_button.visible)
            back_button.grab_focus ();
        else if (start_game_button != null)
            ((!) start_game_button).grab_focus ();
    }

    private void show_view ()
    {
        if (!is_extra_thin)
            headerbar.set_title (last_subtitle);
        actionbar.set_visibility (true);

        stack.set_visible_child_name ("game-box");
        back_button.hide ();        // TODO transition?
        if (game_widget_1 != null && !is_extra_thin)
            ((!) game_widget_1).show ();
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

    internal bool new_game_screen_visible ()
    {
        string? stack_child = stack.get_visible_child_name ();
        if (stack_child == null)
            assert_not_reached ();
        if ((!) stack_child == "game-box")
            return false;
        else
            return true;
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

        if (!back_button.is_focus)
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

    [GtkChild] private MenuButton info_button;

    private inline void toggle_hamburger (/* SimpleAction action, Variant? variant */)
    {
        info_button.active = !info_button.active;
    }

    internal inline void close_hamburger () // TODO manage also the HistoryButton here?
    {
        info_button.active = false;
    }
}
