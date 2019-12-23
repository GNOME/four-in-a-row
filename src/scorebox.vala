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

    private Label label_name_top;
    private Label label_score_top;
    private Label label_name_mid;
    private Label label_score_mid;
    // no change to the draw name line
    private Label label_score_end;

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

        grid = new Grid();
        grid.halign = Align.CENTER;
        grid.row_spacing = 6;
        grid.orientation = Orientation.VERTICAL;
        grid.border_width = 5;

        get_content_area().pack_start(grid);

        grid2 = new Grid();
        grid.add(grid2);
        grid2.column_spacing = 6;

        label_name_top = new Label(null);
        grid2.attach(label_name_top, 0, 0, 1, 1);
        label_name_top.xalign = 0;
        label_name_top.yalign = 0.5f;

        label_score_top = new Label(null);
        grid2.attach(label_score_top, 1, 0, 1, 1);
        label_score_top.xalign = 0;
        label_score_top.yalign = 0.5f;

        label_name_mid = new Label(null);
        grid2.attach(label_name_mid, 0, 1, 1, 1);
        label_name_mid.xalign = 0;
        label_name_mid.yalign = 0.5f;

        label_score_mid = new Label(null);
        grid2.attach(label_score_mid, 1, 1, 1, 1);
        label_score_mid.set_xalign(0);
        label_score_mid.set_yalign(0.5f);

        /* Translators: in the Scores dialog, label of the line where is indicated the number of tie games */
        Label label_name_end = new Label(_("Drawn:"));
        grid2.attach(label_name_end, 0, 2, 1, 1);
        label_name_end.set_xalign(0);
        label_name_end.set_yalign(0.5f);

        label_score_end = new Label(null);
        grid2.attach(label_score_end, 1, 2, 1, 1);
        label_score_end.set_xalign(0);
        label_score_end.set_yalign(0.5f);
        grid.show_all();
    }

    /**
     * update:
     *
     * updates the scorebox with the latest scores
     */
    internal void update(uint[] scores, bool one_player_game) {
        if (one_player_game) {
            if (scores[Player.HUMAN] >= scores[Player.OPPONENT]) {
                /* Translators: in the Scores dialog, label of the line where is indicated the number of games won by the human player */
                label_name_top.set_text(_("You:"));

                /* Translators: in the Scores dialog, label of the line where is indicated the number of games won by the computer player */
                label_name_mid.set_text(_("Me:"));

                label_score_top.label = scores[Player.HUMAN].to_string();
                label_score_mid.label = scores[Player.OPPONENT].to_string();
            } else {
                /* Translators: in the Scores dialog, label of the line where is indicated the number of games won by the computer player */
                label_name_top.set_text(_("Me:"));

                /* Translators: in the Scores dialog, label of the line where is indicated the number of games won by the human player */
                label_name_mid.set_text(_("You:"));

                label_score_top.label = scores[Player.OPPONENT].to_string();
                label_score_mid.label = scores[Player.HUMAN].to_string();
            }
        } else {
            if (scores[Player.HUMAN] >= scores[Player.OPPONENT]) {
                label_name_top.label = theme_get_player(Player.HUMAN,    (uint8) theme_id);    // FIXME missing ":" at end
                label_name_mid.label = theme_get_player(Player.OPPONENT, (uint8) theme_id);    // idem

                label_score_top.label = scores[Player.HUMAN].to_string();
                label_score_mid.label = scores[Player.OPPONENT].to_string();
            } else {
                label_name_top.label = theme_get_player(Player.OPPONENT, (uint8) theme_id);    // FIXME missing ":" at end
                label_name_mid.label = theme_get_player(Player.HUMAN,    (uint8) theme_id);    // idem

                label_score_top.label = scores[Player.OPPONENT].to_string();
                label_score_mid.label = scores[Player.HUMAN].to_string();
            }
        }
        label_score_end.label = scores[Player.NOBODY].to_string();
    }

    protected override bool delete_event(Gdk.EventAny event) {  // TODO use hide_on_delete (Gtk3) or hide-on-close (Gtk4) 1/2
        hide();
        return true;
    }
}
