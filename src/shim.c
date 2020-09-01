#include "../include/shim.h"

//  Functions which can't be called directly from zig for various reasons.
void shim_put_pixel(int x, int y, const ALLEGRO_COLOR* color) {
  // zig 0.6 can't take a ALLEGRO_COLOR by value
  al_put_pixel(x, y, *color);
}
void shim_clear_to_color(const ALLEGRO_COLOR* color) {
  // zig 0.6 can't take a ALLEGRO_COLOR by value
  al_clear_to_color(*color);
}
bool shim_init() {
  // can't call this directly from zig because it's a macro.
  return al_init();
}
void shim_draw_text(const ALLEGRO_FONT* font, const ALLEGRO_COLOR* color, float x, float y, const char* txt) {
  // zig 0.6 can't take a ALLEGRO_COLOR by value
  al_draw_textf(font, *color, x, y, 0, "%s", txt);
}
void shim_color_name(const char* name,  ALLEGRO_COLOR* color) {
  // zig 0.6 can't return a ALLEGRO_COLOR by value
  *color=al_color_name(name);
}
void shim_color_hsv(float h, float s, float v, ALLEGRO_COLOR* color) {
  // zig 0.6 can't return a ALLEGRO_COLOR by value
  *color=al_color_hsv(h, s, v);
}
