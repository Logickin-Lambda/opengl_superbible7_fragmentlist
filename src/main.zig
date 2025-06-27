// These are the libraries used in the examples,
// you may find the respostories from build.zig.zon
const std = @import("std");
const app = @import("sb7.zig");
const ktx = @import("sb7ktx.zig");
const shader = @import("sb7shader.zig");
const model = @import("sb7object.zig");
const shader_code = @import("shaders_triangle.zig");

var program: app.gl.uint = undefined;
var vao: app.gl.uint = undefined;

pub fn main() !void {
    // Many people seem to hate the dynamic loading part of the program.
    // I also hate it too, but I don't seem to find a good solution (yet)
    // that is aligned with both zig good practice and the book
    // which is unfortunately abstracted all tbe inner details.

    // "override" your program using function pointer,
    // and the run function will process them all
    app.start_up = startup;
    app.render = render;
    app.shutdown = shutdown;
    app.run();
}

fn startup() callconv(.c) void {
    const page = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(page);
    defer arena.deinit();

    const vs = shader.load_from_file(arena.allocator(), "src/shader_vertex.glsl", app.gl.VERTEX_SHADER, true) catch {
        return;
    };

    const fs = shader.load_from_file(arena.allocator(), "src/shader_fragment.glsl", app.gl.FRAGMENT_SHADER, true) catch {
        return;
    };

    const shaders = [2]c_uint{ vs, fs };
    program = shader.linkFromShaders(&shaders, true, true) catch {
        std.debug.print("FAILED TO LINK PROGRAM", .{});
        return;
    };

    // Now put all the shaders into the program
    // program = app.gl.CreateProgram();
    // app.gl.AttachShader(program, vs);
    // app.gl.AttachShader(program, fs);

    // app.gl.LinkProgram(program);

    app.gl.GenVertexArrays(1, (&vao)[0..1]);
    app.gl.BindVertexArray(vao);

    var model_instance = model.ModelObject().init(arena.allocator());
    _ = model_instance.load("src/dragon.sbm") catch {
        // std.debug.print("ERROR ON LOADING MODEL", .{});
        return;
    };
}

fn render(_: f64) callconv(.c) void {
    const green: [4]app.gl.float = .{ 0.0, 0.25, 0.0, 1.0 };
    app.gl.ClearBufferfv(app.gl.COLOR, 0, &green);

    app.gl.UseProgram(program);
    app.gl.DrawArrays(app.gl.TRIANGLES, 0, 3);
}

fn shutdown() callconv(.c) void {
    app.gl.BindVertexArray(0);
    app.gl.DeleteVertexArrays(1, (&vao)[0..1]);
    app.gl.DeleteProgram(program);
}
