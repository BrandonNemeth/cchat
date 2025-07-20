const std = @import("std");

pub const MessageType = enum(u8) {
    Join = 1,
    Chat = 2,
    Leave = 3,
};

pub const Message = struct {
    kind: MessageType,
    username: [32]u8,
    content: [256]u8,

    pub fn init(kind: MessageType, username: []const u8, content: []const u8) Message {
        var msg = Message{
            .kind = kind,
            .username = [_]u8{0} ** 32,
            .content = [_]u8{0} ** 256,
        };
        std.mem.copyForwards(u8, msg.username[0..@min(username.len, 32)], username);
        std.mem.copyForwards(u8, msg.content[0..@min(content.len, 256)], content);
        return msg;
    }

    pub fn serialize(self: *const Message, out: []u8) void {
        std.mem.writeInt(u8, out[0..1], @intFromEnum(self.kind), .little);
        std.mem.copyForwards(u8, out[1..33], &self.username);
        std.mem.copyForwards(u8, out[33..289], &self.content);
    }

    pub fn deserialize(input: []const u8) Message {
        const kind = @as(MessageType, @enumFromInt(input[0]));
        var username: [32]u8 = undefined;
        var content: [256]u8 = undefined;
        std.mem.copyForwards(u8, &username, input[1..33]);
        std.mem.copyForwards(u8, &content, input[33..289]);
        return Message{
            .kind = kind,
            .username = username,
            .content = content,
        };
    }
};
