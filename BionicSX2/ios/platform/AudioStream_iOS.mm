// PORTED FROM: Host/AudioStream.cpp, Host/CubebAudioStream.cpp — BionicSX2 iOS Port
// AUDIT REFERENCE: Section 9.2 (CoreAudio/AudioUnit portability),
//                  Section 9.3 (latency and buffer size considerations)
// STATUS: NEW — iOS-native AVAudioEngine audio backend

#import <AVFoundation/AVFoundation.h>
#include "Host/AudioStream.h"
#include "common/Console.h"
#include <mutex>
#include <vector>
#include <memory>

// Audit Section 9.2: cubeb has native iOS AudioUnit backend
// Section 9.3: 48kHz sample rate, 256-512 frame buffer, 5-10ms latency

class iOSAudioStream final : public AudioStream
{
public:
    iOSAudioStream(u32 sample_rate, const AudioStreamParameters& parameters, bool stretch_enabled);
    ~iOSAudioStream() override;

    bool Start(Error* error);
    void Stop();
    void EmptyBuffers();
    void SetPaused(bool paused) override;
    bool SetOutputVolume(float volume);
    FramesToPlayCallback m_frames_to_play_callback = nullptr;
    void* m_frames_to_play_callback_user_data = nullptr;

    static constexpr u32 CHUNK_SIZE = 64;       // Audit Sec 9.3
    static constexpr u32 BUFFER_SIZE = 2048;    // Safe mobile latency per audit

private:
    AVAudioEngine* m_engine;
    AVAudioPlayerNode* m_player;
    AVAudioFormat* m_format;
    std::vector<float> m_buffer;
    bool m_started = false;
    bool m_paused = false;
    float m_volume = 1.0f;
};

iOSAudioStream::iOSAudioStream(u32 sample_rate, const AudioStreamParameters& parameters, bool stretch_enabled)
    : AudioStream()
{
    // Audit Section 9.3: PlayStation 2 native = 48000 Hz
    NSError* error = nil;
    AVAudioSession* session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error) {
        NSLog(@"[BionicSX2] AVAudioSession setCategory failed: %@", error);
    }

    // Audit Section 9.3: Set preferred buffer duration to 5ms for low latency
    [session setPreferredIOBufferDuration:0.005 error:&error];
    if (error) {
        NSLog(@"[BionicSX2] AVAudioSession setPreferredIOBufferDuration failed: %@", error);
    }

    [session setActive:YES error:&error];
    if (error) {
        NSLog(@"[BionicSX2] AVAudioSession setActive failed: %@", error);
    }

    m_engine = [[AVAudioEngine alloc] init];
    m_player = [[AVAudioPlayerNode alloc] init];

    // Audit Section 9.3: 48000 Hz stereo PCM
    m_format = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                 sampleRate:sample_rate
                                                   channels:2
                                                interleaved:NO];

    [m_engine attachNode:m_player];
    [m_engine connect:m_player to:m_engine.mainMixerNode format:m_format];

    m_buffer.resize(BUFFER_SIZE * 2); // Stereo
}

iOSAudioStream::~iOSAudioStream()
{
    Stop();
    [m_player detach];
    [m_engine detachNode:m_player];
}

bool iOSAudioStream::Start(Error* error)
{
    if (m_started) return true;

    NSError* nsError = nil;
    [m_engine startAndReturnError:&nsError];
    if (nsError) {
        NSLog(@"[BionicSX2] AVAudioEngine start failed: %@", nsError);
        return false;
    }

    [m_player play];
    m_started = true;
    NSLog(@"[BionicSX2] AudioStream started at %0.0f Hz", m_format.sampleRate);
    return true;
}

void iOSAudioStream::Stop()
{
    if (!m_started) return;
    [m_player stop];
    [m_engine stop];
    m_started = false;
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

void iOSAudioStream::EmptyBuffers()
{
    // Flush pending audio
    [m_player stop];
    [m_player play];
}

void iOSAudioStream::SetPaused(bool paused)
{
    m_paused = paused;
    if (paused)
        [m_player pause];
    else
        [m_player play];
}

bool iOSAudioStream::SetOutputVolume(float volume)
{
    m_volume = std::max(0.0f, std::min(1.0f, volume));
    m_player.volume = m_volume;
    return true;
}

// Factory function — creates iOS-native audio stream
std::unique_ptr<AudioStream> AudioStream::CreateAudioStream(
    u32 sample_rate, const AudioStreamParameters& parameters,
    bool stretch_enabled, Error* error)
{
    auto stream = std::make_unique<iOSAudioStream>(sample_rate, parameters, stretch_enabled);
    if (!stream->Start(error))
        return nullptr;
    return stream;
}
