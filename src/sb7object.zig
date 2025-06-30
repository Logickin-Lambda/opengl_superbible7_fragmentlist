/// Welcome to another abstraction hell!
/// This is the worst offender so far in the framework because it is
/// not an object by the OOP standard, but it is a program for loading a
/// 3D model into OpenGL, and the program spans across sb7object.cpp
/// and its object.h, along with some crazy sb6file headers.
///
/// Since sb7object.cpp and sb6mfile.h is only included once in the
/// whole superbible project, I will put them all into a single file.
/// for the ease of use.
const std = @import("std");
const gl = @import("gl");

/// Here are all the type definition and structs,
/// Starting with packing a four digit char into a big endian number.
/// The reason is that when the data is feed into the struct, it
/// seems to read that in a big endian manner.
fn SB6M_FOURCC(a: gl.uint, b: gl.uint, c: gl.uint, d: gl.uint) gl.uint {
    return a | b << 8 | c << 16 | d << 24;
}

pub const ChunkType = enum(gl.uint) {
    INDEX_DATA = SB6M_FOURCC('I', 'N', 'D', 'X'),
    VERTEX_DATA = SB6M_FOURCC('V', 'R', 'T', 'X'),
    VERTEX_ATTRIBS = SB6M_FOURCC('A', 'T', 'R', 'B'),
    SUB_OBJECT_LIST = SB6M_FOURCC('O', 'L', 'S', 'T'),
    COMMENT = SB6M_FOURCC('C', 'M', 'N', 'T'),
    DATA = SB6M_FOURCC('D', 'A', 'T', 'A'),
};

/// The union will be replaced by a single int,
/// and if the program require to breakdown the int
/// I will use std.mem.toBytes() and
/// std.mem.bytesToValue() instead because
/// these are used for opening files and
/// I don't think they are time critical anyways.
/// Also, to support their original file format,
/// we need to convert all struct into extern struct.
pub const Header = extern struct {
    magic: gl.uint,
    size: gl.uint,
    num_chunks: gl.uint,
    flags: gl.uint,
};

pub const ChunkHeader = extern struct {
    chunk_type: gl.uint,
    size: gl.uint,
};

pub const ChunkIndexData = extern struct {
    header: ChunkHeader,
    index_type: gl.uint,
    index_count: gl.uint,
    index_data_offset: gl.uint,
};

pub const ChunkVertexData = extern struct {
    header: ChunkHeader,
    data_size: gl.uint,
    data_offset: gl.uint,
    total_vertices: gl.uint,
};

pub const VertexAttribDecl = extern struct {
    name: [64]u8,
    size: gl.uint,
    attr_type: gl.uint,
    stride: gl.uint,
    flags: gl.uint,
    data_offset: gl.uint,
};

const VERTEX_ATTRIB_FLAG_NORMALIZED: gl.uint = 0x00000001;
const VERTEX_ATTRIB_FLAG_INTEGER: gl.uint = 0x00000002;

pub const VertexAttribChunk = extern struct {
    header: ChunkHeader,
    attrib_count: gl.uint,
    // It is not even a single item array to begin with
    // because the code iterates this property using in an index,
    // I don't know why they squarely put a single item array to begin with.
    // In this zig version, I use Many-Item Pointer instead.
    attrib_data: [*]VertexAttribDecl,
};

pub const DataEncoding = enum(gl.uint) {
    // Single item enum? Why?
    DATA_ENCODING_RAW = 0,
};

pub const DataChunk = extern struct {
    header: ChunkHeader,
    encoding: gl.uint,
    data_offset: gl.uint,
    data_length: gl.uint,
};

pub const SubObjectDecl = extern struct {
    first: gl.uint,
    count: gl.uint,
};

pub const ChunkSubObjectList = extern struct {
    header: ChunkHeader,
    count: gl.uint,
    sub_object: [*]SubObjectDecl,
};

pub const ChunkComment = extern struct {
    header: ChunkHeader,
    comment: [*]gl.char,
};

// The following object class is a disaster...
// In the orignal C++ code,
// Both the header and cpp contains
// some implementations and now,
// I need to merge both of them...
//
// Since the original C++ code is an object
// I could try to build a function return a struct
// I will call it ModelObject instead of Object
// because it seemingly a class for fetching a 3D model
// such that to remove the confusion of objects in OOP.

/// Just Why??? Why did the original C++ implementation
/// did a single item enum for this Constant, on
/// the member level???
const MAX_SUB_OBJECTS = 256;

pub fn ModelObject() type {
    return struct {
        const Self = @This();

        // These were the private properties
        data_buffer: gl.uint,
        vao: gl.uint,
        index_type: gl.uint,
        index_offset: gl.uint = undefined,
        num_sub_objects: gl.uint = undefined,
        sub_object: [MAX_SUB_OBJECTS]SubObjectDecl = undefined,

        // Of course, some part of the process needs dynamic
        // heap allocation, especially reading a file, thus an allocator
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            const model_object = Self{
                .allocator = allocator,
                .data_buffer = 0,
                .index_type = 0,
                .vao = 0,
            };

            return model_object;
        }

        pub fn deinit(_: Self) void {}

        pub fn render(self: Self, instance_count_in: ?gl.uint, base_instance_in: ?gl.uint) void {
            self.renderSubObject(0, instance_count_in, base_instance_in);
        }

        pub fn renderSubObject(self: Self, object_index: gl.uint, instance_count_in: ?gl.uint, base_instance_in: ?gl.uint) void {
            const instance_count = instance_count_in orelse 1;
            const base_instance = base_instance_in orelse 0;

            gl.BindVertexArray(self.vao);

            if (self.index_type != gl.NONE) {
                gl.DrawElementsInstancedBaseInstance(
                    gl.TRIANGLES,
                    @intCast(self.sub_object[object_index].count),
                    self.index_type,
                    @ptrCast(&self.sub_object[object_index].first),
                    @intCast(instance_count),
                    base_instance,
                );
            } else {
                gl.DrawArraysInstancedBaseInstance(
                    gl.TRIANGLES,
                    @intCast(self.sub_object[object_index].first),
                    @intCast(self.sub_object[object_index].count),
                    @intCast(instance_count),
                    base_instance,
                );
            }
        }

        pub fn get_sub_object_info(self: Self, index: gl.uint, first: *gl.uint, count: *gl.uint) void {
            if (index >= MAX_SUB_OBJECTS) {
                // In the original C++ implementation,
                // set the reference to... 0?
                // I believe it should be overwriting the
                // value given by the reference instead of
                // changing it.
                first.* = 0;
                count.* = 0;
            } else {
                first.* = self.sub_object[index].first;
                count.* = self.sub_object[index].count;
            }
        }

        /// Here we go, we now need to fight against the Demon "Icon of Sin",
        /// The final boss of this framework (hopefully)
        ///
        /// Errors shows on VScode;
        /// Where no comments shown and where hell's six feet deep;
        /// That crash does wait, there's no debate;
        /// So rewrite the mess, going to hell and back!
        ///
        pub fn load(self: *Self, filename: []const u8) !void {

            // we have to try to open the file before erase the vao and vbo.
            var file = try std.fs.cwd().openFile(filename, .{});
            defer file.close();

            var bf = std.io.bufferedReader(file.reader());
            const fp = bf.reader();

            // Another rant to the original C++ code:
            // The free memory process had only processed once throughout the whole class.
            // Why specifically refactor this four line code while leaving all other
            // messier spaghetti in place?!
            gl.DeleteVertexArrays(1, (&self.vao)[0..1]);
            gl.DeleteBuffers(1, (&self.data_buffer)[0..1]);
            self.vao = 0;
            self.data_buffer = 0;

            // From here, the original C++ code just slap the data into the header struct,
            // and hoping for the best to map the correct field of the structs...
            // I don't know if zig can do this, nor I want to do this because
            // this looks concerning security wise and it is really hard to understand.
            // Thus, I will reverse engineering the file to see how to read it such that
            // it can read in a correct order using the reader operations.

            // Firstly, we need to read the first few bytes of data into a header:
            // The format of the header is the following:
            // magic        : 4 slot char array, aka an uint
            // size         : uint, represent the size of this header
            // num_chunks   : uint
            // flags        : uint
            //
            // Suggested by the byte 4 of the file, corresponding to the size field,
            // seems like all the size, or any integer based field in the header are
            // little endian.

            // Unfortunately, we need to do the same with zig because the OpenGL functions
            // want us to pass the pointer of the chunk; although the features in file io are
            // great and it is really handy for most of the task, it doesn't seems to work with
            // the file format I am working with where it is heavily relies on raw pointer
            // access. Thus, we have to bite the bullet and...
            // Allocate the whole file into heap such that we can refer the file using pointers.

            var arena_file = std.heap.ArenaAllocator.init(self.allocator);
            defer arena_file.deinit();
            const file_data = try fp.readAllAlloc(arena_file.allocator(), try file.getEndPos());
            var file_data_ptr = file_data.ptr;

            // We need to gaslit the file_data to be a pointer to the Header struct.
            // thus, alignCast and ptrCast to the rescue.
            const header_ptr: *Header = @ptrCast(@alignCast(file_data_ptr));
            file_data_ptr += header_ptr.size; // Jumps to the next Header chunks

            // Seems the casting handles the endianness as well, so we get 16 instead of 268,435,456
            // std.debug.print("\nHeader Result\n", .{});
            // std.debug.print("Magic: {X}\n", .{header_ptr.magic}); // prints 4D364253 (M6bS)
            // std.debug.print("Size: {X}\n", .{header_ptr.size}); // prints 16
            // std.debug.print("Num Chunks: {X}\n", .{header_ptr.num_chunks}); // prints 2
            // std.debug.print("Flags: {X}\n", .{header_ptr.flags}); // prints 0

            // Here is the confusing bit Because we need to iterate file by the chunk size given
            // by the header, and precisely assign the pointer of each starting point of the chunks.
            // Since all headers are merged into a single file, we need some form of identifier to
            // tell the type of chunk, and this is where the Clamped four characters uint shines
            // because we can turn that into an integer based pattern matching as shown:
            var vertex_attrib_chunk: ?*VertexAttribChunk = null;
            var vertex_data_chunk: ?*ChunkVertexData = null;
            var index_data_chunk: ?*ChunkIndexData = null;
            var sub_object_chunk: ?*ChunkSubObjectList = null;
            var data_chunk: ?*DataChunk = null;

            for (0..header_ptr.*.num_chunks) |_| {
                // More Gaslighting to the file_data to different form of header and chunks.
                const chunk: *ChunkHeader = @ptrCast(@alignCast(file_data_ptr));

                // Seems it is possible to solve it using union, but let's follow the original C++ way
                switch (@as(ChunkType, @enumFromInt(chunk.chunk_type))) {
                    ChunkType.VERTEX_ATTRIBS => {
                        vertex_attrib_chunk = @ptrCast(@alignCast(chunk));
                        // Since the chunk only cast the header, but not the data,
                        // we need to explicitly cast the inner data as shown,
                        // and finding the start of that Many Item Pointer by adding an offset
                        // of the size of ChunkHeader and gl.uint which is the attrib_count
                        // I can't think of a better way of doing this yet, but this nonetheless
                        // works for now because the attrib_data now has the correct type of pointer
                        // pointing to the correct location.
                        const inner_chunk = file_data_ptr + @sizeOf(ChunkHeader) + @sizeOf(gl.uint);
                        vertex_attrib_chunk.?.attrib_data = @as([*]VertexAttribDecl, @ptrCast(@alignCast(inner_chunk)));
                    },
                    ChunkType.VERTEX_DATA => {
                        vertex_data_chunk = @ptrCast(@alignCast(chunk));
                    },
                    ChunkType.INDEX_DATA => {
                        index_data_chunk = @ptrCast(@alignCast(chunk));
                    },
                    ChunkType.SUB_OBJECT_LIST => {
                        // This will also cause the same seg fault issue as the vertex_attrib_chunk,
                        // unless I have a better solution and the future example needs it, I am not
                        // going to touch this part. TODO: update this cast if better solution is found
                        sub_object_chunk = @ptrCast(@alignCast(chunk));
                    },
                    ChunkType.DATA => {
                        data_chunk = @ptrCast(@alignCast(chunk));
                    },
                    else => {},
                }
                file_data_ptr += chunk.size;
            }

            // Finally, with all those data, we can finally work on something familiar,
            // to declare a new array and buffer for our incoming objects
            gl.GenVertexArrays(1, (&self.vao)[0..1]);
            gl.BindVertexArray(self.vao);

            if (data_chunk) |parsed_data| {
                gl.GenBuffers(1, (&self.data_buffer)[0..1]);
                gl.BindBuffer(gl.ARRAY_BUFFER, self.data_buffer);
                gl.BufferData(
                    gl.ARRAY_BUFFER,
                    parsed_data.data_length,
                    @as([*]u8, @ptrCast(@alignCast(parsed_data))) + parsed_data.data_offset,
                    gl.STATIC_DRAW,
                );
            } else {
                var data_size: gl.uint = 0;
                var size_used: gl.uint = 0;

                if (vertex_data_chunk) |parsed_data| {
                    data_size += parsed_data.data_size;
                }

                if (index_data_chunk) |parsed_data| {
                    const index_size: gl.uint = if (parsed_data.index_type == gl.UNSIGNED_SHORT) @sizeOf(gl.ushort) else @sizeOf(gl.ubyte);
                    data_size += parsed_data.index_count * index_size;
                }

                gl.GenBuffers(1, (&self.data_buffer)[0..1]);
                gl.BindBuffer(gl.ARRAY_BUFFER, self.data_buffer);
                gl.BufferData(gl.ARRAY_BUFFER, data_size, null, gl.STATIC_DRAW);

                if (vertex_data_chunk) |parsed_data| {
                    gl.BufferSubData(
                        gl.ARRAY_BUFFER,
                        0,
                        parsed_data.data_size,
                        file_data_ptr + parsed_data.data_offset,
                    );
                    size_used += parsed_data.data_offset;
                }

                if (index_data_chunk) |parsed_data| {
                    const index_size: gl.uint = if (parsed_data.index_type == gl.UNSIGNED_SHORT) @sizeOf(gl.ushort) else @sizeOf(gl.ubyte);
                    gl.BufferSubData(
                        gl.ARRAY_BUFFER,
                        0,
                        parsed_data.index_count * index_size,
                        file_data_ptr + parsed_data.index_data_offset,
                    );
                }
            }

            // Seems like the original program has stated that the vertex_attrib_chunk is not optional
            // because there is no null check in this part, but to prevent the program crashes with
            // a null pointer, I will perform a null check before processing the loop.
            if (vertex_attrib_chunk) |vertex_attrib| {
                for (0..vertex_attrib.attrib_count) |i| {
                    const attrib_decl = vertex_attrib.attrib_data[i];
                    const flag_normalized: gl.boolean = if (attrib_decl.flags & VERTEX_ATTRIB_FLAG_NORMALIZED != 0) gl.TRUE else gl.FALSE;
                    gl.VertexAttribPointer(
                        @intCast(i),
                        @intCast(attrib_decl.size),
                        attrib_decl.attr_type,
                        flag_normalized,
                        @intCast(attrib_decl.stride),
                        attrib_decl.data_offset,
                    );
                }
            }

            if (index_data_chunk) |index_data| {
                gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.data_buffer);
                self.index_type = index_data.index_type;
                self.index_offset = index_data.index_data_offset;
            } else {
                self.index_type = gl.NONE;
            }

            if (sub_object_chunk) |sub_object| {
                if (sub_object.count > MAX_SUB_OBJECTS) {
                    sub_object.count = MAX_SUB_OBJECTS;
                }

                for (0..sub_object.count) |i| {
                    self.sub_object[i] = sub_object.sub_object[i];
                }

                self.num_sub_objects = sub_object.count;
            } else {
                const index = if (self.index_type != gl.NONE) index_data_chunk.?.index_count else vertex_data_chunk.?.total_vertices;

                self.sub_object[0].first = 0;
                self.sub_object[0].count = index;
            }

            // Not sure why they bind the array and buffer in here again
            gl.BindVertexArray(0);
            gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
        }
    };
}
