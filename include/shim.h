#include <allegro5/allegro.h>
#include <allegro5/allegro_color.h>
#include <allegro5/allegro_font.h>
bool shim_init();
void shim_draw_text(const ALLEGRO_FONT*, const ALLEGRO_COLOR*, float x, float y, int flags, const char*);
void shim_color_name(const char* name,  ALLEGRO_COLOR* color);
void shim_color_hsv(float, float, float, ALLEGRO_COLOR*);
