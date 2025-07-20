const MessageType = enum {
    Join,
    Leave,
    Chat,
};

const Message = struct {
    msg_type: MessageType,
    username: [32]u8,
    content: [256]u8,
};
