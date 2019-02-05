/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*-
 * scorebox.vala
 *
 * Copyright © 2018 Jacob Humphrey
 *
 * This file is part of GNOME Four-in-a-row.
 *
 * GNOME Four-in-a-row is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * GNOME Four-in-a-row is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with GNOME Four-in-a-row. If not, see <http://www.gnu.org/licenses/>.
 */

class Scorebox : Gtk.Dialog {
    Gtk.Label[] label_name;
    Gtk.Label label_score[3];
    public new FourInARow application;

    public Scorebox(Gtk.Window parent, FourInARow application) {
        Object(title: _("Scores"),
               use_header_bar: 1,
               destroy_with_parent: true,
               resizable: false,
               border_width: 5);
        get_content_area().spacing = 2;
        set_transient_for(parent);
        modal = true;

        Gtk.Grid grid, grid2;

        label_name = new Gtk.Label[3];
        label_score = new Gtk.Label[3];

        grid = new Gtk.Grid();
        grid.halign = Gtk.Align.CENTER;
        grid.row_spacing = 6;
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.border_width = 5;

        get_content_area().pack_start(grid);

        grid2 = new Gtk.Grid();
        grid.add(grid2);
        grid2.column_spacing = 6;

        label_name[PlayerID.PLAYER1] = new Gtk.Label(null);
        grid2.attach(label_name[PlayerID.PLAYER1], 0, 0, 1, 1);
        label_name[PlayerID.PLAYER1].xalign = 0;
        label_name[PlayerID.PLAYER1].yalign = 0.5f;

        label_score[PlayerID.PLAYER1] = new Gtk.Label(null);
        grid2.attach(label_score[PlayerID.PLAYER1], 1, 0, 1, 1);
        label_score[PlayerID.PLAYER1].xalign = 0;
        label_score[PlayerID.PLAYER1].yalign = 0.5f;

        label_name[PlayerID.PLAYER2] = new Gtk.Label(null);
        grid2.attach(label_name[PlayerID.PLAYER2], 0, 1, 1, 1);
        label_name[PlayerID.PLAYER2].xalign = 0;
        label_name[PlayerID.PLAYER2].yalign = 0.5f;

        label_score[PlayerID.PLAYER2] = new Gtk.Label(null);
        grid2.attach(label_score[PlayerID.PLAYER2], 1, 1, 1, 1);
        label_score[PlayerID.PLAYER2].set_xalign(0);
        label_score[PlayerID.PLAYER2].set_yalign(0.5f);

        label_name[PlayerID.NOBODY] = new Gtk.Label(_("Drawn:"));
        grid2.attach(label_name[PlayerID.NOBODY], 0, 2, 1, 1);
        label_name[PlayerID.NOBODY].set_xalign(0);
        label_name[PlayerID.NOBODY].set_yalign(0.5f);

        label_score[PlayerID.NOBODY] = new Gtk.Label(null);
        grid2.attach(label_score[PlayerID.NOBODY], 1, 2, 1, 1);
        label_score[PlayerID.NOBODY].set_xalign(0);
        label_score[PlayerID.NOBODY].set_yalign(0.5f);
        grid.show_all();

        this.application = application;
    }

    /**
     * update:
     *
     * updates the scorebox with the latest scores
     */
    public void update(int[] scores) {
        if (Prefs.instance.get_n_human_players() == 1) {
            if (Prefs.instance.level[PlayerID.PLAYER1] == Level.HUMAN) {
                label_name[PlayerID.PLAYER1].set_text(_("You:"));
                label_name[PlayerID.PLAYER2].label = _("Me:");
            } else {
                label_name[PlayerID.PLAYER2].set_text(_("You:"));
                label_name[PlayerID.PLAYER1].label = _("Me:");
            }
        } else {
            label_name[PlayerID.PLAYER1].label = theme_get_player(PlayerID.PLAYER1);
            label_name[PlayerID.PLAYER2].label = theme_get_player(PlayerID.PLAYER2);
        }
        label_score[PlayerID.PLAYER1].label = scores[PlayerID.PLAYER1].to_string();
        label_score[PlayerID.PLAYER2].label = scores[PlayerID.PLAYER2].to_string();
        label_score[PlayerID.NOBODY].label = scores[PlayerID.NOBODY].to_string();

    }

    public override bool delete_event(Gdk.EventAny event) {
        hide();
        return true;
    }
}
