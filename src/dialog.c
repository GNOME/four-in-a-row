/*
 * gnect dialog.c
 *
 */



#include "config.h"
#include "main.h"
#include "dialog.h"
#include "gnect.h"
#include "prefs.h"



extern gint      debugging;
extern Gnect     gnect;
extern Prefs     prefs;
extern GtkWidget *app;


static GtkWidget *label_descr1;
static GtkWidget *label_descr2;
static GtkWidget *label_score1;
static GtkWidget *label_score2;
static GtkWidget *label_score_drawn;

static GtkWidget *dlg_score = NULL;


void
dialog_about (void)
{
        /*
         * Display the About dialog.
         */

        const gchar *authors[] = {"Gnect:",
                                  "  Tim Musson <trmusson@ihug.co.nz>",
                                  "  David Neary <bolsh@gimp.org>",
                                  "\nVelena Engine V1.07; revision Apr 18 2002:",
                                  "  AI engine written by Giuliano Bertoletti",
                                  "  Based on the knowledged approach of Victor Allis",
                                  "  Copyright (C) 1996-97 ",
                                  "  Giuliano Bertoletti and GBE 32241 Software PR.",
                                  NULL};
        const gchar *documents[] = { NULL };
        const gchar *translator = _("translator");
        static GtkWidget *dlg_about;
        GdkPixbuf *logo;


        if (dlg_about != NULL) {
                gdk_window_show(dlg_about->window);
                gdk_window_raise(dlg_about->window);
                return;
        }

        logo = gdk_pixbuf_new_from_file (FNAME_GNECT_LOGO, NULL);

        dlg_about = gnome_about_new (APPNAME,
                                     VERSION,
                                     "(c) 1999-2002, The Authors",
                                     _("\"Four in a row\" for GNOME, with a computer player driven by Giuliano Bertoletti's Velena Engine.\n\nhttp://homepages.ihug.co.nz/~trmusson/gnect.html"),
                                     authors,
                                     documents,
                                     strcmp (translator, "translator") != 0 ? translator : NULL,
                                     logo);

        gtk_window_set_transient_for (GTK_WINDOW (dlg_about), GTK_WINDOW(app));

        if (logo) g_object_unref (logo); 

        g_signal_connect (dlg_about, "destroy", 
                          GTK_SIGNAL_FUNC (gtk_widget_destroyed), &dlg_about);

        gtk_widget_show (dlg_about);
}



void
dialog_score_update (void)
{
        /*
         * If the scorebox dialog exists, update the info it's showing.
         */

        gchar *str;

        DEBUG_PRINT (1, "dialog_score_update\n");

        if (dlg_score) {

                if (gnect_get_n_players () == 1) {
                        if (prefs.player1 == PLAYER_HUMAN) {
                                gtk_label_set_text (GTK_LABEL (label_descr1), _("You"));
                                gtk_label_set_text (GTK_LABEL (label_descr2), _("Me"));
                        }
                        else {
                                gtk_label_set_text (GTK_LABEL (label_descr1), _("Me"));
                                gtk_label_set_text (GTK_LABEL (label_descr2), _("You"));
                        }
                }
                else {
                        gtk_label_set_text (GTK_LABEL (label_descr1), prefs.descr_player1);
                        gtk_label_set_text (GTK_LABEL (label_descr2), prefs.descr_player2);
                }

                str = g_strdup_printf (" %d", gnect.score[PLAYER_1]);
                gtk_label_set_text (GTK_LABEL (label_score1), str);
                g_free(str);

                str = g_strdup_printf (" %d", gnect.score[PLAYER_2]);
                gtk_label_set_text (GTK_LABEL (label_score2), str);
                g_free(str);

                str = g_strdup_printf (" %d", gnect.score[DRAWN_GAME]);
                gtk_label_set_text (GTK_LABEL(label_score_drawn), str);
                g_free (str);

        }
}



static void
cb_dialog_score_hide (GtkWidget *widget, int response_id, gpointer *data)
{
        if (response_id == GTK_RESPONSE_CLOSE) {
                gtk_widget_hide (dlg_score);
        }
}



static void
dialog_score_create (void)
{
        /*
         * Build the scorebox dialog.
         */

        GtkWidget *table, *vbox, *vbox2, *frame, *label, *icon;
        GError *errors;


        dlg_score = gtk_dialog_new_with_buttons (_("Scores"),
                                                 GTK_WINDOW (app),
                                                 GTK_DIALOG_DESTROY_WITH_PARENT,
                                                 GTK_STOCK_CLOSE, 
                                                 GTK_RESPONSE_CLOSE,
                                                 NULL);

        vbox = GTK_DIALOG (dlg_score)->vbox;
        gtk_object_set_data (GTK_OBJECT (dlg_score), "vbox", vbox);
        gtk_widget_show (vbox);

        vbox2 = gtk_vbox_new (FALSE, 0);
        gtk_widget_show (vbox2);
        gtk_box_pack_start (GTK_BOX (vbox), vbox2, TRUE, TRUE, 0);

        frame = gtk_frame_new (NULL);
        gtk_widget_show (frame);
        gtk_box_pack_start (GTK_BOX (vbox2), frame, FALSE, FALSE, 0);

        table = gtk_table_new (3, 2, FALSE);
        gtk_widget_show (table);
        gtk_box_pack_start (GTK_BOX (vbox2), table, TRUE, TRUE, 0);
        gtk_container_set_border_width (GTK_CONTAINER (table), 5);
        gtk_table_set_col_spacings (GTK_TABLE (table), 10);


        /* player one */

        label_descr1 = gtk_label_new (NULL);
        gtk_widget_show (label_descr1);
        gtk_table_attach (GTK_TABLE (table), label_descr1, 0, 1, 0, 1,
                          (GtkAttachOptions) (GTK_FILL), (GtkAttachOptions) (0), 0, 0);
        gtk_misc_set_alignment (GTK_MISC (label_descr1), 0, 0.5);

        label_score1 = gtk_label_new (NULL);
        gtk_widget_show (label_score1);
        gtk_table_attach (GTK_TABLE (table), label_score1, 1, 2, 0, 1,
                          (GtkAttachOptions) (GTK_EXPAND | GTK_FILL), (GtkAttachOptions) (0), 0, 0);
        gtk_misc_set_alignment (GTK_MISC (label_score1), 1, 0.5);


        /* player two */

        label_descr2 = gtk_label_new (NULL);
        gtk_widget_show (label_descr2);
        gtk_table_attach (GTK_TABLE (table), label_descr2, 0, 1, 1, 2,
                          (GtkAttachOptions) (GTK_FILL), (GtkAttachOptions) (0), 0, 0);
        gtk_misc_set_alignment (GTK_MISC (label_descr2), 0, 0.5);

        label_score2 = gtk_label_new (NULL);
        gtk_widget_show (label_score2);
        gtk_table_attach (GTK_TABLE (table), label_score2, 1, 2, 1, 2,
                          (GtkAttachOptions) (GTK_EXPAND | GTK_FILL), (GtkAttachOptions) (0), 0, 0);
        gtk_misc_set_alignment (GTK_MISC (label_score2), 1, 0.5);


        /* drawn games */

        label = gtk_label_new (_("Drawn"));
        gtk_widget_show (label);
        gtk_table_attach (GTK_TABLE (table), label, 0, 1, 2, 3,
                          (GtkAttachOptions) (GTK_FILL), (GtkAttachOptions) (0), 0, 0);
        gtk_misc_set_alignment (GTK_MISC (label), 0, 0.5);

        label_score_drawn = gtk_label_new (NULL);
        gtk_widget_show (label_score_drawn);
        gtk_table_attach (GTK_TABLE (table), label_score_drawn, 1, 2, 2, 3,
                          (GtkAttachOptions) (GTK_EXPAND | GTK_FILL), (GtkAttachOptions) (0), 0, 0);
        gtk_misc_set_alignment (GTK_MISC (label_score_drawn), 1, 0.5);


        /* scorebox icon */

        icon = gtk_image_new_from_file (FNAME_GNECT_ICON);
        gtk_widget_show (icon);
        gtk_container_add (GTK_CONTAINER(frame), icon);


        /* set label text */

        dialog_score_update ();


        /* connect close button */

        g_signal_connect (GTK_DIALOG (dlg_score), "response", 
                          GTK_SIGNAL_FUNC (cb_dialog_score_hide), NULL);
}



void
dialog_score (void)
{
        if (!dlg_score) {

                /* build and show it */

                dialog_score_create ();
                gtk_widget_show (dlg_score);

        }
        else {

                /* already built - make sure it's visible */

                gtk_widget_show (dlg_score);
                gdk_window_show (dlg_score->window);
                gdk_window_raise (dlg_score->window);

        }
}

