const std = @import("std");
const a5 = @cImport({
    @cInclude("allegro5/allegro.h");
    @cInclude("allegro5/allegro_font.h");
    @cInclude("allegro5/allegro_image.h");
    @cInclude("allegro5/allegro_color.h");
    @cInclude("shim.h");
});

// Soon these shims can go away...
fn al_color_name(name: []const u8) a5.ALLEGRO_COLOR {
    var c: a5.ALLEGRO_COLOR = undefined;
    a5.shim_color_name(@ptrCast([*c]const u8, name), &c);
    return c;
}

fn al_color_hsv(h: f32, s: f32, v: f32) a5.ALLEGRO_COLOR {
    var c: a5.ALLEGRO_COLOR = undefined;
    a5.shim_color_hsv(h, s, v, &c);
    return c;
}

fn al_init() bool {
    return a5.shim_init();
}
// end shim

const Timer = struct {
    timer: f64 = 0.0,
    counter: f64 = 0.0,
    fn start(self: *Timer) void {
        self.*.timer -= a5.al_get_time();
        self.*.counter += 1.0;
    }
    fn stop(self: *Timer) void {
        self.*.timer += a5.al_get_time();
    }
    fn fps(self: Timer) f64 {
        if (self.timer == 0.0) {
            return 0.0;
        } else {
            return self.counter / self.timer;
        }
    }
};

const Example = struct {
    pattern: *a5.ALLEGRO_BITMAP, font: *a5.ALLEGRO_FONT, queue: *a5.ALLEGRO_EVENT_QUEUE, background: a5.ALLEGRO_COLOR, text: a5.ALLEGRO_COLOR, white: a5.ALLEGRO_COLOR, timer: [4]Timer, FPS: i32, text_x: f32, text_y: f32
};
var ex = Example{
    .pattern = undefined,
    .font = undefined,
    .queue = undefined,
    .background = undefined,
    .text = undefined,
    .white = undefined,
    .timer = [_]Timer{.{}} ** 4,
    .FPS = undefined,
    .text_x = undefined,
    .text_y = undefined,
};

fn example_bitmap(w: i32, h: i32) *a5.ALLEGRO_BITMAP {
    const mx: f32 = @intToFloat(f32, w) * 0.5;
    const my: f32 = @intToFloat(f32, h) * 0.5;
    var state = a5.ALLEGRO_STATE{ ._tls = undefined };
    if (a5.al_create_bitmap(w, h)) |pattern| {
        a5.al_store_state(@ptrCast([*c]a5.ALLEGRO_STATE, &state), a5.ALLEGRO_STATE_TARGET_BITMAP);
        a5.al_set_target_bitmap(pattern);
        _ = a5.al_lock_bitmap(pattern, a5.ALLEGRO_PIXEL_FORMAT_ANY, a5.ALLEGRO_LOCK_WRITEONLY);
        var i: i32 = 0;
        while (i < w) : (i += 1) {
            var j: i32 = 0;
            while (j < h) : (j += 1) {
                const x = @intToFloat(f32, i) - mx;
                const y = @intToFloat(f32, j) - my;
                const a = std.math.atan2(f32, y, x);
                const d = std.math.sqrt(std.math.pow(f32, x, 2) + std.math.pow(f32, y, 2));
                const sat = std.math.pow(f32, 1.0 - 1.0 / (1.0 + d * 0.1), 5);
                var hue = 3.0 * a * 180 / std.math.pi;
                hue = (hue / 360 - std.math.floor(hue / 360.0)) * 360.0;
                var color: a5.ALLEGRO_COLOR = al_color_hsv(hue, sat, 1.0);
                a5.al_put_pixel(i, j, color);
            }
        }
        var black: a5.ALLEGRO_COLOR = al_color_name("black");
        a5.al_put_pixel(0, 0, black);
        a5.al_unlock_bitmap(pattern);
        a5.al_restore_state(&state);
        return pattern;
    } else {
        abort_example("Unable to create bitmap");
    }
}

fn set_xy(x: f32, y: f32) void {
    ex.text_x = x;
    ex.text_y = y;
}
fn get_xy(px: *f32, py: *f32) void {
    px.* = ex.text_x;
    py.* = ex.text_y;
}

fn print(comptime format: []const u8, args: anytype) void {
    var buffer: [1024]u8 = undefined;
    const message = std.fmt.bufPrint(buffer[0..], format, args) catch "???";
    const th = @intToFloat(f32, a5.al_get_font_line_height(ex.font));
    a5.al_set_blender(a5.ALLEGRO_ADD, a5.ALLEGRO_ONE, a5.ALLEGRO_INVERSE_ALPHA);
    // not yet! compiler error
    //    a5.al_draw_text(ex.font, ex.text, ex.text_x, ex.text_y, 0, @ptrCast([*c]const u8, message));
    a5.shim_draw_text(ex.font, &ex.text, ex.text_x, ex.text_y, 0, @ptrCast([*c]const u8, message));
    ex.text_y += th;
}

fn pixrow(lock: *a5.ALLEGRO_LOCKED_REGION, row: usize) [*]u8 {
    const pitch = @intCast(isize, lock.*.pitch);
    const data = @ptrCast([*]u8, lock.*.data);
    if (pitch > 0) {
        const upitch = @intCast(usize, pitch);
        return data + row * upitch;
    } else {
        const upitch = @intCast(usize, -pitch);
        return data - row * upitch;
    }
}
fn draw() void {
    const iw = a5.al_get_bitmap_width(ex.pattern);
    const ih = a5.al_get_bitmap_height(ex.pattern);
    a5.al_set_blender(a5.ALLEGRO_ADD, a5.ALLEGRO_ONE, a5.ALLEGRO_ZERO);
    a5.al_clear_to_color(ex.background);
    var screen = a5.al_get_target_bitmap();
    set_xy(8, 8);
    var x: f32 = undefined;
    var y: f32 = undefined;
    var red: a5.ALLEGRO_COLOR = al_color_name("red");
    // Test 2
    {
        print("Screen -> Bitmap -> Screen ({d:.2} fps)", .{ex.timer[1].fps()});
        get_xy(&x, &y);
        a5.al_draw_bitmap(ex.pattern, x, y, 0);
        var temp = a5.al_create_bitmap(iw, ih);
        a5.al_set_target_bitmap(temp);
        a5.al_clear_to_color(red);
        ex.timer[1].start();
        a5.al_draw_bitmap_region(screen, x, y, @intToFloat(f32, iw), @intToFloat(f32, ih), 0, 0, 0);
        a5.al_set_target_bitmap(screen);
        a5.al_draw_bitmap(temp, x + 8.0 + @intToFloat(f32, iw), y, 0);
        ex.timer[1].stop();
        set_xy(x, y + @intToFloat(f32, ih));
        a5.al_destroy_bitmap(temp);
    }
    // Test 3
    {
        print("Screen -> Memory -> Screen ({d:.2} fps)", .{ex.timer[2].fps()});
        get_xy(&x, &y);
        a5.al_draw_bitmap(ex.pattern, x, y, 0);
        a5.al_set_new_bitmap_flags(a5.ALLEGRO_MEMORY_BITMAP);
        var temp = a5.al_create_bitmap(iw, ih);
        a5.al_set_target_bitmap(temp);
        a5.al_clear_to_color(red);
        ex.timer[2].start();
        a5.al_draw_bitmap_region(screen, x, y, @intToFloat(f32, iw), @intToFloat(f32, ih), 0, 0, 0);
        a5.al_set_target_bitmap(screen);
        a5.al_draw_bitmap(temp, x + 8.0 + @intToFloat(f32, iw), y, 0);
        ex.timer[2].stop();
        set_xy(x, y + @intToFloat(f32, ih));
        a5.al_destroy_bitmap(temp);
        a5.al_set_new_bitmap_flags(a5.ALLEGRO_VIDEO_BITMAP);
    }
    // Test 4
    {
        print("Screen -> Locked -> Screen ({d:.2} fps)", .{ex.timer[3].fps()});
        get_xy(&x, &y);
        a5.al_draw_bitmap(ex.pattern, x, y, 0);
        ex.timer[3].start();
        const lock = a5.al_lock_bitmap_region(screen, @floatToInt(c_int, x), @floatToInt(c_int, y), iw, ih, a5.ALLEGRO_PIXEL_FORMAT_ANY, a5.ALLEGRO_LOCK_READONLY);
        const size = @intCast(usize, lock.*.pixel_size);
        const data = std.heap.c_allocator.alloc(u8, size * @intCast(usize, iw * ih)) catch unreachable;
        const w = @intCast(usize, iw);
        var i: usize = 0;
        while (i < ih) : (i += 1) {
            const sdata = pixrow(lock, i);
            std.mem.copy(u8, data[i * size * w .. (i + 1) * size * w], sdata[0 .. size * w]);
        }
        a5.al_unlock_bitmap(screen);
        const wlock = a5.al_lock_bitmap_region(screen, @floatToInt(c_int, x) + 8 + iw, @floatToInt(c_int, y), iw, ih, a5.ALLEGRO_PIXEL_FORMAT_ANY, a5.ALLEGRO_LOCK_WRITEONLY);

        i = 0;
        while (i < ih) : (i += 1) {
            const wdata = pixrow(wlock, i);
            std.mem.copy(u8, wdata[0 .. size * w], data[i * size * w .. (i + 1) * size * w]);
        }
        a5.al_unlock_bitmap(screen);

        std.heap.c_allocator.free(data);
        ex.timer[3].stop();
        set_xy(x, y + @intToFloat(f32, ih));
    }
}

fn tick() void {
    draw();
    a5.al_flip_display();
}
fn init() void {
    ex.FPS = 60;

    ex.font = (a5.al_load_font("data/fixed_font.tga", 0, 0) orelse
        abort_example("data/fixed_font.tga not found\n"));
    ex.background = al_color_name("beige");
    ex.text = al_color_name("black");
    ex.white = al_color_name("white");
    ex.pattern = example_bitmap(100, 100);
}

export fn user_main(argc: c_int, argv: [*c][*c]u8) c_int {
    if (!al_init()) {
        abort_example("Could not init Allegro.\n");
    }

    _ = a5.al_install_keyboard();
    _ = a5.al_install_mouse();
    _ = a5.al_init_image_addon();
    _ = a5.al_init_font_addon();
    init_platform_specific();

    const display = (a5.al_create_display(640, 480) orelse
        abort_example("Error creating display\n"));

    init();

    var timer = a5.al_create_timer(1.0 / @intToFloat(f32, ex.FPS)).?;

    ex.queue = a5.al_create_event_queue().?;
    defer a5.al_destroy_event_queue(ex.queue);
    a5.al_register_event_source(ex.queue, a5.al_get_keyboard_event_source());
    a5.al_register_event_source(ex.queue, a5.al_get_mouse_event_source());
    a5.al_register_event_source(ex.queue, a5.al_get_display_event_source(display));
    a5.al_register_event_source(ex.queue, a5.al_get_timer_event_source(timer));

    a5.al_start_timer(timer);
    run();

    return 0;
}
fn run() void {
    var need_draw = true;

    while (true) {
        if (need_draw and a5.al_is_event_queue_empty(ex.queue)) {
            tick();
            need_draw = false;
        }
        var event: a5.ALLEGRO_EVENT = undefined;

        a5.al_wait_for_event(ex.queue, &event);

        switch (event.type) {
            a5.ALLEGRO_EVENT_DISPLAY_CLOSE => return,

            a5.ALLEGRO_EVENT_KEY_DOWN => if (event.keyboard.keycode == a5.ALLEGRO_KEY_ESCAPE) {
                return;
            },

            a5.ALLEGRO_EVENT_TIMER => need_draw = true,
            else => {},
        }
    }
}

pub fn main() anyerror!void {
    const arg0 = "app";
    const argv = null; //[][]u8{&arg0[0]};
    _ = a5.al_run_main(1, argv, user_main);
}

fn abort_example(msg: []const u8) noreturn {
    std.debug.panic("Example aborted:\n{}\n", .{msg});
}
fn init_platform_specific() void {}
