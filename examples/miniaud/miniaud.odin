#+vet
// https://gist.github.com/p1xelHer0/abed4728096ea3a88af7802cbe46cf08
// https://miniaud.io/docs/
package main

import "core:fmt"
import "core:time"
import ma "vendor:miniaudio"

//AUDIO_FORMAT :: ma.encoding_format.wav
AUDIO_FORMAT :: ma.encoding_format.flac
//AUDIO_FORMAT :: ma.encoding_format.mp3
//AUDIO_FORMAT :: ma.encoding_format.vorbis

// 0 - Use native channel count of the device
AUDIO_CHANNELS :: 0
AUDIO_SAMPLE_RATE :: 0

when AUDIO_FORMAT == .flac {
	AUDIO_FILE :: #load("../../data/audio/lossless-flac-44khz-16bit-stereo.flac")
} else when AUDIO_FORMAT == .mp3 {
	AUDIO_FILE :: #load("../../data/audio/lossy-mp3-44khz-16bit-stereo-64kbps.mp3")
} else when AUDIO_FORMAT == .vorbis {
	AUDIO_FILE :: #load("../../data/audio/lossy-ogg-44khz-16bit-stereo-64kbps.ogg")
} else {
	AUDIO_FILE :: #load("../../data/audio/lossless-wave-44khz-16bit-stereo.wav")
}

engine: ma.engine
// NOTE: Keep your decoder alive for the life of your sound object
decoder: ma.decoder
sound: ma.sound

main :: proc() {
	engine_config := ma.engine_config_init()
	engine_config.channels = AUDIO_CHANNELS
	engine_config.sampleRate = AUDIO_SAMPLE_RATE
	engine_config.listenerCount = 1

	engine_init_result := ma.engine_init(&engine_config, &engine)
	if engine_init_result != .SUCCESS {fmt.panicf("failed to init miniaudio engine: %v", engine_init_result)}

	engine_start_result := ma.engine_start(&engine)
	if engine_start_result != .SUCCESS {fmt.panicf("failed to start miniaudio engine: %v", engine_start_result)}

	decoder_config := ma.decoder_config_init(outputFormat = .f32, outputChannels = AUDIO_CHANNELS, outputSampleRate = AUDIO_SAMPLE_RATE)
	// When loading a decoder, miniaudio uses a trial and error technique to find the appropriate decoding backend.
	// This can be unnecessarily inefficient if the type is already known. In this case you can use encodingFormat
	// variable in the device config to specify a specific encoding format you want to decode:
	decoder_config.encodingFormat = AUDIO_FORMAT

	decoder_result := ma.decoder_init_memory(pData = raw_data(AUDIO_FILE), dataSize = len(AUDIO_FILE), pConfig = &decoder_config, pDecoder = &decoder)
	if decoder_result != .SUCCESS {fmt.panicf("failed to init decoder: %v", decoder_result)}
	sound_result := ma.sound_init_from_data_source(pEngine = &engine, pDataSource = decoder.ds.pCurrent, flags = 0, pGroup = nil, pSound = &sound)
	if sound_result != .SUCCESS {fmt.panicf("failed to init sound file from memory: %v", sound_result)}

	fmt.println("Playing", decoder_config.encodingFormat)
	ma.sound_start(&sound)
	time.sleep(time.Millisecond * 1500)
	fmt.println("Done.")
}
