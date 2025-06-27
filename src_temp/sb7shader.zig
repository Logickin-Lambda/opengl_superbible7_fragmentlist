/// Again, we have to gone through the abstraction hell again.
/// This time, we need to sort out their sb7Shader.cpp
/// with reverse engineering.
/// As usual, I will try to add some comment to explain what
/// the code does based on my understanding.
const std = @import("std");
const gl = @import("gl");

/// Based on my understanding, the is similar to our shader loading code
/// in the previous examples, but they have been extracted into a function,
/// with optional error checking.
pub fn load_from_file(allocator: std.mem.Allocator, filepath: []const u8, shader_type: gl.@"enum", check_errors: bool) !gl.uint {
    var file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    // just like java, we need a buffer reader to generate a reader
    // that can be used for iteration
    // var bf = std.io.bufferedReader(file.reader());
    // const fp = bf.reader();

    // Their original fseek function were used for getting the pointer
    // of the start and end of the file, and allocating a buffer with
    // the size of the file size; however, the shader code has an unknown
    // size such that we should allocate the memory into the heap instead.
    // Thus, I have used an allocator for such situation.
    // In addition, the original goto is dreading because it is really
    // hard to see how the problem ending up, and since zig has try catch,
    // these are the good replacement to handle errors.

    // Thus, thanks to the feature of zig, whole read process can
    // be reduced down into three lines:
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit(); // clear the data

    // we just need to read all the content, and not specific bytes, thus no Buffered Reader
    const data = try file.readToEndAlloc(arena.allocator(), try file.getEndPos());

    // Creating a shader, just like how you have done in the previous examples:
    const shader = gl.CreateShader(shader_type);
    gl.ShaderSource(shader, 1, &.{data.ptr}, &.{@as(c_int, @intCast(data.len))});
    gl.CompileShader(shader);

    if (check_errors) {
        // errdefer in the rescue, no more goto madness like the original C++ code
        errdefer gl.DeleteShader(shader);
        try verifyShader(shader);
    }

    return shader;
}

// the is the og shader loading code used in the earlier examples
pub fn load_from_slice(source: []const u8, shader_type: gl.@"enum", check_errors: bool) !gl.uint {
    const shader = gl.CreateShader(shader_type);
    gl.ShaderSource(shader, 1, &.{source.ptr}, &.{@as(c_int, @intCast(source.len))});
    gl.CompileShader(shader);

    if (check_errors) {
        errdefer gl.DeleteShader(shader);
        try verifyShader(shader);
    }
    return shader;
}

/// This basically same as the process of creating and linking gl programs
/// like you have done before, but the original OpenGL superbible decided
/// to encapsulate the process; thus, I have done the same such that to
/// aligns to the orignal C++ implementation which you may make a direct
/// comparison between languages.
///
/// Nevertheless, thanks to the slices in zig, we don't need to specify
/// length of the given array which slices has length provided, so
/// I have removed the original shader_count input parameter.
pub fn linkFromShaders(shaders: []const gl.uint, delete_shaders: bool, check_errors: bool) !gl.uint {
    const program = gl.CreateProgram();

    for (shaders) |shader| {
        gl.AttachShader(program, shader);
    }

    gl.LinkProgram(program);

    if (check_errors) {
        errdefer gl.DeleteProgram(program);
        try verifyProgram(program);
    }

    // According to https://stackoverflow.com/a/18736860/20840262,
    // The deleted a linked shader don't actually delete the shader,
    // but marked as to be deleted after the shader is no longer linked.
    if (delete_shaders) {
        for (shaders) |shader| {
            gl.DeleteShader(shader);
        }
    }

    return program;
}

/// I have decided to reuse my own version instead of the original superbible version
/// so that I don't need to handle the file IOs like the original C++ version,
/// while it is still compatible to my original version.
/// Running the executables display the error message anyways.
///
/// Unfortunately, this part will be duplicated, but I have no choice if I need to
/// make this compatible with the earlier examples since this file is optional.
fn verifyShader(shader: c_uint) !void {
    var success: gl.int = gl.TRUE;
    var info_log: [1024:0]u8 = undefined;

    gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success);

    if (success == gl.FALSE) {
        gl.GetShaderInfoLog(
            shader,
            @as(c_int, @intCast(info_log.len)),
            null,
            &info_log,
        );
        std.log.err("{s}", .{std.mem.sliceTo(&info_log, 0)});
        return error.CompileShaderFailed;
    }
}

fn verifyProgram(shaderProgram: c_uint) !void {
    var success: gl.int = gl.TRUE;
    var info_log: [1024:0]u8 = undefined;
    gl.GetProgramiv(shaderProgram, gl.LINK_STATUS, &success);

    if (success == gl.FALSE) {
        gl.GetProgramInfoLog(
            shaderProgram,
            @as(c_int, @intCast(info_log.len)),
            null,
            &info_log,
        );
        std.log.err("{s}", .{&info_log});
        return error.LinkProgramFailed;
    }
}
