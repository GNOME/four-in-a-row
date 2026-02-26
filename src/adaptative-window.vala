/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
   This file is part of GNOME Four-in-a-row.

   Copyright © 2019 Arnaud Bonatti

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

private interface AdaptativeWidget : Object
{ /*
       ╎ extra ╎
       ╎ thin  ╎
  ╶╶╶╶ ┏━━━━━━━┳━━━━━━━┳━━━━━──╴
 extra ┃ PHONE ┃ PHONE ┃ EXTRA
 flat  ┃ _BOTH ┃ _HZTL ┃ _FLAT
  ╶╶╶╶ ┣━━━━━━━╋━━━━━━━╋━━━━╾──╴
       ┃ PHONE ┃       ┃
       ┃ _VERT ┃       ┃
       ┣━━━━━━━┫       ┃
       ┃ EXTRA ┃ QUITE ╿ USUAL
       ╿ _THIN │ _THIN │ _SIZE
       ╵       ╵       ╵
       ╎   quite thin  ╎
                              */

    internal enum WindowSize {
        START_SIZE,
        USUAL_SIZE,
        QUITE_THIN,
        PHONE_VERT,
        PHONE_HZTL,
        PHONE_BOTH,
        EXTRA_THIN,
        EXTRA_FLAT;

        internal static inline bool is_extra_thin (WindowSize window_size)
        {
            return (window_size == PHONE_BOTH) || (window_size == PHONE_VERT) || (window_size == EXTRA_THIN);
        }

        internal static inline bool is_extra_flat (WindowSize window_size)
        {
            return (window_size == PHONE_BOTH) || (window_size == PHONE_HZTL) || (window_size == EXTRA_FLAT);
        }

        internal static inline bool is_quite_thin (WindowSize window_size)
        {
            return is_extra_thin (window_size) || (window_size == PHONE_HZTL) || (window_size == QUITE_THIN);
        }
    }

    internal abstract void set_window_size (WindowSize new_size);
}

private const int LARGE_WINDOW_SIZE = 1042;

private abstract class AdaptativeWindow : Adw.ApplicationWindow
{
    construct
    {
        height_request = 284; // 288px max for Purism Librem 5 landscape, for 720px width; update gschema also
        width_request = 350; // 360px max for Purism Librem 5 portrait, for 648px height; update gschema also
    }

    /*\
    * * callbacks
    \*/

    protected override void size_allocate (int width, int height, int baseline)
    {
        base.size_allocate (width, height, baseline);
        update_adaptative_children (ref width, ref height);
    }

    /*\
    * * adaptative stuff
    \*/

    private AdaptativeWidget.WindowSize window_size = AdaptativeWidget.WindowSize.START_SIZE;

    private List<AdaptativeWidget> adaptative_children = new List<AdaptativeWidget> ();
    protected void add_adaptative_child (AdaptativeWidget child)
    {
        adaptative_children.append (child);
    }

    private void update_adaptative_children (ref int width, ref int height)
    {
        bool extra_flat = height < 400;
        bool flat       = height < 500;

        if (width < 590)
        {
            if (extra_flat)         change_window_size (AdaptativeWidget.WindowSize.PHONE_BOTH);
            else if (height < 787)  change_window_size (AdaptativeWidget.WindowSize.PHONE_VERT);
            else                    change_window_size (AdaptativeWidget.WindowSize.EXTRA_THIN);

            set_style_classes (/* extra thin */ true, /* thin */ true, /* large */ false,
                               /* extra flat */ extra_flat, /* flat */ flat);
        }
        else if (width < 787)
        {
            if (extra_flat)         change_window_size (AdaptativeWidget.WindowSize.PHONE_HZTL);
            else                    change_window_size (AdaptativeWidget.WindowSize.QUITE_THIN);

            set_style_classes (/* extra thin */ false, /* thin */ true, /* large */ false,
                               /* extra flat */ extra_flat, /* flat */ flat);
        }
        else
        {
            if (extra_flat)         change_window_size (AdaptativeWidget.WindowSize.EXTRA_FLAT);
            else                    change_window_size (AdaptativeWidget.WindowSize.USUAL_SIZE);

            set_style_classes (/* extra thin */ false, /* thin */ false, /* large */ (width > LARGE_WINDOW_SIZE),
                               /* extra flat */ extra_flat, /* flat */ flat);
        }
    }

    private void change_window_size (AdaptativeWidget.WindowSize new_window_size)
    {
        if (window_size == new_window_size)
            return;
        window_size = new_window_size;
        adaptative_children.@foreach ((adaptative_child) => adaptative_child.set_window_size (new_window_size));
    }

    /*\
    * * manage style classes
    \*/

    private bool has_extra_thin_window_class = false;
    private bool has_thin_window_class = false;
    private bool has_extra_flat_window_class = false;
    private bool has_flat_window_class = false;

    private void set_style_classes (bool extra_thin_window, bool thin_window, bool large_window,
                                    bool extra_flat_window, bool flat_window)
    {
        // for width
        if (has_extra_thin_window_class && !extra_thin_window)
            set_style_class ("extra-thin-window", false, ref has_extra_thin_window_class);
        if (has_thin_window_class && !thin_window)
            set_style_class ("thin-window", false, ref has_thin_window_class);

        if (thin_window != has_thin_window_class)
            set_style_class ("thin-window", thin_window, ref has_thin_window_class);
        if (extra_thin_window != has_extra_thin_window_class)
            set_style_class ("extra-thin-window", extra_thin_window, ref has_extra_thin_window_class);

        // for height
        if (has_extra_flat_window_class && !extra_flat_window)
            set_style_class ("extra-flat-window", false, ref has_extra_flat_window_class);

        if (flat_window != has_flat_window_class)
            set_style_class ("flat-window", flat_window, ref has_flat_window_class);
        if (extra_flat_window != has_extra_flat_window_class)
            set_style_class ("extra-flat-window", extra_flat_window, ref has_extra_flat_window_class);
    }

    private inline void set_style_class (string class_name, bool new_state, ref bool old_state)
    {
        old_state = new_state;
        if (new_state)
            add_css_class (class_name);
        else
            remove_css_class (class_name);
    }
}
