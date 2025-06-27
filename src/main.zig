// These are the libraries used in the examples,
// you may find the respostories from build.zig.zon
const std = @import("std");
const app = @import("sb7.zig");
const ktx = @import("sb7ktx.zig");
const shader = @import("sb7shader.zig");
const model = @import("sb7object.zig");
const zm = @import("zm");

const shader_code = @import("shaders_triangle.zig");

// Here are All protected properties which is in the original object
// Not the best practice, but it works well for the superbible examples
var clear_program: app.gl.uint = 0;
var append_program: app.gl.uint = 0;
var resolve_program: app.gl.uint = 0;

var fragment_buffer: app.gl.uint = undefined;
var head_pointer_image: app.gl.uint = undefined;
var atomic_counter_buffer: app.gl.uint = undefined;
var dummy_vao: app.gl.uint = undefined;

const Textures = struct {
    color: app.gl.uint,
    normals: app.gl.uint,
};

const UniformsBlock = struct {
    mv_matrix: zm.Mat4f,
    view_matrix: zm.Mat4f,
    proj_matrix: zm.Mat4f,
};

var uniforms_buffer: app.gl.uint = undefined;

var Uniforms = struct {
    mvp: app.gl.uint,
};

pub fn main() !void {
    // Many people seem to hate the dynamic loading part of the program.
    // I also hate it too, but I don't seem to find a good solution (yet)
    // that is aligned with both zig good practice and the book
    // which is unfortunately abstracted all tbe inner details.

    // "override" your program using function pointer,
    // and the run function will process them all
    app.init = init;
    app.start_up = startup;
    app.render = render;
    app.run();
}

fn init() anyerror!void {
    std.mem.copyForwards(u8, &app.info.title, "Fragment List");
}

fn startup() callconv(.c) void {
    const page = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(page);
    defer arena.deinit();

    loadShaders(arena.allocator()) catch {
        std.debug.print("FAILED TO LOAD SHADER\n", .{});
        return;
    };

    app.gl.GenBuffers(1, (&uniforms_buffer)[0..1]);
    app.gl.BindBuffer(app.gl.UNIFORM_BUFFER, uniforms_buffer);
    app.gl.BufferData(app.gl.UNIFORM_BUFFER, @sizeOf(UniformsBlock), null, app.gl.DYNAMIC_DRAW);

    var dragon = model.ModelObject().init(arena.allocator());
    defer dragon.deinit();

    dragon.load("media/objects/dragon.sbm") catch {
        std.debug.print("DRAGON OBJECT LOAD FAILED\n", .{});
        return;
    };

    // TODO: Study why they have used the specific for the buffers and what are the difference between DYNAMIC_DRAW and DYNAMIC_COPY
    app.gl.GenBuffers(1, (&fragment_buffer)[0..1]);
    app.gl.BindBuffer(app.gl.SHADER_STORAGE_BUFFER, fragment_buffer);
    // I have no idea why they have hardcoded 16 MB into the size in their buffer.
    app.gl.BufferData(app.gl.SHADER_STORAGE_BUFFER, 1024 * 1024 * 16, null, app.gl.DYNAMIC_COPY);

    app.gl.GenBuffers(1, (&atomic_counter_buffer)[0..1]);
    app.gl.BindBuffer(app.gl.ATOMIC_COUNTER_BUFFER, atomic_counter_buffer);
    app.gl.BufferData(app.gl.ATOMIC_COUNTER_BUFFER, 4, null, app.gl.DYNAMIC_COPY);

    app.gl.GenTextures(1, (&head_pointer_image)[0..1]);
    app.gl.BindTexture(app.gl.TEXTURE_2D, head_pointer_image);
    app.gl.TexStorage2D(app.gl.TEXTURE_2D, 1, app.gl.R32UI, 1024, 1024);

    app.gl.GenVertexArrays(1, (&dummy_vao)[0..1]);
    app.gl.BindVertexArray(dummy_vao);
}

/// The original superbible example contains three different set of shaders
/// and we need to load them all together
fn loadShaders(arena: std.mem.Allocator) !void {
    var shaders: [2]app.gl.uint = undefined;

    shaders[0] = try shader.load_from_file(arena, "media/shaders/clear.vs.glsl", app.gl.VERTEX_SHADER, true);
    shaders[1] = try shader.load_from_file(arena, "media/shaders/clear.fs.glsl", app.gl.FRAGMENT_SHADER, true);

    if (clear_program != 0) {
        app.gl.DeleteProgram(clear_program);
    }

    clear_program = try shader.linkFromShaders(&shaders, true, true);

    shaders[0] = try shader.load_from_file(arena, "media/shaders/append.vs.glsl", app.gl.VERTEX_SHADER, true);
    shaders[1] = try shader.load_from_file(arena, "media/shaders/append.fs.glsl", app.gl.FRAGMENT_SHADER, true);

    if (append_program != 0) {
        app.gl.DeleteProgram(append_program);
    }

    append_program = try shader.linkFromShaders(&shaders, true, true);

    shaders[0] = try shader.load_from_file(arena, "media/shaders/resolve.vs.glsl", app.gl.VERTEX_SHADER, true);
    shaders[1] = try shader.load_from_file(arena, "media/shaders/resolve.fs.glsl", app.gl.FRAGMENT_SHADER, true);

    if (resolve_program != 0) {
        app.gl.DeleteProgram(resolve_program);
    }

    resolve_program = try shader.linkFromShaders(&shaders, true, true);
}

fn render(_: f64) callconv(.c) void {
    const green: [4]app.gl.float = .{ 0.0, 0.25, 0.0, 1.0 };
    app.gl.ClearBufferfv(app.gl.COLOR, 0, &green);
}
