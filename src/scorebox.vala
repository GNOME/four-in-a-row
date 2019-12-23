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

private class Scorebox : Dialog {
    [CCode (notify = false)] internal int theme_id { private get; internal set; }

    private Label[] label_name;
    private Label[] label_score;

    internal Scorebox(Window parent, FourInARow application) {
        /* Translators: title of the Scores dialog; plural noun */
        Object(title: _("Scores"),
               use_header_bar: 1,
               destroy_with_parent: true,
               resizable: false,
               border_width: 5,
               application: application);
        get_content_area().spacing = 2;
        set_transient_for(parent);
        modal = true;

        Grid grid, grid2;

        label_name = new Label[3];
        label_score = new Label[3];

        grid = new Grid();
        grid.halign = Align.CENTER;
        grid.row_spacing = 6;
        grid.orientation = Orientation.VERTICAL;
        grid.border_width = 5;

        get_content_area().pack_start(grid);

        grid2 = new Grid();
        grid.add(grid2);
        grid2.column_spacing = 6;

        label_name[PlayerID.HUMAN] = new Label(null);
        grid2.attach(label_name[PlayerID.HUMAN], 0, 0, 1, 1);
        label_name[PlayerID.HUMAN].xalign = 0;
        label_name[PlayerID.HUMAN].yalign = 0.5f;

        label_score[PlayerID.HUMAN] = new Label(null);
        grid2.attach(label_score[PlayerID.HUMAN], 1, 0, 1, 1);
        label_score[PlayerID.HUMAN].xalign = 0;
        label_score[PlayerID.HUMAN].yalign = 0.5f;

        label_name[PlayerID.OPPONENT] = new Label(null);
        grid2.attach(label_name[PlayerID.OPPONENT], 0, 1, 1, 1);
        label_name[PlayerID.OPPONENT].xalign = 0;
        label_name[PlayerID.OPPONENT].yalign = 0.5f;

        label_score[PlayerID.OPPONENT] = new Label(null);
        grid2.attach(label_score[PlayerID.OPPONENT], 1, 1, 1, 1);
        label_score[PlayerID.OPPONENT].set_xalign(0);
        label_score[PlayerID.OPPONENT].set_yalign(0.5f);

        /* Translators: in the Scores dialog, label of the line where is indicated the number of tie games */
        label_name[PlayerID.NOBODY] = new Label(_("Drawn:"));
        grid2.attach(label_name[PlayerID.NOBODY], 0, 2, 1, 1);
        label_name[PlayerID.NOBODY].set_xalign(0);
        label_name[PlayerID.NOBODY].set_yalign(0.5f);

        label_score[PlayerID.NOBODY] = new Label(null);
        grid2.attach(label_score[PlayerID.NOBODY], 1, 2, 1, 1);
        label_score[PlayerID.NOBODY].set_xalign(0);
        label_score[PlayerID.NOBODY].set_yalign(0.5f);
        grid.show_all();
    }

    /**
     * update:
     *
     * updates the scorebox with the latest scores
     */
    internal void update(uint[] scores, bool one_player_game) {
        if (one_player_game) {
            if (scores[PlayerID.HUMAN] >= scores[PlayerID.OPPONENT]) {
                /* Translators: in the Scores dialog, label of the line where is indicated the number of games won by the human player */
                label_name[0].set_text(_("You:"));

                /* Translators: in the Scores dialog, label of the line where is indicated the number of games won by the computer player */
                label_name[1].set_text(_("Me:"));

                label_score[0].label = scores[PlayerID.HUMAN].to_string();
                label_score[1].label = scores[PlayerID.OPPONENT].to_string();
            } else {
                /* Translators: in the Scores dialog, label of the line where is indicated the number of games won by the computer player */
                label_name[0].set_text(_("Me:"));

                /* Translators: in the Scores dialog, label of the line where is indicated the number of games won by the human player */
                label_name[1].set_text(_("You:"));

                label_score[0].label = scores[1].to_string();
                label_score[1].label = scores[0].to_string();
            }
        } else {
            label_name[0].label = theme_get_player(PlayerID.HUMAN, (uint8) theme_id);    // FIXME missing ":" at end
            label_name[1].label = theme_get_player(PlayerID.OPPONENT, (uint8) theme_id);    // idem

            label_score[PlayerID.HUMAN].label = scores[PlayerID.HUMAN].to_string();
            label_score[PlayerID.OPPONENT].label = scores[PlayerID.OPPONENT].to_string();
        }
        label_score[PlayerID.NOBODY].label  = scores[PlayerID.NOBODY].to_string();

    }

    protected override bool delete_event(Gdk.EventAny event) {  // TODO use hide_on_delete (Gtk3) or hide-on-close (Gtk4) 1/2
        hide();
        return true;
    }
}
