#include <allegro5/allegro.h>
#include <allegro5/allegro_color.h>
#include <allegro5/allegro_font.h>
void shim_put_pixel(int x, int y, const struct ALLEGRO_COLOR* color);
bool shim_init();
void shim_clear_to_color(const struct ALLEGRO_COLOR* color);
void shim_draw_text(const ALLEGRO_FONT*, const ALLEGRO_COLOR*, float x, float y, const char*);
void shim_color_name(const char* name,  ALLEGRO_COLOR* color);
void shim_color_hsv(float, float, float, ALLEGRO_COLOR*);
