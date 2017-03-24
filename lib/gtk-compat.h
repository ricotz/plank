/*
 *  Copyright (C) 2015 Rico Tzschichholz
 *
 *  This file is part of Plank.
 *
 *  Plank is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Plank is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef __PLANK_GTK_COMPAT_H__
#define __PLANK_GTK_COMPAT_H__

#include <gtk/gtk.h>

G_BEGIN_DECLS

/* Conditional compat-layer for Gtk+ 3.19.1+ */
void plank_compat_gtk_widget_class_set_css_name (GtkWidgetClass *widget_class, const char *name);
void plank_compat_gtk_widget_path_iter_set_object_name (GtkWidgetPath *path, gint pos, const char *name);

G_END_DECLS

#endif
