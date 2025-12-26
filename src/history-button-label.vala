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

using Gtk;

private class HistoryButtonLabel : Widget
{
    [CCode (notify = false)] public ThemeManager theme_manager { private get; protected construct; }

    private Stack stack;
    private Picture picture_piece;
    private Piece human_piece;
    private Piece opponent_piece;

    public HistoryButtonLabel (ThemeManager theme_manager)
    {
        Object (theme_manager: theme_manager);

        human_piece = new Piece (theme_manager, Player.HUMAN);
        opponent_piece = new Piece (theme_manager, Player.OPPONENT);
        theme_manager.theme_changed.connect (() => {
            human_piece = new Piece (theme_manager, Player.HUMAN);
            opponent_piece = new Piece (theme_manager, Player.OPPONENT);
        });
    }

    construct
    {
        width_request = 56;

        layout_manager = new BinLayout ();

        stack = new Stack ();
        stack.set_parent (this);

        var b = new Box (Orientation.HORIZONTAL, 2);
        var picture_arrow = new Picture ();
        picture_arrow.hexpand = true;
        picture_arrow.paintable = new Arrow ();
        b.append (picture_arrow);

        picture_piece = new Picture ();
        picture_piece.hexpand = true;
        picture_piece.paintable = human_piece;
        b.append (picture_piece);

        stack.add_named (b, "turn");

        /* Translators: label of the game status button (in the headerbar, next to the hamburger button); please keep the string as small as possible (3~5 characters) */
        var label = new Label (_("End!"));
        stack.add_named (label, "end");
    }

    public void set_player (Player player)
    {
        switch (player)
        {
            case Player.HUMAN:
                picture_piece.paintable = human_piece;
                stack.visible_child_name = "turn";
                break;
            case Player.OPPONENT:
                picture_piece.paintable = opponent_piece;
                stack.visible_child_name = "turn";
                break;
            case Player.NOBODY:
                stack.visible_child_name = "end";
                break;
            default:
                assert_not_reached ();
        }
    }
}
