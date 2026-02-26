/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
   This file is part of GNOME Four-in-a-row.

   Copyright 2010-2013 Robert Ancell
   Copyright 2013-2014 Michael Catanzaro
   Copyright 2014-2019 Arnaud Bonatti

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

[GtkTemplate (ui = "/org/gnome/Four-in-a-row/ui/fiar-screens.ui")]
private class NewGameScreen : Box, AdaptativeWidget
{
    [GtkChild] private unowned Box game_type_section;
    [GtkChild] private unowned Box users_section;
    [GtkChild] private unowned Box start_section;

    [GtkChild] private unowned Adw.ToggleGroup game_type_group;
    [GtkChild] private unowned Adw.ToggleGroup users_group;
    [GtkChild] private unowned Adw.ToggleGroup level_group;
    [GtkChild] private unowned Adw.ToggleGroup start_group;

    public int num_players { get; set; }
    public string first_player { get; set; }
    public int opponent { get; set; }

    construct
    {
        bind_property ("num-players", users_group, "active",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL,
            (binding, srcval, ref targetval) => {
                targetval.set_uint (srcval.get_int () - 1);
                return true;
            },
            (binding, srcval, ref targetval) => {
                targetval.set_int ((int) srcval.get_uint () + 1);
                return true;
            });

        bind_property ("first-player", start_group, "active-name",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

        bind_property ("opponent", level_group, "active",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL,
            (binding, srcval, ref targetval) => {
                targetval.set_uint (srcval.get_int () - 1);
                return true;
            },
            (binding, srcval, ref targetval) => {
                targetval.set_int ((int) srcval.get_uint () + 1);
                return true;
            });

        notify["num-players"].connect (() => update_game_type ());
        notify["first-player"].connect (() => update_game_type ());

        game_type_group.notify ["active-name"].connect (() => {
            var game_type = game_type_group.get_active_name ();
            if (game_type == "human")
            {
                num_players = 1;
                first_player = "human";
            }
            else if (game_type == "computer")
            {
                num_players = 1;
                first_player = "computer";
            }
            else if (game_type == "two")
            {
                num_players = 2;
            }
        });
    }

    private void update_game_type ()
    {
        if (num_players == 1)
        {
            update_sensitivity (true);
            if (first_player == "human")
                game_type_group.set_active_name ("human");
            else
                game_type_group.set_active_name ("computer");
        }
        else
        {
            update_sensitivity (false);
            game_type_group.set_active_name ("two");
        }
    }

    private void update_sensitivity (bool new_sensitivity)
    {
        level_group.sensitive = new_sensitivity;
        start_group.sensitive = new_sensitivity;
    }

    private bool quite_thin = false;
    private bool extra_thin = true;     // extra_thin && !quite_thin is impossible, so it will not return in next method the first time
    private bool extra_flat = false;
    private void set_window_size (AdaptativeWidget.WindowSize new_size)
    {
        bool _quite_thin = WindowSize.is_quite_thin (new_size);
        bool _extra_thin = WindowSize.is_extra_thin (new_size);
        bool _extra_flat = WindowSize.is_extra_flat (new_size);

        if ((_quite_thin == quite_thin)
         && (_extra_thin == extra_thin)
         && (_extra_flat == extra_flat))
            return;
        quite_thin = _quite_thin;
        extra_thin = _extra_thin;
        extra_flat = _extra_flat;

        if (extra_thin)
        {
            set_orientation (Orientation.VERTICAL);
            spacing = 18;
            homogeneous = false;
            height_request = 360;
            width_request = 250;
            margin_bottom = 22;

            game_type_section.visible = true;
            users_section.visible = false;
            start_section.visible = false;

            level_group.set_orientation (Orientation.VERTICAL);
        }
        else if (extra_flat)
        {
            set_orientation (Orientation.HORIZONTAL);
            homogeneous = true;
            height_request = 113;
            margin_bottom = 6;
            if (quite_thin)
            {
                spacing = 21;
                width_request = 420;
            }
            else
            {
                spacing = 24;
                width_request = 450;
            }

            game_type_section.visible = true;
            users_section.visible = false;
            start_section.visible = false;

            level_group.set_orientation (Orientation.VERTICAL);
        }
        else
        {
            set_orientation (Orientation.VERTICAL);
            spacing = 18;
            width_request = quite_thin ? 380 : 400;
            height_request = 263;
            margin_bottom = 22;

            game_type_section.visible = false;
            users_section.visible = true;
            start_section.visible = true;

            level_group.set_orientation (Orientation.HORIZONTAL);

            homogeneous = true;
        }
        queue_allocate ();
    }
}
