#include "../include/shim.h"

//  Functions which can't be called directly from zig for various reasons.
bool shim_init() {
  // can't call this directly from zig because it's a macro.
  return al_init();
}
