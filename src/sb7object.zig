/// Welcome to another abstraction hell!
/// This is worst offender so far in the framework because it is
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
fn SB6M_FOURCC(a: gl.uint, b: gl.uint, c: gl.uint, d: gl.uint) gl.uint {
    return a | b << 8 | c << 16 | d << 24;
}

pub const ChunkType = enum(gl.uint) {
    SB6M_CHUNK_TYPE_INDEX_DATA = SB6M_FOURCC('I', 'N', 'D', 'X'),
    SB6M_CHUNK_TYPE_VERTEX_DATA = SB6M_FOURCC('V', 'R', 'T', 'X'),
    SB6M_CHUNK_TYPE_VERTEX_ATTRIBS = SB6M_FOURCC('A', 'T', 'R', 'B'),
    SB6M_CHUNK_TYPE_SUB_OBJECT_LIST = SB6M_FOURCC('O', 'L', 'S', 'T'),
    SB6M_CHUNK_TYPE_COMMENT = SB6M_FOURCC('C', 'M', 'N', 'T'),
    SB6M_CHUNK_TYPE_DATA = SB6M_FOURCC('D', 'A', 'T', 'A'),
};

/// The union will be replaced by a single int,
/// and if the program require to breakdown the int
/// I will use std.mem.toBytes() and
/// std.mem.bytesToValue() instead because
/// these are used for opening files and
/// I don't think they are time critical anyways.
pub const Header = struct {
    magic: gl.uint,
    size: gl.uint,
    num_chunks: gl.uint,
    flags: gl.uint,
};

pub const ChunkHeader = struct {
    chunk_type: gl.uint,
    size: gl.uint,
};

pub const ChunkIndexData = struct {
    header: ChunkHeader,
    index_type: gl.uint,
    index_count: gl.uint,
    index_data_offset: gl.uint,
};

pub const ChunkVertexData = struct {
    header: ChunkHeader,
    data_size: gl.uint,
    data_offset: gl.uint,
    total_vertices: gl.uint,
};

pub const VertexAttribDecl = struct {
    name: [64]u8,
    size: gl.uint,
    attr_type: gl.uint,
    stride: gl.uint,
    flags: gl.uint,
    data_offset: gl.uint,
};

const VERTEX_ATTRIB_FLAG_NORMALIZED = 0x00000001;
const VERTEX_ATTRIB_FLAG_INTEGER = 0x00000002;

pub const VertexAttribChunk = struct {
    header: ChunkHeader,
    attrib_count: gl.uint,
    attrib_data: [1]VertexAttribDecl, // Single Sized Array, but it has a count?
};

pub const DataEncoding = enum(gl.uint) {
    // Single item enum? Why?
    DATA_ENCODING_RAW = 0,
};

pub const DataChunk = struct {
    header: ChunkHeader,
    encoding: gl.uint,
    data_offset: gl.uint,
    data_length: gl.uint,
};

pub const SubObjectDecl = struct {
    first: gl.uint,
    count: gl.uint,
};

pub const ChunkSubObjectList = struct {
    header: ChunkHeader,
    count: gl.uint,
    sub_object: [1]SubObjectDecl,
};

pub const ChunkComment = struct {
    header: ChunkHeader,
    comment: [1]gl.char,
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
        index_offset: gl.uint,
        num_sub_objects: gl.uint,
        sub_object: [MAX_SUB_OBJECTS]SubObjectDecl,

        // Of course, some part of the process needs dynamic
        // heap allocation, especially reading a file, thus an allocator
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .data_buffer = 0,
                .index_type = 0,
                .vao = 0,
            };
        }

        pub fn deinit() void {}

        pub fn render(_: Self, instance_count_in: ?gl.uint, base_instance_in: ?gl.uint) void {
            renderSubObject(0, instance_count_in, base_instance_in);
        }

        pub fn renderSubObject(self: Self, object_index: gl.uint, instance_count_in: ?gl.uint, base_instance_in: ?gl.uint) void {
            const instance_count = instance_count_in orelse 1;
            const base_instance = base_instance_in orelse 0;

            gl.BindVertexArray(self.vao);

            if (self.index_type != gl.NONE) {
                gl.DrawElementsInstancedBaseInstance(
                    gl.TRIANGLES,
                    self.sub_object[object_index].count,
                    self.index_type,
                    @ptrCast(&self.sub_object[object_index].first),
                    instance_count,
                    base_instance,
                );
            } else {
                gl.DrawArraysInstancedBaseInstance(
                    gl.TRIANGLES,
                    self.sub_object[object_index].first,
                    self.sub_object[object_index].count,
                    instance_count,
                    base_instance,
                );
            }
        }
    };
}
