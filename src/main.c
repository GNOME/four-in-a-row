/*
 * gnect main.c
 *
 * Tim Musson
 * <trmusson@ihug.co.nz>
 *
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * http://www.gnu.org/copyleft/gpl.html
 *
 *
 */



#include "config.h"
#include "main.h"
#include "gnect.h"
#include "prefs.h"
#include "gui.h"
#include "gfx.h"


extern Gnect  gnect;
extern Anim   anim;
extern Theme  *theme_current;

gint   seed;
gint   debugging; /* 1=flow | 2=themes | 4=srand | 8=velena */
gchar  *geom_str;
gchar  *fname_theme;


static const struct poptOption opts[] = {
        {
                "geometry",  '\0',
                POPT_ARG_STRING,
                &geom_str, 0,
                N_("Initial window placement"),
                N_("GEOMETRY")
        },
        {
                "seed", 's',
                POPT_ARG_INT,
                &seed, 0,
                N_("Random number seed"),
                N_("SEED")
        },
        {
                "theme", 't',
                POPT_ARG_STRING,
                &fname_theme, 0,
                N_("Initial theme file (excluding path)"),
                N_("FILENAME")
        },
        {
                "debugging", 'd',
                POPT_ARG_INT,
                &debugging, 0,
                N_("Debugging level (4 for random seed)"),
                "N"
        },
        {
                NULL, '\0', 0, NULL, 0
        }
};




int
main (int argc, char *argv[])
{
        struct board *veleng_init ();


        bindtextdomain (PACKAGE, GNOMELOCALEDIR);
        textdomain (PACKAGE);

        if (gnome_init_with_popt_table (APPNAME, VERSION, argc, argv, opts, 0, NULL)) {
                ERROR_PRINT("gnome_init_with_popt_table failed\n");
                exit (1);
        }

        /*
        gnome_program_init (APPNAME, VERSION, LIBGNOMEUI_MODULE,
                            argc, argv, GNOME_PARAM_POPT_TABLE, NULL, NULL);
        */

        prefs_get ();


        /* read all theme files and assign theme_current */
        if (!theme_init (fname_theme)) {
                g_printerr (_("%s: no themes available\n"), APPNAME);
                gnect_cleanup (1);
        }


        anim.id = 0;

        gnect_srand (seed);

        gnect.veleng_board = veleng_init ();

        gnect.who_starts = gnect_get_random_num (2) - 1;
        gnect_reset (FALSE); /* reset, no graphics */

        gui_create ();

        theme_load (theme_current);

        gui_open (geom_str);


        gtk_main ();


        gnect_cleanup (0);
        return 0;
}

