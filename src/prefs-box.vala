/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
   This file is part of GNOME Four-in-a-row.

   Copyright © 2018 Jacob Humphrey

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

private class PrefsBox : Dialog
{
    private const uint DEFAULT_KEY_LEFT  = Gdk.Key.Left;
    private const uint DEFAULT_KEY_RIGHT = Gdk.Key.Right;
    private const uint DEFAULT_KEY_DROP  = Gdk.Key.Down;

    internal PrefsBox (Window parent)
    {
        Object (title: _("Keyboard Controls"), destroy_with_parent: true);
        set_transient_for (parent);
        this.application = parent.application;
        modal = true;
        get_content_area ().border_width = 0;   // defaults on 2

        GamesControlsList controls_list = new GamesControlsList (Prefs.instance.settings);
        controls_list.shadow_type = ShadowType.NONE;
        controls_list.add_controls ("key-left",     _("Move left"),     DEFAULT_KEY_LEFT,
                                    "key-right",    _("Move right"),    DEFAULT_KEY_RIGHT,
                                    "key-drop",     _("Drop marble"),   DEFAULT_KEY_DROP);
        get_content_area ().pack_start (controls_list, true, true, 0);
    }

    protected override bool delete_event (Gdk.EventAny event)   // TODO use hide_on_delete (Gtk3) or hide-on-close (Gtk4) 2/2
    {
        hide ();
        return true;
    }
}
