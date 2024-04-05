/* ========================================================================================== */
/* FMOD Ex - C++ header file. Copyright (c), Firelight Technologies Pty, Ltd. 2004-2014.      */
/*                                                                                            */
/* Use this header in conjunction with fmod.h (which contains all the constants / callbacks)  */
/* to develop using C++ classes.                                                              */
/* ========================================================================================== */

#ifndef _FMOD_HPP
#define _FMOD_HPP

#include "fmod.h"

/*
    Constant and defines
*/

/*
    FMOD Namespace
*/
namespace FMOD
{
    class System;
    class Sound;
    class Channel;
    class ChannelGroup;
    class SoundGroup;
    class Reverb;
    class DSP;
    class DSPConnection;
    class Geometry;

    /*
        FMOD global system functions (optional).
    */
    inline FMOD_RESULT Memory_Initialize(void *poolmem, int poollen, FMOD_MEMORY_ALLOCCALLBACK useralloc, FMOD_MEMORY_REALLOCCALLBACK userrealloc, FMOD_MEMORY_FREECALLBACK userfree, FMOD_MEMORY_TYPE memtypeflags = FMOD_MEMORY_ALL) { return FMOD_Memory_Initialize(poolmem, poollen, useralloc, userrealloc, userfree, memtypeflags); }
    inline FMOD_RESULT Memory_GetStats  (int *currentalloced, int *maxalloced, bool blocking = true) { return FMOD_Memory_GetStats(currentalloced, maxalloced, blocking); }
    inline FMOD_RESULT Debug_SetLevel(FMOD_DEBUGLEVEL level)  { return FMOD_Debug_SetLevel(level); }
    inline FMOD_RESULT Debug_GetLevel(FMOD_DEBUGLEVEL *level) { return FMOD_Debug_GetLevel(level); }
    inline FMOD_RESULT File_SetDiskBusy(int busy) { return FMOD_File_SetDiskBusy(busy); }
    inline FMOD_RESULT File_GetDiskBusy(int *busy) { return FMOD_File_GetDiskBusy(busy); }

    /*
        FMOD System factory functions.
    */
    inline FMOD_RESULT System_Create(System **system) { return FMOD_System_Create((FMOD_SYSTEM **)system); }

    /*
       'System' API
    */

    class System
    {
      private:

        System();   /* Constructor made private so user cannot statically instance a System class.
                       System_Create must be used. */
      public:

        FMOD_RESULT release                ();

        // Pre-init functions.
        FMOD_RESULT setOutput              (FMOD_OUTPUTTYPE output);
        FMOD_RESULT getOutput              (FMOD_OUTPUTTYPE *output);
        FMOD_RESULT getNumDrivers          (int *numdrivers);
        FMOD_RESULT getDriverInfo          (int id, char *name, int namelen, FMOD_GUID *guid);
        FMOD_RESULT getDriverInfoW         (int id, short *name, int namelen, FMOD_GUID *guid);
        FMOD_RESULT getDriverCaps          (int id, FMOD_CAPS *caps, int *controlpaneloutputrate, FMOD_SPEAKERMODE *controlpanelspeakermode);
        FMOD_RESULT setDriver              (int driver);
        FMOD_RESULT getDriver              (int *driver);
        FMOD_RESULT setHardwareChannels    (int numhardwarechannels);
        FMOD_RESULT setSoftwareChannels    (int numsoftwarechannels);
        FMOD_RESULT getSoftwareChannels    (int *numsoftwarechannels);
        FMOD_RESULT setSoftwareFormat      (int samplerate, FMOD_SOUND_FORMAT format, int numoutputchannels, int maxinputchannels, FMOD_DSP_RESAMPLER resamplemethod);
        FMOD_RESULT getSoftwareFormat      (int *samplerate, FMOD_SOUND_FORMAT *format, int *numoutputchannels, int *maxinputchannels, FMOD_DSP_RESAMPLER *resamplemethod, int *bits);
        FMOD_RESULT setDSPBufferSize       (unsigned int bufferlength, int numbuffers);
        FMOD_RESULT getDSPBufferSize       (unsigned int *bufferlength, int *numbuffers);
        FMOD_RESULT setFileSystem          (FMOD_FILE_OPENCALLBACK useropen, FMOD_FILE_CLOSECALLBACK userclose, FMOD_FILE_READCALLBACK userread, FMOD_FILE_SEEKCALLBACK userseek, FMOD_FILE_ASYNCREADCALLBACK userasyncread, FMOD_FILE_ASYNCCANCELCALLBACK userasynccancel, int blockalign);
        FMOD_RESULT attachFileSystem       (FMOD_FILE_OPENCALLBACK useropen, FMOD_FILE_CLOSECALLBACK userclose, FMOD_FILE_READCALLBACK userread, FMOD_FILE_SEEKCALLBACK userseek);
        FMOD_RESULT setAdvancedSettings    (FMOD_ADVANCEDSETTINGS *settings);
        FMOD_RESULT getAdvancedSettings    (FMOD_ADVANCEDSETTINGS *settings);
        FMOD_RESULT setSpeakerMode         (FMOD_SPEAKERMODE speakermode);
        FMOD_RESULT getSpeakerMode         (FMOD_SPEAKERMODE *speakermode);
        FMOD_RESULT setCallback            (FMOD_SYSTEM_CALLBACK callback);

        // Plug-in support
        FMOD_RESULT setPluginPath          (const char *path);
        FMOD_RESULT loadPlugin             (const char *filename, unsigned int *handle, unsigned int priority = 0);
        FMOD_RESULT unloadPlugin           (unsigned int handle);
        FMOD_RESULT getNumPlugins          (FMOD_PLUGINTYPE plugintype, int *numplugins);
        FMOD_RESULT getPluginHandle        (FMOD_PLUGINTYPE plugintype, int index, unsigned int *handle);
        FMOD_RESULT getPluginInfo          (unsigned int handle, FMOD_PLUGINTYPE *plugintype, char *name, int namelen, unsigned int *version);
        FMOD_RESULT setOutputByPlugin      (unsigned int handle);
        FMOD_RESULT getOutputByPlugin      (unsigned int *handle);
        FMOD_RESULT createDSPByPlugin      (unsigned int handle, DSP **dsp);
        FMOD_RESULT registerCodec          (FMOD_CODEC_DESCRIPTION *description, unsigned int *handle, unsigned int priority = 0);
        FMOD_RESULT registerDSP            (FMOD_DSP_DESCRIPTION *description, unsigned int *handle);

        // Init/Close
        FMOD_RESULT init                   (int maxchannels, FMOD_INITFLAGS flags, void *extradriverdata);
        FMOD_RESULT close                  ();

        // General post-init system functions
        FMOD_RESULT update                 ();        /* IMPORTANT! CALL THIS ONCE PER FRAME! */

        FMOD_RESULT set3DSettings          (float dopplerscale, float distancefactor, float rolloffscale);
        FMOD_RESULT get3DSettings          (float *dopplerscale, float *distancefactor, float *rolloffscale);
        FMOD_RESULT set3DNumListeners      (int numlisteners);
        FMOD_RESULT get3DNumListeners      (int *numlisteners);
        FMOD_RESULT set3DListenerAttributes(int listener, const FMOD_VECTOR *pos, const FMOD_VECTOR *vel, const FMOD_VECTOR *forward, const FMOD_VECTOR *up);
        FMOD_RESULT get3DListenerAttributes(int listener, FMOD_VECTOR *pos, FMOD_VECTOR *vel, FMOD_VECTOR *forward, FMOD_VECTOR *up);
        FMOD_RESULT set3DRolloffCallback   (FMOD_3D_ROLLOFFCALLBACK callback);
        FMOD_RESULT set3DSpeakerPosition   (FMOD_SPEAKER speaker, float x, float y, bool active);
        FMOD_RESULT get3DSpeakerPosition   (FMOD_SPEAKER speaker, float *x, float *y, bool *active);

        FMOD_RESULT setStreamBufferSize    (unsigned int filebuffersize, FMOD_TIMEUNIT filebuffersizetype);
        FMOD_RESULT getStreamBufferSize    (unsigned int *filebuffersize, FMOD_TIMEUNIT *filebuffersizetype);

        // System information functions.
        FMOD_RESULT getVersion             (unsigned int *version);
        FMOD_RESULT getOutputHandle        (void **handle);
        FMOD_RESULT getChannelsPlaying     (int *channels);
        FMOD_RESULT getHardwareChannels    (int *numhardwarechannels);
        FMOD_RESULT getCPUUsage            (float *dsp, float *stream, float *geometry, float *update, float *total);
        FMOD_RESULT getSoundRAM            (int *currentalloced, int *maxalloced, int *total);
        FMOD_RESULT getNumCDROMDrives      (int *numdrives);
        FMOD_RESULT getCDROMDriveName      (int drive, char *drivename, int drivenamelen, char *scsiname, int scsinamelen, char *devicename, int devicenamelen);
        FMOD_RESULT getSpectrum            (float *spectrumarray, int numvalues, int channeloffset, FMOD_DSP_FFT_WINDOW windowtype);
        FMOD_RESULT getWaveData            (float *wavearray, int numvalues, int channeloffset);

        // Sound/DSP/Channel/FX creation and retrieval.
        FMOD_RESULT createSound            (const char *name_or_data, FMOD_MODE mode, FMOD_CREATESOUNDEXINFO *exinfo, Sound **sound);
        FMOD_RESULT createStream           (const char *name_or_data, FMOD_MODE mode, FMOD_CREATESOUNDEXINFO *exinfo, Sound **sound);
        FMOD_RESULT createDSP              (FMOD_DSP_DESCRIPTION *description, DSP **dsp);
        FMOD_RESULT createDSPByType        (FMOD_DSP_TYPE type, DSP **dsp);
        FMOD_RESULT createChannelGroup     (const char *name, ChannelGroup **channelgroup);
        FMOD_RESULT createSoundGroup       (const char *name, SoundGroup **soundgroup);
        FMOD_RESULT createReverb           (Reverb **reverb);

        FMOD_RESULT playSound              (FMOD_CHANNELINDEX channelid, Sound *sound, bool paused, Channel **channel);
        FMOD_RESULT playDSP                (FMOD_CHANNELINDEX channelid, DSP *dsp, bool paused, Channel **channel);
        FMOD_RESULT getChannel             (int channelid, Channel **channel);
        FMOD_RESULT getMasterChannelGroup  (ChannelGroup **channelgroup);
        FMOD_RESULT getMasterSoundGroup    (SoundGroup **soundgroup);

        // Reverb API
        FMOD_RESULT setReverbProperties    (const FMOD_REVERB_PROPERTIES *prop);
        FMOD_RESULT getReverbProperties    (FMOD_REVERB_PROPERTIES *prop);
        FMOD_RESULT setReverbAmbientProperties(FMOD_REVERB_PROPERTIES *prop);
        FMOD_RESULT getReverbAmbientProperties(FMOD_REVERB_PROPERTIES *prop);

        // System level DSP access.
        FMOD_RESULT getDSPHead             (DSP **dsp);
        FMOD_RESULT addDSP                 (DSP *dsp, DSPConnection **connection);
        FMOD_RESULT lockDSP                ();
        FMOD_RESULT unlockDSP              ();
        FMOD_RESULT getDSPClock            (unsigned int *hi, unsigned int *lo);

        // Recording API.
        FMOD_RESULT getRecordNumDrivers    (int *numdrivers);
        FMOD_RESULT getRecordDriverInfo    (int id, char *name, int namelen, FMOD_GUID *guid);
        FMOD_RESULT getRecordDriverInfoW   (int id, short *name, int namelen, FMOD_GUID *guid);
        FMOD_RESULT getRecordDriverCaps    (int id, FMOD_CAPS *caps, int *minfrequency, int *maxfrequency);
        FMOD_RESULT getRecordPosition      (int id, unsigned int *position);

        FMOD_RESULT recordStart            (int id, Sound *sound, bool loop);
        FMOD_RESULT recordStop             (int id);
        FMOD_RESULT isRecording            (int id, bool *recording);

        // Geometry API.
        FMOD_RESULT createGeometry         (int maxpolygons, int maxvertices, Geometry **geometry);
        FMOD_RESULT setGeometrySettings    (float maxworldsize);
        FMOD_RESULT getGeometrySettings    (float *maxworldsize);
        FMOD_RESULT loadGeometry           (const void *data, int datasize, Geometry **geometry);
        FMOD_RESULT getGeometryOcclusion   (const FMOD_VECTOR *listener, const FMOD_VECTOR *source, float *direct, float *reverb);

        // Network functions.
        FMOD_RESULT setNetworkProxy        (const char *proxy);
        FMOD_RESULT getNetworkProxy        (char *proxy, int proxylen);
        FMOD_RESULT setNetworkTimeout      (int timeout);
        FMOD_RESULT getNetworkTimeout      (int *timeout);

        // Userdata set/get.
        FMOD_RESULT setUserData            (void *userdata);
        FMOD_RESULT getUserData            (void **userdata);

        FMOD_RESULT getMemoryInfo          (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details);
    };

    /*
        'Sound' API
    */
    class Sound
    {
      private:

        Sound();   /* Constructor made private so user cannot statically instance a Sound class.
                      Appropriate Sound creation or retrieval function must be used. */
      public:

        FMOD_RESULT release                ();
        FMOD_RESULT getSystemObject        (System **system);

        // Standard sound manipulation functions.
        FMOD_RESULT lock                   (unsigned int offset, unsigned int length, void **ptr1, void **ptr2, unsigned int *len1, unsigned int *len2);
        FMOD_RESULT unlock                 (void *ptr1, void *ptr2, unsigned int len1, unsigned int len2);
        FMOD_RESULT setDefaults            (float frequency, float volume, float pan, int priority);
        FMOD_RESULT getDefaults            (float *frequency, float *volume, float *pan,  int *priority);
        FMOD_RESULT setVariations          (float frequencyvar, float volumevar, float panvar);
        FMOD_RESULT getVariations          (float *frequencyvar, float *volumevar, float *panvar);
        FMOD_RESULT set3DMinMaxDistance    (float min, float max);
        FMOD_RESULT get3DMinMaxDistance    (float *min, float *max);
        FMOD_RESULT set3DConeSettings      (float insideconeangle, float outsideconeangle, float outsidevolume);
        FMOD_RESULT get3DConeSettings      (float *insideconeangle, float *outsideconeangle, float *outsidevolume);
        FMOD_RESULT set3DCustomRolloff     (FMOD_VECTOR *points, int numpoints);
        FMOD_RESULT get3DCustomRolloff     (FMOD_VECTOR **points, int *numpoints);
        FMOD_RESULT setSubSound            (int index, Sound *subsound);
        FMOD_RESULT getSubSound            (int index, Sound **subsound);
        FMOD_RESULT setSubSoundSentence    (int *subsoundlist, int numsubsounds);
        FMOD_RESULT getName                (char *name, int namelen);
        FMOD_RESULT getLength              (unsigned int *length, FMOD_TIMEUNIT lengthtype);
        FMOD_RESULT getFormat              (FMOD_SOUND_TYPE *type, FMOD_SOUND_FORMAT *format, int *channels, int *bits);
        FMOD_RESULT getNumSubSounds        (int *numsubsounds);
        FMOD_RESULT getNumTags             (int *numtags, int *numtagsupdated);
        FMOD_RESULT getTag                 (const char *name, int index, FMOD_TAG *tag);
        FMOD_RESULT getOpenState           (FMOD_OPENSTATE *openstate, unsigned int *percentbuffered, bool *starving, bool *diskbusy);
        FMOD_RESULT readData               (void *buffer, unsigned int lenbytes, unsigned int *read);
        FMOD_RESULT seekData               (unsigned int pcm);

        FMOD_RESULT setSoundGroup          (SoundGroup *soundgroup);
        FMOD_RESULT getSoundGroup          (SoundGroup **soundgroup);

        // Synchronization point API.  These points can come from markers embedded in wav files, and can also generate channel callbacks.
        FMOD_RESULT getNumSyncPoints       (int *numsyncpoints);
        FMOD_RESULT getSyncPoint           (int index, FMOD_SYNCPOINT **point);
        FMOD_RESULT getSyncPointInfo       (FMOD_SYNCPOINT *point, char *name, int namelen, unsigned int *offset, FMOD_TIMEUNIT offsettype);
        FMOD_RESULT addSyncPoint           (unsigned int offset, FMOD_TIMEUNIT offsettype, const char *name, FMOD_SYNCPOINT **point);
        FMOD_RESULT deleteSyncPoint        (FMOD_SYNCPOINT *point);

        // Functions also in Channel class but here they are the 'default' to save having to change it in Channel all the time.
        FMOD_RESULT setMode                (FMOD_MODE mode);
        FMOD_RESULT getMode                (FMOD_MODE *mode);
        FMOD_RESULT setLoopCount           (int loopcount);
        FMOD_RESULT getLoopCount           (int *loopcount);
        FMOD_RESULT setLoopPoints          (unsigned int loopstart, FMOD_TIMEUNIT loopstarttype, unsigned int loopend, FMOD_TIMEUNIT loopendtype);
        FMOD_RESULT getLoopPoints          (unsigned int *loopstart, FMOD_TIMEUNIT loopstarttype, unsigned int *loopend, FMOD_TIMEUNIT loopendtype);

        // For MOD/S3M/XM/IT/MID sequenced formats only.
        FMOD_RESULT getMusicNumChannels    (int *numchannels);
        FMOD_RESULT setMusicChannelVolume  (int channel, float volume);
        FMOD_RESULT getMusicChannelVolume  (int channel, float *volume);
        FMOD_RESULT setMusicSpeed          (float speed);
        FMOD_RESULT getMusicSpeed          (float *speed);

        // Userdata set/get.
        FMOD_RESULT setUserData            (void *userdata);
        FMOD_RESULT getUserData            (void **userdata);

        FMOD_RESULT getMemoryInfo          (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details);
    };

    /*
        'Channel' API.
    */
    class Channel
    {
      private:

        Channel();   /* Constructor made private so user cannot statically instance a Channel class.
                        Appropriate Channel creation or retrieval function must be used. */
      public:

        FMOD_RESULT getSystemObject        (System **system);

        FMOD_RESULT stop                   ();
        FMOD_RESULT setPaused              (bool paused);
        FMOD_RESULT getPaused              (bool *paused);
        FMOD_RESULT setVolume              (float volume);
        FMOD_RESULT getVolume              (float *volume);
        FMOD_RESULT setFrequency           (float frequency);
        FMOD_RESULT getFrequency           (float *frequency);
        FMOD_RESULT setPan                 (float pan);
        FMOD_RESULT getPan                 (float *pan);
        FMOD_RESULT setDelay               (FMOD_DELAYTYPE delaytype, unsigned int delayhi, unsigned int delaylo);
        FMOD_RESULT getDelay               (FMOD_DELAYTYPE delaytype, unsigned int *delayhi, unsigned int *delaylo);
        FMOD_RESULT setSpeakerMix          (float frontleft, float frontright, float center, float lfe, float backleft, float backright, float sideleft, float sideright);
        FMOD_RESULT getSpeakerMix          (float *frontleft, float *frontright, float *center, float *lfe, float *backleft, float *backright, float *sideleft, float *sideright);
        FMOD_RESULT setSpeakerLevels       (FMOD_SPEAKER speaker, float *levels, int numlevels);
        FMOD_RESULT getSpeakerLevels       (FMOD_SPEAKER speaker, float *levels, int numlevels);
        FMOD_RESULT setInputChannelMix     (float *levels, int numlevels);
        FMOD_RESULT getInputChannelMix     (float *levels, int numlevels);
        FMOD_RESULT setMute                (bool mute);
        FMOD_RESULT getMute                (bool *mute);
        FMOD_RESULT setPriority            (int priority);
        FMOD_RESULT getPriority            (int *priority);
        FMOD_RESULT setPosition            (unsigned int position, FMOD_TIMEUNIT postype);
        FMOD_RESULT getPosition            (unsigned int *position, FMOD_TIMEUNIT postype);
        FMOD_RESULT setReverbProperties    (const FMOD_REVERB_CHANNELPROPERTIES *prop);
        FMOD_RESULT getReverbProperties    (FMOD_REVERB_CHANNELPROPERTIES *prop);
        FMOD_RESULT setLowPassGain         (float gain);
        FMOD_RESULT getLowPassGain         (float *gain);

        FMOD_RESULT setChannelGroup        (ChannelGroup *channelgroup);
        FMOD_RESULT getChannelGroup        (ChannelGroup **channelgroup);
        FMOD_RESULT setCallback            (FMOD_CHANNEL_CALLBACK callback);

        // 3D functionality.
        FMOD_RESULT set3DAttributes        (const FMOD_VECTOR *pos, const FMOD_VECTOR *vel);
        FMOD_RESULT get3DAttributes        (FMOD_VECTOR *pos, FMOD_VECTOR *vel);
        FMOD_RESULT set3DMinMaxDistance    (float mindistance, float maxdistance);
        FMOD_RESULT get3DMinMaxDistance    (float *mindistance, float *maxdistance);
        FMOD_RESULT set3DConeSettings      (float insideconeangle, float outsideconeangle, float outsidevolume);
        FMOD_RESULT get3DConeSettings      (float *insideconeangle, float *outsideconeangle, float *outsidevolume);
        FMOD_RESULT set3DConeOrientation   (FMOD_VECTOR *orientation);
        FMOD_RESULT get3DConeOrientation   (FMOD_VECTOR *orientation);
        FMOD_RESULT set3DCustomRolloff     (FMOD_VECTOR *points, int numpoints);
        FMOD_RESULT get3DCustomRolloff     (FMOD_VECTOR **points, int *numpoints);
        FMOD_RESULT set3DOcclusion         (float directocclusion, float reverbocclusion);
        FMOD_RESULT get3DOcclusion         (float *directocclusion, float *reverbocclusion);
        FMOD_RESULT set3DSpread            (float angle);
        FMOD_RESULT get3DSpread            (float *angle);
        FMOD_RESULT set3DPanLevel          (float level);
        FMOD_RESULT get3DPanLevel          (float *level);
        FMOD_RESULT set3DDopplerLevel      (float level);
        FMOD_RESULT get3DDopplerLevel      (float *level);
        FMOD_RESULT set3DDistanceFilter    (bool custom, float customLevel, float centerFreq);
        FMOD_RESULT get3DDistanceFilter    (bool *custom, float *customLevel, float *centerFreq);

        // DSP functionality only for channels playing sounds created with FMOD_SOFTWARE.
        FMOD_RESULT getDSPHead             (DSP **dsp);
        FMOD_RESULT addDSP                 (DSP *dsp, DSPConnection **connection);

        // Information only functions.
        FMOD_RESULT isPlaying              (bool *isplaying);
        FMOD_RESULT isVirtual              (bool *isvirtual);
        FMOD_RESULT getAudibility          (float *audibility);
        FMOD_RESULT getCurrentSound        (Sound **sound);
        FMOD_RESULT getSpectrum            (float *spectrumarray, int numvalues, int channeloffset, FMOD_DSP_FFT_WINDOW windowtype);
        FMOD_RESULT getWaveData            (float *wavearray, int numvalues, int channeloffset);
        FMOD_RESULT getIndex               (int *index);

        // Functions also found in Sound class but here they can be set per channel.
        FMOD_RESULT setMode                (FMOD_MODE mode);
        FMOD_RESULT getMode                (FMOD_MODE *mode);
        FMOD_RESULT setLoopCount           (int loopcount);
        FMOD_RESULT getLoopCount           (int *loopcount);
        FMOD_RESULT setLoopPoints          (unsigned int loopstart, FMOD_TIMEUNIT loopstarttype, unsigned int loopend, FMOD_TIMEUNIT loopendtype);
        FMOD_RESULT getLoopPoints          (unsigned int *loopstart, FMOD_TIMEUNIT loopstarttype, unsigned int *loopend, FMOD_TIMEUNIT loopendtype);

        // Userdata set/get.
        FMOD_RESULT setUserData            (void *userdata);
        FMOD_RESULT getUserData            (void **userdata);

        FMOD_RESULT getMemoryInfo          (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details);
    };

    /*
        'ChannelGroup' API
    */
    class ChannelGroup
    {
      private:

        ChannelGroup();   /* Constructor made private so user cannot statically instance a ChannelGroup class.
                             Appropriate ChannelGroup creation or retrieval function must be used. */
      public:

        FMOD_RESULT release                 ();
        FMOD_RESULT getSystemObject         (System **system);

        // Channelgroup scale values.  (changes attributes relative to the channels, doesn't overwrite them)
        FMOD_RESULT setVolume               (float volume);
        FMOD_RESULT getVolume               (float *volume);
        FMOD_RESULT setPitch                (float pitch);
        FMOD_RESULT getPitch                (float *pitch);
        FMOD_RESULT set3DOcclusion          (float directocclusion, float reverbocclusion);
        FMOD_RESULT get3DOcclusion          (float *directocclusion, float *reverbocclusion);
        FMOD_RESULT setPaused               (bool paused);
        FMOD_RESULT getPaused               (bool *paused);
        FMOD_RESULT setMute                 (bool mute);
        FMOD_RESULT getMute                 (bool *mute);

        // Channelgroup override values.  (recursively overwrites whatever settings the channels had)
        FMOD_RESULT stop                    ();
        FMOD_RESULT overrideVolume          (float volume);
        FMOD_RESULT overrideFrequency       (float frequency);
        FMOD_RESULT overridePan             (float pan);
        FMOD_RESULT overrideReverbProperties(const FMOD_REVERB_CHANNELPROPERTIES *prop);
        FMOD_RESULT override3DAttributes    (const FMOD_VECTOR *pos, const FMOD_VECTOR *vel);
        FMOD_RESULT overrideSpeakerMix      (float frontleft, float frontright, float center, float lfe, float backleft, float backright, float sideleft, float sideright);

        // Nested channel groups.
        FMOD_RESULT addGroup                (ChannelGroup *group);
        FMOD_RESULT getNumGroups            (int *numgroups);
        FMOD_RESULT getGroup                (int index, ChannelGroup **group);
        FMOD_RESULT getParentGroup          (ChannelGroup **group);

        // DSP functionality only for channel groups playing sounds created with FMOD_SOFTWARE.
        FMOD_RESULT getDSPHead              (DSP **dsp);
        FMOD_RESULT addDSP                  (DSP *dsp, DSPConnection **connection);

        // Information only functions.
        FMOD_RESULT getName                 (char *name, int namelen);
        FMOD_RESULT getNumChannels          (int *numchannels);
        FMOD_RESULT getChannel              (int index, Channel **channel);
        FMOD_RESULT getSpectrum             (float *spectrumarray, int numvalues, int channeloffset, FMOD_DSP_FFT_WINDOW windowtype);
        FMOD_RESULT getWaveData             (float *wavearray, int numvalues, int channeloffset);

        // Userdata set/get.
        FMOD_RESULT setUserData             (void *userdata);
        FMOD_RESULT getUserData             (void **userdata);

        FMOD_RESULT getMemoryInfo           (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details);
    };

    /*
        'SoundGroup' API
    */
    class SoundGroup
    {
      private:

        SoundGroup();       /* Constructor made private so user cannot statically instance a SoundGroup class.
                               Appropriate SoundGroup creation or retrieval function must be used. */
      public:

        FMOD_RESULT release                ();
        FMOD_RESULT getSystemObject        (System **system);

        // SoundGroup control functions.
        FMOD_RESULT setMaxAudible          (int maxaudible);
        FMOD_RESULT getMaxAudible          (int *maxaudible);
        FMOD_RESULT setMaxAudibleBehavior  (FMOD_SOUNDGROUP_BEHAVIOR behavior);
        FMOD_RESULT getMaxAudibleBehavior  (FMOD_SOUNDGROUP_BEHAVIOR *behavior);
        FMOD_RESULT setMuteFadeSpeed       (float speed);
        FMOD_RESULT getMuteFadeSpeed       (float *speed);
        FMOD_RESULT setVolume              (float volume);
        FMOD_RESULT getVolume              (float *volume);
        FMOD_RESULT stop                   ();

        // Information only functions.
        FMOD_RESULT getName                (char *name, int namelen);
        FMOD_RESULT getNumSounds           (int *numsounds);
        FMOD_RESULT getSound               (int index, Sound **sound);
        FMOD_RESULT getNumPlaying          (int *numplaying);

        // Userdata set/get.
        FMOD_RESULT setUserData            (void *userdata);
        FMOD_RESULT getUserData            (void **userdata);

        FMOD_RESULT getMemoryInfo          (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details);
    };

    /*
        'DSP' API
    */
    class DSP
    {
      private:

        DSP();   /* Constructor made private so user cannot statically instance a DSP class.
                    Appropriate DSP creation or retrieval function must be used. */
      public:

        FMOD_RESULT release                ();
        FMOD_RESULT getSystemObject        (System **system);

        // Connection / disconnection / input and output enumeration.
        FMOD_RESULT addInput               (DSP *target, DSPConnection **connection);
        FMOD_RESULT disconnectFrom         (DSP *target);
        FMOD_RESULT disconnectAll          (bool inputs, bool outputs);
        FMOD_RESULT remove                 ();
        FMOD_RESULT getNumInputs           (int *numinputs);
        FMOD_RESULT getNumOutputs          (int *numoutputs);
        FMOD_RESULT getInput               (int index, DSP **input, DSPConnection **inputconnection);
        FMOD_RESULT getOutput              (int index, DSP **output, DSPConnection **outputconnection);

        // DSP unit control.
        FMOD_RESULT setActive              (bool active);
        FMOD_RESULT getActive              (bool *active);
        FMOD_RESULT setBypass              (bool bypass);
        FMOD_RESULT getBypass              (bool *bypass);
        FMOD_RESULT setSpeakerActive		 (FMOD_SPEAKER speaker, bool active);
		FMOD_RESULT getSpeakerActive		 (FMOD_SPEAKER speaker, bool *active);
		FMOD_RESULT reset                  ();


        // DSP parameter control.
        FMOD_RESULT setParameter           (int index, float value);
        FMOD_RESULT getParameter           (int index, float *value, char *valuestr, int valuestrlen);
        FMOD_RESULT getNumParameters       (int *numparams);
        FMOD_RESULT getParameterInfo       (int index, char *name, char *label, char *description, int descriptionlen, float *min, float *max);
        FMOD_RESULT showConfigDialog       (void *hwnd, bool show);

        // DSP attributes.
        FMOD_RESULT getInfo                (char *name, unsigned int *version, int *channels, int *configwidth, int *configheight);
        FMOD_RESULT getType                (FMOD_DSP_TYPE *type);
        FMOD_RESULT setDefaults            (float frequency, float volume, float pan, int priority);
        FMOD_RESULT getDefaults            (float *frequency, float *volume, float *pan, int *priority);

        // Userdata set/get.
        FMOD_RESULT setUserData            (void *userdata);
        FMOD_RESULT getUserData            (void **userdata);

        FMOD_RESULT getMemoryInfo          (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details);
    };


    /*
        'DSPConnection' API
    */
    class DSPConnection
    {
      private:

        DSPConnection();    /* Constructor made private so user cannot statically instance a DSPConnection class.
                               Appropriate DSPConnection creation or retrieval function must be used. */

      public:

        FMOD_RESULT getInput              (DSP **input);
        FMOD_RESULT getOutput             (DSP **output);
        FMOD_RESULT setMix                (float volume);
        FMOD_RESULT getMix                (float *volume);
        FMOD_RESULT setLevels             (FMOD_SPEAKER speaker, float *levels, int numlevels);
        FMOD_RESULT getLevels             (FMOD_SPEAKER speaker, float *levels, int numlevels);

        // Userdata set/get.
        FMOD_RESULT setUserData           (void *userdata);
        FMOD_RESULT getUserData           (void **userdata);

        FMOD_RESULT getMemoryInfo         (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details);
    };


    /*
        'Geometry' API
    */
    class Geometry
    {
      private:

        Geometry();   /* Constructor made private so user cannot statically instance a Geometry class.
                         Appropriate Geometry creation or retrieval function must be used. */

      public:

        FMOD_RESULT release                ();

        // Polygon manipulation.
        FMOD_RESULT addPolygon             (float directocclusion, float reverbocclusion, bool doublesided, int numvertices, const FMOD_VECTOR *vertices, int *polygonindex);
        FMOD_RESULT getNumPolygons         (int *numpolygons);
        FMOD_RESULT getMaxPolygons         (int *maxpolygons, int *maxvertices);
        FMOD_RESULT getPolygonNumVertices  (int index, int *numvertices);
        FMOD_RESULT setPolygonVertex       (int index, int vertexindex, const FMOD_VECTOR *vertex);
        FMOD_RESULT getPolygonVertex       (int index, int vertexindex, FMOD_VECTOR *vertex);
        FMOD_RESULT setPolygonAttributes   (int index, float directocclusion, float reverbocclusion, bool doublesided);
        FMOD_RESULT getPolygonAttributes   (int index, float *directocclusion, float *reverbocclusion, bool *doublesided);

        // Object manipulation.
        FMOD_RESULT setActive              (bool active);
        FMOD_RESULT getActive              (bool *active);
        FMOD_RESULT setRotation            (const FMOD_VECTOR *forward, const FMOD_VECTOR *up);
        FMOD_RESULT getRotation            (FMOD_VECTOR *forward, FMOD_VECTOR *up);
        FMOD_RESULT setPosition            (const FMOD_VECTOR *position);
        FMOD_RESULT getPosition            (FMOD_VECTOR *position);
        FMOD_RESULT setScale               (const FMOD_VECTOR *scale);
        FMOD_RESULT getScale               (FMOD_VECTOR *scale);
        FMOD_RESULT save                   (void *data, int *datasize);

        // Userdata set/get.
        FMOD_RESULT setUserData            (void *userdata);
        FMOD_RESULT getUserData            (void **userdata);

        FMOD_RESULT getMemoryInfo          (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details);
    };


    /*
        'Reverb' API
    */
    class Reverb
    {
      private:

        Reverb();    /*  Constructor made private so user cannot statically instance a Reverb class.
                         Appropriate Reverb creation or retrieval function must be used. */

      public:

        FMOD_RESULT release                ();

        // Reverb manipulation.
        FMOD_RESULT set3DAttributes        (const FMOD_VECTOR *position, float mindistance, float maxdistance);
        FMOD_RESULT get3DAttributes        (FMOD_VECTOR *position, float *mindistance,float *maxdistance);
        FMOD_RESULT setProperties          (const FMOD_REVERB_PROPERTIES *properties);
        FMOD_RESULT getProperties          (FMOD_REVERB_PROPERTIES *properties);
        FMOD_RESULT setActive              (bool active);
        FMOD_RESULT getActive              (bool *active);

        // Userdata set/get.
        FMOD_RESULT setUserData            (void *userdata);
        FMOD_RESULT getUserData            (void **userdata);

        FMOD_RESULT getMemoryInfo          (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details);
    };
}

#endif
