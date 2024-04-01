const std = @import("std");
const openal = @import("./openal/_.zig");
const sound = @import("../library/sound/_.zig");

pub fn setup(params: struct {
    allocator: std.mem.Allocator,
}) !void {
    const audio = try sound.wav.parse_file("sounds/blinding-lights.wav", params.allocator);
    defer audio.deallocate(params.allocator);

    const audio2 = try sound.wav.parse_file("sounds/completion.wav", params.allocator);
    defer audio2.deallocate(params.allocator);

    var device: *openal.alc.ALCdevice = undefined;
    if (openal.alc.alcOpenDevice(null)) |found_device| {
        device = found_device;
    } else return error.OpenalNoDeviceFound;

    var context: *openal.alc.ALCcontext = undefined;
    if (openal.alc.alcCreateContext(device, null)) |created_context| {
        context = created_context;
    } else return error.OpenalNoContextFound;

    if (openal.alc.alcMakeContextCurrent(context) == openal.alc.AL_FALSE) {
        return error.OpenalContextCurrentError;
    }

    var buffer: openal.alc.ALuint = undefined;
    openal.alc.alGenBuffers(1, @ptrCast(&buffer));
    openal.alc.alBufferData(buffer, openal.alc.AL_FORMAT_STEREO16, @ptrCast(audio.data), @intCast(audio.data_size), @intCast(audio.sample_rate));

    var buffer2: openal.alc.ALuint = undefined;
    openal.alc.alGenBuffers(1, @ptrCast(&buffer2));
    openal.alc.alBufferData(buffer2, openal.alc.AL_FORMAT_STEREO16, @ptrCast(audio2.data), @intCast(audio2.data_size), @intCast(audio2.sample_rate));

    var source: [2]openal.alc.ALuint = undefined;
    openal.alc.alGenSources(2, @ptrCast(&source));
    openal.alc.alSourceQueueBuffers(source[0], 1, @ptrCast(&buffer));
    openal.alc.alSourceQueueBuffers(source[1], 1, @ptrCast(&buffer2));
    openal.alc.alSourcePlay(source[0]);

    var timer = try std.time.Timer.start();
    var playing: bool = true;
    var other_played: bool = false;
    while (playing) {
        var play_state: openal.alc.ALint = undefined;
        openal.alc.alGetSourcei(source[0], openal.alc.AL_SOURCE_STATE, &play_state);
        playing = play_state == openal.alc.AL_PLAYING;

        const elapsed_time = @divFloor(timer.read(), std.time.ns_per_s);
        if (!other_played and elapsed_time == 2) {
            openal.alc.alSourcePlay(source[1]);
            other_played = true;
        }
    }

    openal.alc.alSourceStop(source[0]);
    openal.alc.alSourceStop(source[1]);
    openal.alc.alSourceUnqueueBuffers(source[0], 1, @ptrCast(&buffer));
    openal.alc.alSourceUnqueueBuffers(source[1], 1, @ptrCast(&buffer));

    openal.alc.alDeleteBuffers(1, &buffer);
    openal.alc.alDeleteBuffers(1, &buffer2);
}

pub fn loop() !void {}
pub fn cleanup() void {}
