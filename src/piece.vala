/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
   This file is part of GNOME Four-in-a-row.

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

private class Piece : Object, Gdk.Paintable
{
    private ThemeManager    theme_manager;
    private Player          player = Player.NOBODY;

    internal Piece (ThemeManager theme_manager, Player player)
    {
        this.theme_manager = theme_manager;
        this.player = player;
    }

    private Gdk.Pixbuf? tileset_pixbuf;
    private void init_pixbuf (int pixbuf_size)
    {
        tileset_pixbuf = theme_manager.pb_tileset_raw.scale_simple (pixbuf_size * 6, pixbuf_size, Gdk.InterpType.BILINEAR);
        if (tileset_pixbuf == null)
            assert_not_reached ();
    }

    protected void snapshot (Gdk.Snapshot gdk_snapshot, double width, double height)
    {
        var snapshot = (Gtk.Snapshot) gdk_snapshot;

        var pixbuf_size = (int) double.min (width, height);
        if (tileset_pixbuf == null || pixbuf_size != ((!) tileset_pixbuf).height)
            init_pixbuf (pixbuf_size);

        snapshot.save ();

        Graphene.Rect rect = Graphene.Rect () {
            origin = Graphene.Point () { x = 0, y = 0 },
            size = Graphene.Size () { width = pixbuf_size, height = pixbuf_size }
        };
        Cairo.Context cr = snapshot.append_cairo (rect);

        int offset;
        switch (player)
        {
            case Player.HUMAN   : offset = 0;               break;
            case Player.OPPONENT: offset = pixbuf_size;     break;
            case Player.NOBODY  : offset = pixbuf_size * 2; break;
            default: assert_not_reached ();
        }

        cr.save ();
        Gdk.cairo_set_source_pixbuf (cr, (!) tileset_pixbuf, - offset, 0);
        cr.rectangle (0, 0, pixbuf_size, pixbuf_size);

        cr.clip ();
        cr.paint ();
        cr.restore ();

        snapshot.restore ();
    }
}
