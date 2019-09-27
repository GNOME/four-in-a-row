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

private class PrefsBox : Dialog {
    private const uint DEFAULT_KEY_LEFT = Gdk.Key.Left;
    private const uint DEFAULT_KEY_RIGHT = Gdk.Key.Right;
    private const uint DEFAULT_KEY_DROP = Gdk.Key.Down;

    internal PrefsBox(Window parent) {
        Notebook notebook;
        ComboBox combobox;

        Grid grid;
        GamesControlsList controls_list;
        Label label;
        CellRendererText renderer;
        Gtk.ListStore model;
        TreeIter iter;

        Object(
            title: _("Preferences"),
            destroy_with_parent: true);
        set_transient_for(parent);
        this.application = parent.application;
        modal = true;
        border_width = 5;
        get_content_area().spacing = 2;
        notebook = new Notebook();
        notebook.set_border_width(5);
        get_content_area().pack_start(notebook, true, true, 0);

        /* game tab */
        grid = new Grid();
        grid.set_row_spacing(6);
        grid.set_column_spacing(12);
        grid.set_border_width(12);

        label = new Label(_("Game"));
        notebook.append_page(grid, label);

        label = new Label(_("Opponent:"));  // TODO add a mnemonic?
        label.set_xalign((float)0.0);
        label.set_yalign((float)0.5);
        label.set_hexpand(true);
        grid.attach(label,0,0 ,1, 1);

        combobox = new ComboBox();
        renderer = new CellRendererText();
        combobox.pack_start(renderer, true);
        combobox.add_attribute(renderer, "text", 0);
        model = new Gtk.ListStore(2, typeof(string), typeof(int));
        combobox.set_model(model);
        model.append(out iter);
        model.@set(iter, 0, _("Human"), 1, Level.HUMAN);
        if (Prefs.instance.level[PlayerID.PLAYER2] == Level.HUMAN)
            combobox.set_active_iter(iter);
        model.append(out iter);
        model.@set(iter, 0, _("Level one"), 1, Level.WEAK);
        if (Prefs.instance.level[PlayerID.PLAYER2] == Level.WEAK)
            combobox.set_active_iter(iter);
        model.append(out iter);
        model.@set(iter, 0, _("Level two"), 1, Level.MEDIUM);
        if (Prefs.instance.level[PlayerID.PLAYER2] == Level.MEDIUM)
            combobox.set_active_iter(iter);
        model.append(out iter);
        model.@set(iter, 0, _("Level three"), 1, Level.STRONG);
        if (Prefs.instance.level[PlayerID.PLAYER2] == Level.STRONG)
            combobox.set_active_iter(iter);

        combobox.changed.connect(on_select_opponent);
        grid.attach(combobox, 1, 0, 1, 1);

        /* keyboard tab */
        label = new Label.with_mnemonic(_("Keyboard Controls"));

        controls_list = new GamesControlsList(Prefs.instance.settings);
        controls_list.add_controls("key-left",  _("Move left"),     DEFAULT_KEY_LEFT,
                                   "key-right", _("Move right"),    DEFAULT_KEY_RIGHT,
                                   "key-drop",  _("Drop marble"),   DEFAULT_KEY_DROP);
        controls_list.border_width = 12;
        notebook.append_page(controls_list, label);
    }

    protected override bool delete_event(Gdk.EventAny event) {  // TODO use hide_on_delete (Gtk3) or hide-on-close (Gtk4) 2/2
        hide();
        return true;
    }

    private inline void on_select_opponent(ComboBox combobox) {
        FourInARow app = (FourInARow)application;
        TreeIter iter;
        int iter_value;

        combobox.get_active_iter(out iter);
        combobox.get_model().@get(iter, 1, out iter_value);

        Prefs.instance.level[PlayerID.PLAYER2] = (Level)iter_value;
        Prefs.instance.settings.set_int("opponent", iter_value);
        app.who_starts = PlayerID.PLAYER2; /* This gets reversed in game_reset. */
        app.game_reset();
    }
}
