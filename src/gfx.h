/* gfx.h */



gboolean gfx_load (gint id);
void     gfx_free (void);
void     gfx_expose (GdkRectangle *area);
void     gfx_draw_tile (gint r, gint c, gboolean refresh);
void     gfx_draw_all (gboolean refresh);
void     gfx_draw_grid (void);
gint     gfx_get_column (gint xpos);

