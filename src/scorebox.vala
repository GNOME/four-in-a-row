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

private class Scorebox : Dialog
{
    [CCode (notify = false)] public ThemeManager theme_manager { private get; protected construct; }

    private Label label_name_top;
    private Label label_score_top;
    private Label label_name_mid;
    private Label label_score_mid;
    // no change to the draw name line
    private Label label_score_end;

    internal Scorebox (Window parent, FourInARow application, ThemeManager theme_manager)
    {
        /* Translators: title of the Scores dialog; plural noun */
        Object (title: _("Scores"),
                use_header_bar: /* true */ 1,
                destroy_with_parent: true,
                resizable: false,
                application: application,
                transient_for: parent,
                modal: true,
                theme_manager: theme_manager);
    }

    construct
    {
        Grid grid = new Grid ();
        grid.halign = Align.CENTER;
        grid.row_spacing = 2;
        grid.column_spacing = 6;
        grid.border_width = 10;

        label_name_top = new Label (null);
        grid.attach (label_name_top, 0, 0, 1, 1);
        label_name_top.halign = Align.START;

        label_score_top = new Label (null);
        grid.attach (label_score_top, 1, 0, 1, 1);
        label_score_top.halign = Align.END;

        label_name_mid = new Label (null);
        grid.attach (label_name_mid, 0, 1, 1, 1);
        label_name_mid.halign = Align.START;

        label_score_mid = new Label (null);
        grid.attach (label_score_mid, 1, 1, 1, 1);
        label_score_mid.halign = Align.END;

        /* Translators: in the Scores dialog, label of the line where is indicated the number of tie games */
        Label label_name_end = new Label (_("Drawn:"));
        grid.attach (label_name_end, 0, 2, 1, 1);
        label_name_end.halign = Align.START;

        label_score_end = new Label (null);
        grid.attach (label_score_end, 1, 2, 1, 1);
        label_score_end.halign = Align.END;

        grid.show_all ();
        get_content_area ().pack_start (grid);

        theme_manager.theme_changed.connect (update);
    }

    private void update ()
    {
        if (one_player_game)
        {
            if (scores [Player.HUMAN] >= scores [Player.OPPONENT])
            {
                /* Translators: in the Scores dialog, label of the line where is indicated the number of games won by the human player */
                label_name_top.set_text (_("You:"));

                /* Translators: in the Scores dialog, label of the line where is indicated the number of games won by the computer player */
                label_name_mid.set_text (_("Me:"));

                label_score_top.label = scores [Player.HUMAN   ].to_string ();
                label_score_mid.label = scores [Player.OPPONENT].to_string ();
            }
            else
            {
                /* Translators: in the Scores dialog, label of the line where is indicated the number of games won by the computer player */
                label_name_top.set_text (_("Me:"));

                /* Translators: in the Scores dialog, label of the line where is indicated the number of games won by the human player */
                label_name_mid.set_text (_("You:"));

                label_score_top.label = scores [Player.OPPONENT].to_string ();
                label_score_mid.label = scores [Player.HUMAN   ].to_string ();
            }
        }
        else
        {
            if (scores [Player.HUMAN] >= scores [Player.OPPONENT])
            {
                label_name_top.label = theme_manager.get_player (Player.HUMAN,    /* with colon */ true);
                label_name_mid.label = theme_manager.get_player (Player.OPPONENT, /* with colon */ true);

                label_score_top.label = scores [Player.HUMAN   ].to_string ();
                label_score_mid.label = scores [Player.OPPONENT].to_string ();
            }
            else
            {
                label_name_top.label = theme_manager.get_player (Player.OPPONENT, /* with colon */ true);
                label_name_mid.label = theme_manager.get_player (Player.HUMAN,    /* with colon */ true);

                label_score_top.label = scores [Player.OPPONENT].to_string ();
                label_score_mid.label = scores [Player.HUMAN   ].to_string ();
            }
        }
        label_score_end.label = scores [Player.NOBODY].to_string ();
    }

    protected override bool delete_event (Gdk.EventAny event)   // TODO use hide_on_delete (Gtk3) or hide-on-close (Gtk4)
    {
        hide ();
        return true;
    }

    /*\
    * * score management
    \*/

    private bool one_player_game = false;
    private Player last_winner = Player.NOBODY;
    private uint [] scores = { /* human */ 0, /* opponent */ 0, /* draw */ 0 };

    internal void new_match (bool _one_player_game)
    {
        scores = { 0, 0, 0 };
        last_winner = Player.NOBODY;
        one_player_game = _one_player_game;
        update ();
    }

    internal void give_up (Player player)
    {
        if (player == Player.HUMAN)
            scores [Player.OPPONENT]++;
        else if (player == Player.OPPONENT)
            scores [Player.HUMAN]++;
        else
            assert_not_reached ();
        update ();
    }

    internal void win (Player player)
    {
        scores [player]++;
        last_winner = player;
        update ();
    }

    internal void unwin ()
    {
        if (last_winner == Player.NOBODY)
            assert_not_reached ();
        scores [last_winner]--;
        last_winner = Player.NOBODY;
        update ();
    }

    internal bool is_first_game ()
    {
        return scores [Player.HUMAN] + scores [Player.OPPONENT] + scores [Player.NOBODY] == 0;
    }
}
