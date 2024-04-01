const std = @import("std");
const openal = @import("./openal/_.zig");
const sound = @import("../library/sound/_.zig");

pub fn setup(params: struct {
    allocator: std.mem.Allocator,
}) !void {
    const audio = try sound.wav.parse_file("sounds/blinding-lights.wav", params.allocator);
    defer audio.deallocate(params.allocator);

    var al_error: c_int = undefined;

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
    openal.alc.alGenBuffers(1, &buffer);
    openal.alc.alBufferData(buffer, openal.alc.AL_FORMAT_STEREO16, @ptrCast(audio.data), @intCast(audio.data_size), @intCast(audio.sample_rate));

    var source: openal.alc.ALuint = undefined;
    openal.alc.alGenSources(1, &source);
    openal.alc.alSourceQueueBuffers(source, 1, &buffer);
    openal.alc.alSourcePlay(source);

    var playing: bool = true;
    while (playing) {
        var play_state: openal.alc.ALint = undefined;
        openal.alc.alGetSourcei(source, openal.alc.AL_SOURCE_STATE, &play_state);
        playing = play_state == openal.alc.AL_PLAYING;
    }

    openal.alc.alSourceStop(source);
    openal.alc.alSourceUnqueueBuffers(source, 1, &buffer);

    openal.alc.alDeleteBuffers(1, &buffer);
    al_error = openal.alc.alGetError();
}

pub fn loop() !void {}
pub fn cleanup() void {}
