/*
 * gnect gui.h
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA. 
 */

#ifndef _GNECT_GUI_H_
#define _GNECT_GUI_H_

#define STATUS_MSG_CLEAR             0
#define STATUS_MSG_SET               1
#define STATUS_MSG_FLASH             2

void gui_create (void);
void gui_open (const gchar *geom_str);
void gui_set_status (const gchar *msg_str, gint mode);
void gui_set_status_winner (gint winner, gboolean with_sound);
void gui_set_status_prompt (gint player);
void gui_set_status_prompt_new_game (gint mode);
void gui_set_tooltip (GtkWidget *widget, const gchar *tip_str);
void gui_set_new_sensitive (gboolean sensitive);
void gui_set_hint_sensitive (gboolean sensitive);
void gui_set_undo_sensitive (gboolean sensitive);
void gui_update_hint_sensitivity (void);
void gui_update_undo_sensitivity (void);

#endif
