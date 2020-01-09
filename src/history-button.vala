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

[GtkTemplate (ui = "/org/gnome/Four-in-a-row/ui/history-button.ui")]
private class HistoryButton : MenuButton, AdaptativeWidget
{
    [CCode (notify = false)] public ThemeManager theme_manager { private get; protected construct; }

    [GtkChild] private Stack stack;
    [GtkChild] private DrawingArea drawing;

    internal HistoryButton (ref GLib.Menu menu, ThemeManager theme_manager)
    {
        Object (menu_model: menu, theme_manager: theme_manager);
    }

    construct
    {
        drawing.configure_event.connect (configure_drawing);
        drawing.draw.connect (update_drawing);
        theme_manager.theme_changed.connect (() => {
                if (!drawing_configured)
                    return;
                init_pixbuf ();
                if (current_player != Player.NOBODY)
                    drawing.queue_draw ();
            });
    }

    protected override void set_window_size (AdaptativeWidget.WindowSize new_size)
    {
    }

    internal void set_player (Player player)
    {
        current_player = player;
        if (player == Player.NOBODY)
            stack.set_visible_child_name ("label");
        else
        {
            stack.set_visible_child (drawing);
            drawing.queue_draw ();
        }
    }

    /*\
    * * drawing
    \*/

    private bool drawing_configured = false;
    private int drawing_height      = int.MIN;
    private int drawing_width       = int.MIN;
    private int pixbuf_size         = int.MIN;
    private double arrow_half_width = - double.MAX;
    private int board_x             = int.MIN;
    private int board_y             = int.MIN;
    private const int pixbuf_margin = 1;

    private Gdk.Pixbuf tileset_pixbuf;

    private bool configure_drawing ()
    {
        int height          = drawing.get_allocated_height ();
        int width           = drawing.get_allocated_width ();
        int new_height      = (int) double.min (height, width / 2.0);

        bool refresh_pixbuf = drawing_height != new_height;
        drawing_height      = new_height;
        pixbuf_size         = drawing_height - 2 * pixbuf_margin;
        if (refresh_pixbuf)
            init_pixbuf ();
        arrow_half_width    = pixbuf_size / 4.0;

        bool vertical_fill  = height == new_height;
        drawing_width       =  vertical_fill ? (int) (new_height * 2.0) : width;
        board_x             =  vertical_fill ? (int) ((width  - drawing_width)  / 2.0) : 0;
        board_y             = !vertical_fill ? (int) ((height - drawing_height) / 2.0) : 0;

        drawing_configured  = true;
        return true;
    }
    private void init_pixbuf ()
    {
        Gdk.Pixbuf? tmp_pixbuf = theme_manager.pb_tileset_raw.scale_simple (pixbuf_size * 6, pixbuf_size, Gdk.InterpType.BILINEAR);
        if (tmp_pixbuf == null)
            assert_not_reached ();
        tileset_pixbuf = (!) tmp_pixbuf;
    }

    private bool update_drawing (Cairo.Context cr)
    {
        if (!drawing_configured)
            return false;

        draw_arrow (cr);
        draw_piece (cr);
        return true;
    }

    private const double arrow_margin_top = 3.0;
    private void draw_arrow (Cairo.Context cr)
    {
        cr.save ();

        cr.set_line_cap (Cairo.LineCap.ROUND);
        cr.set_line_join (Cairo.LineJoin.ROUND);

        cr.set_source_rgba (/* red */ 0.5, /* green */ 0.5, /* blue */ 0.5, 1.0);
        cr.set_line_width (/* looks good */ 2.0);

        cr.translate (board_x, board_y);
        cr.move_to (      arrow_half_width, arrow_margin_top);
        cr.line_to (3.0 * arrow_half_width, drawing_height / 2.0);
        cr.line_to (      arrow_half_width, drawing_height - arrow_margin_top);
        cr.stroke ();

        cr.restore ();
    }

    private Player current_player = Player.NOBODY;
    private void draw_piece (Cairo.Context cr)
    {
        int offset;
        switch (current_player)
        {
            case Player.HUMAN   : offset = 0;               break;
            case Player.OPPONENT: offset = pixbuf_size;     break;
            case Player.NOBODY  : offset = pixbuf_size * 2; break;
            default: assert_not_reached ();
        }

        cr.save ();
        int x = board_x + drawing_width - pixbuf_margin - pixbuf_size;
        int y = board_y + pixbuf_margin;
        Gdk.cairo_set_source_pixbuf (cr, tileset_pixbuf, x - offset, y);
        cr.rectangle (x, y, pixbuf_size, pixbuf_size);

        cr.clip ();
        cr.paint ();
        cr.restore ();
    }
}
