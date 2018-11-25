/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* games-controls.vala
 *
 * Copyright © 2018 Jacob Humphrey
 *
 * This file is part of GNOME Four in a Row.
 *
 * GNOME Four in a Row is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * GNOME Four in a Row is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with GNOME Four in a Row. If not, see <http://www.gnu.org/licenses/>.
 */


/*
 * Needed to force vala to include headers in the correct order.
 * See https://gitlab.gnome.org/GNOME/vala/issues/98
 */
const string games_controls_gettext_package = Config.GETTEXT_PACKAGE;

enum Columns {
    CONFKEY_COLUMN = 0,
    LABEL_COLUMN,
    KEYCODE_COLUMN,
    KEYMODS_COLUMN,
    DEFAULT_KEYCODE_COLUMN,
    DEFAULT_KEYMODS_COLUMN,
    N_COLUMNS
}

public class GamesControlsList : Gtk.ScrolledWindow {
    Gtk.TreeModel model;
    Gtk.ListStore store;
    Gtk.TreeView view;

    Settings settings;
    ulong notify_handler_id;

    public GamesControlsList(GLib.Settings settings) {
        Gtk.CellRenderer label_renderer;
        Gtk.CellRendererAccel key_renderer;
        Gtk.TreeViewColumn column;

        this.hscrollbar_policy = Gtk.PolicyType.NEVER;
        this.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
        this.shadow_type = Gtk.ShadowType.IN;
        this.settings = settings;
        notify_handler_id = settings.changed
            .connect(settings_changed_cb);

        store = new Gtk.ListStore(Columns.N_COLUMNS,
            Type.STRING,
            Type.STRING,
            Type.UINT,
            Type.UINT,
            Type.UINT,
            Type.UINT);

        model = store;
        view = new Gtk.TreeView.with_model(model);

        view.headers_visible = false;
        view.enable_search = false;

        label_renderer = new Gtk.CellRendererText();
        column = new Gtk.TreeViewColumn.with_attributes("Control", label_renderer,
            "text", Columns.LABEL_COLUMN);

        view.append_column(column);

        key_renderer = new Gtk.CellRendererAccel();

        key_renderer.editable = true;
        key_renderer.accel_mode = Gtk.CellRendererAccelMode.OTHER;

        key_renderer.accel_edited.connect(this.accel_edited_cb);
        key_renderer.accel_cleared.connect(this.accel_cleared_cb);

        column = new Gtk.TreeViewColumn.with_attributes("Key", key_renderer,
            "accel-key", Columns.KEYCODE_COLUMN,
            "accel-mods", Columns.KEYMODS_COLUMN);

        view.append_column(column);
        this.add(view);
    }

    void accel_cleared_cb (string path_string) {
        Gtk.TreePath path;
        Gtk.TreeIter iter;
        string conf_key = null;
        int default_keyval = 0; //set to 0 to make valac happy

        path = new Gtk.TreePath.from_string (path_string);
        if (path == null)
            return;

        if (!model.get_iter (out iter, path)) {
            return;
        }

        model.get(iter,
                  Columns.CONFKEY_COLUMN, conf_key,
                  Columns.DEFAULT_KEYCODE_COLUMN, default_keyval);

        if(conf_key == null)
            return;

        /* Note: the model is updated in the conf notification callback */
        /* FIXME: what to do with the modifiers? */
        settings.set_int(conf_key, default_keyval);
    }

    void accel_edited_cb (string path_string, uint keyval, Gdk.ModifierType mask, uint hardware_keycode) {
        Gtk.TreePath path;
        Gtk.TreeIter iter;
        string conf_key = null;
        bool valid;
        bool unused_key = true;


        path = new Gtk.TreePath.from_string (path_string);
        if (path == null)
            return;

        if (!model.get_iter (out iter, path)) {
            return;
        }

        model.get (iter, Columns.CONFKEY_COLUMN, conf_key);
        if (conf_key == null)
            return;

        valid = model.get_iter_first (out iter);
        while (valid) {
            string actual_conf_key = null;

            model.get (iter, Columns.CONFKEY_COLUMN, actual_conf_key);

            if (settings.get_int (actual_conf_key) == keyval){
                unused_key = false;

                if (conf_key == actual_conf_key) {
                    var dialog = new Gtk.MessageDialog.with_markup (window,
                        Gtk.DialogFlags.DESTROY_WITH_PARENT,
                        Gtk.MessageType.WARNING,
                        Gtk.ButtonsType.OK,
                        "<span weight=\"bold\" size=\"larger\">%s</span>",
                        _("This key is already in use."));

                    dialog.run();
                }
                break;
            }

            valid = store.iter_next (ref iter);
        }

        /* Note: the model is updated in the conf notification callback */
        /* FIXME: what to do with the modifiers? */
        if (unused_key)
            settings.set_int (conf_key, (int)keyval);
    }

    void add_control (string conf_key, string? label, uint default_keyval) {
        Gtk.TreeIter iter;
        uint keyval;

        if (label == null)
            label = _("Unknown Command");

        keyval = settings.get_int(conf_key);

        store.insert_with_values(out iter, -1,
            Columns.CONFKEY_COLUMN, conf_key,
            Columns.LABEL_COLUMN, label,
            Columns.KEYCODE_COLUMN, keyval,
            Columns.KEYMODS_COLUMN, 0,
            Columns.DEFAULT_KEYCODE_COLUMN, default_keyval,
            Columns.DEFAULT_KEYMODS_COLUMN, 0
            );

    }

    public void add_controls (string first_gconf_key, ...) {
        var args = va_list();
        string? key;
        string label;
        uint keyval;

        key = first_gconf_key;
        while (key != null) {
            label = args.arg();
            keyval = args.arg();
            this.add_control (key, label, keyval);
            key = args.arg();
        }
    }
}
