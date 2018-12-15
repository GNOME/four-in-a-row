/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*-
* prefs-box.vala
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
class PrefsBox : Gtk.Dialog {
    Gtk.Notebook notebook;
    Gtk.ComboBox combobox;
    Gtk.ComboBoxText combobox_theme;
    Gtk.ToggleButton checkbutton_sound;

    public PrefsBox(Gtk.Window parent) {
        Gtk.Grid grid;
        GamesControlsList controls_list;
        Gtk.Label label;
        Gtk.CellRendererText renderer;
        Gtk.ListStore model;
        Gtk.TreeIter iter;

        Object(
            title: _("Preferences"),
            destroy_with_parent: true);
        set_transient_for(parent);
        border_width = 5;
        get_content_area().spacing = 2;
        notebook = new Gtk.Notebook();
        notebook.set_border_width(5);
        get_content_area().pack_start(notebook, true, true, 0);

        /* game tab */
        grid = new Gtk.Grid();
        grid.set_row_spacing(6);
        grid.set_column_spacing(12);
        grid.set_border_width(12);

        label = new Gtk.Label(_("Game"));
        notebook.append_page(grid, label);

        label = new Gtk.Label(_("Opponent:"));
        label.set_hexpand(true);
        grid.attach(label,0,0 ,1, 1);

        combobox = new Gtk.ComboBox();
        renderer = new Gtk.CellRendererText();
        combobox.pack_start(renderer, true);
        combobox.add_attribute(renderer, "text", 0);
        model = new Gtk.ListStore(2, typeof(string), typeof(int));
        combobox.set_model(model);
        model.append(out iter);
        model.set(iter, 0, _("Human"), 1, Level.HUMAN);
        if (Prefs.instance.level[PlayerID.PLAYER2] == Level.HUMAN)
            combobox.set_active_iter(iter);
        model.append(out iter);
        model.set(iter, 0, _("Level one"), 1, Level.WEAK);
        if (Prefs.instance.level[PlayerID.PLAYER2] == Level.WEAK)
            combobox.set_active_iter(iter);
        model.append(out iter);
        model.set(iter, 0, _("Level two"), 1, Level.MEDIUM);
        if (Prefs.instance.level[PlayerID.PLAYER2] == Level.MEDIUM)
            combobox.set_active_iter(iter);
        model.append(out iter);
        model.set(iter, 0, _("Level thre"), 1, Level.STRONG);
        if (Prefs.instance.level[PlayerID.PLAYER2] == Level.STRONG)
            combobox.set_active_iter(iter);

        combobox.changed.connect(on_select_opponent);
        grid.attach(combobox, 1, 0, 1, 1);

        label = new Gtk.Label.with_mnemonic(_("_Theme:"));
        label.set_xalign((float)0.0);
        label.set_yalign((float)0.5);
        grid.attach(label, 0, 1, 1, 1);

        combobox_theme = new Gtk.ComboBoxText();
        for (int i = 0; i < theme.length; i++) {
            combobox_theme.append_text(_(theme_get_title(i)));
        }
        label.set_mnemonic_widget(combobox_theme);
        grid.attach(combobox_theme, 1, 1, 1, 1);

        checkbutton_sound = new Gtk.CheckButton.with_mnemonic(_("E_nable sounds"));
        grid.attach(checkbutton_sound, 0, 2, 2, 1);

        /* keyboard tab */
        label = new Gtk.Label.with_mnemonic(_("Keyboard Controls"));

        controls_list = new GamesControlsList(settings);
        controls_list.add_controls("key-left", _("Move left"), DEFAULT_KEY_LEFT,
                       "key-right", _("Move right"), DEFAULT_KEY_RIGHT,
                       "key-drop", _("Drop marble"), DEFAULT_KEY_DROP);
        controls_list.border_width = 12;
        notebook.append_page(controls_list, label);

        /* fill in initial values */
        combobox_theme.set_active(Prefs.instance.theme_id);
        checkbutton_sound.set_active(Prefs.instance.do_sound);

        /* connect signals */
        combobox_theme.changed.connect(on_select_theme);
        checkbutton_sound.toggled.connect(Prefs.instance.on_toggle_sound);
        Prefs.instance.theme_changed.connect((theme_id) => {
            combobox_theme.set_active(theme_id);
        });
        Prefs.instance.sound_changed.connect((sound) => {
            checkbutton_sound.set_active(sound);
        });
    }

    protected override bool delete_event(Gdk.EventAny event) {
        hide();
        return true;
    }

    void on_select_theme(Gtk.ComboBox combo) {
        int id = combo.get_active();
        settings.set_int("theme-id", id);
    }

    void on_select_opponent(Gtk.ComboBox w) {
        Gtk.TreeIter iter;
        int value;

        w.get_active_iter(out iter);
        w.get_model().get(iter, 1, out value);

        Prefs.instance.level[PlayerID.PLAYER2] = (Level)value;
        settings.set_int("opponent", value);
        Scorebox.instance.reset();
        global::application.who_starts = PlayerID.PLAYER2; /* This gets reversed in game_reset. */
        global::application.game_reset();
    }
}
