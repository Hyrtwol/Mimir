/*
    fmod_event.hpp - Data-driven event classes
    Copyright (c), Firelight Technologies Pty, Ltd. 2004-2014.

    This header is the base header for all other FMOD EventSystem headers. If you are programming in C use FMOD_EVENT.H
*/

#ifndef __FMOD_EVENT_HPP__
#define __FMOD_EVENT_HPP__

#ifndef _FMOD_HPP
#include "fmod.hpp"
#endif
#ifndef __FMOD_EVENT_H__
#include "fmod_event.h"
#endif

namespace FMOD
{
    class EventSystem;
    class EventCategory;
    class EventProject;
    class EventGroup;
    class Event;
    class EventParameter;
    class EventReverb;
    class EventQueue;
    class EventQueueEntry;
    class MusicSystem;
    class MusicPrompt;

    /*
        FMOD EventSystem factory functions.
    */
    inline FMOD_RESULT EventSystem_Create(EventSystem **eventsystem) { return FMOD_EventSystem_Create((FMOD_EVENTSYSTEM **)eventsystem); }

    /*
       'EventSystem' API
    */
    class EventSystem
    {
        public :

        // Initialization / system functions.
        FMOD_RESULT init                      (int maxchannels, FMOD_INITFLAGS flags, void *extradriverdata, FMOD_EVENT_INITFLAGS eventflags = FMOD_EVENT_INIT_NORMAL);
        FMOD_RESULT release                   ();
        FMOD_RESULT update                    ();
        FMOD_RESULT setMediaPath              (const char *path);
        FMOD_RESULT setPluginPath             (const char *path);
        FMOD_RESULT getVersion                (unsigned int *version);
        FMOD_RESULT getInfo                   (FMOD_EVENT_SYSTEMINFO *info);
        FMOD_RESULT getSystemObject           (System **system);
        FMOD_RESULT getMusicSystem            (MusicSystem **musicsystem);
        FMOD_RESULT setLanguage               (const char *language);
        FMOD_RESULT getLanguage               (char *language);
        FMOD_RESULT registerDSP               (FMOD_DSP_DESCRIPTION *description, unsigned int *handle);

        // FEV load/unload.
        FMOD_RESULT load                      (const char *name_or_data, FMOD_EVENT_LOADINFO *loadinfo, EventProject **project);
        FMOD_RESULT unload                    ();

        // Event,EventGroup,EventCategory Retrieval.
        FMOD_RESULT getProject                (const char *name, EventProject **project);
        FMOD_RESULT getProjectByIndex         (int index,        EventProject **project);
        FMOD_RESULT getNumProjects            (int *numprojects);
        FMOD_RESULT getCategory               (const char *name, EventCategory **category);
        FMOD_RESULT getCategoryByIndex        (int index,        EventCategory **category);
        FMOD_RESULT getMusicCategory          (EventCategory **category);
        FMOD_RESULT getNumCategories          (int *numcategories);
        FMOD_RESULT getGroup                  (const char *name, bool cacheevents, EventGroup **group);
        FMOD_RESULT getEvent                  (const char *name, FMOD_EVENT_MODE mode, Event **event);
        FMOD_RESULT getEventBySystemID        (unsigned int systemid, FMOD_EVENT_MODE mode, Event **event);
        FMOD_RESULT getEventByGUID            (const FMOD_GUID *guid, FMOD_EVENT_MODE mode, Event **event);
        FMOD_RESULT getEventByGUIDString      (const char *guid, FMOD_EVENT_MODE mode, Event **event);
        FMOD_RESULT getNumEvents              (int *numevents);

        // Reverb interfaces.
        FMOD_RESULT setReverbProperties       (const FMOD_REVERB_PROPERTIES *props);
        FMOD_RESULT getReverbProperties       (FMOD_REVERB_PROPERTIES *props);

        FMOD_RESULT getReverbPreset           (const char *name, FMOD_REVERB_PROPERTIES *props, int *index = 0);
        FMOD_RESULT getReverbPresetByIndex    (const int index,  FMOD_REVERB_PROPERTIES *props, char **name = 0);
        FMOD_RESULT getNumReverbPresets       (int *numpresets);

        FMOD_RESULT createReverb              (EventReverb **reverb);
        FMOD_RESULT setReverbAmbientProperties(FMOD_REVERB_PROPERTIES *props);
        FMOD_RESULT getReverbAmbientProperties(FMOD_REVERB_PROPERTIES *props);

        // Event queue interfaces.
        FMOD_RESULT createEventQueue          (EventQueue **queue);
        FMOD_RESULT createEventQueueEntry     (Event *event, EventQueueEntry **entry);

        // 3D Listener interface.
        FMOD_RESULT set3DNumListeners         (int numlisteners);
        FMOD_RESULT get3DNumListeners         (int *numlisteners);
        FMOD_RESULT set3DListenerAttributes   (int listener, const FMOD_VECTOR *pos, const FMOD_VECTOR *vel, const FMOD_VECTOR *forward, const FMOD_VECTOR *up);
        FMOD_RESULT get3DListenerAttributes   (int listener, FMOD_VECTOR *pos, FMOD_VECTOR *vel, FMOD_VECTOR *forward, FMOD_VECTOR *up);

        // Get/set user data
        FMOD_RESULT setUserData               (void *userdata);
        FMOD_RESULT getUserData               (void **userdata);

        // Pre-loading FSB files (from disk or from memory, use FMOD_OPENMEMORY_POINT to point to pre-loaded memory).
        FMOD_RESULT preloadFSB                (const char *filename, int streaminstance, Sound *sound, bool unloadprevious = false);
        FMOD_RESULT unloadFSB                 (const char *filename, int streaminstance);

        FMOD_RESULT getMemoryInfo             (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details);
    };

    /*
       'EventProject' API
    */
    class EventProject
    {
        public :

        virtual FMOD_RESULT release            () = 0;
        virtual FMOD_RESULT getInfo            (FMOD_EVENT_PROJECTINFO *info) = 0;
        virtual FMOD_RESULT getGroup           (const char *name, bool cacheevents, EventGroup **group) = 0;
        virtual FMOD_RESULT getGroupByIndex    (int index,        bool cacheevents, EventGroup **group) = 0;
        virtual FMOD_RESULT getNumGroups       (int *numgroups) = 0;
        virtual FMOD_RESULT getEvent           (const char *name, FMOD_EVENT_MODE mode, Event **event) = 0;
        virtual FMOD_RESULT getEventByProjectID(unsigned int projectid, FMOD_EVENT_MODE mode, Event **event) = 0;
        virtual FMOD_RESULT getNumEvents       (int *numevents) = 0;
        virtual FMOD_RESULT loadSampleData     (int *eventid_array, int sizeof_eventid_array, char **groupname_array, int sizeof_groupname_array, FMOD_EVENT_MODE eventmode) = 0;
        virtual FMOD_RESULT stopAllEvents      (bool immediate = false) = 0;
        virtual FMOD_RESULT cancelAllLoads     () = 0;
        virtual FMOD_RESULT setUserData        (void *userdata) = 0;
        virtual FMOD_RESULT getUserData        (void **userdata) = 0;

        virtual FMOD_RESULT getMemoryInfo      (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details) = 0;
        virtual ~EventProject(){};
    };

    /*
       'EventGroup' API
    */
    class EventGroup
    {
        public :

        virtual FMOD_RESULT getInfo            (int *index, char **name) = 0;
        virtual FMOD_RESULT loadEventData      (FMOD_EVENT_RESOURCE resource = FMOD_EVENT_RESOURCE_STREAMS_AND_SAMPLES, FMOD_EVENT_MODE mode = FMOD_EVENT_DEFAULT) = 0;
        virtual FMOD_RESULT freeEventData      (Event *event = 0, bool waituntilready = true) = 0;
        virtual FMOD_RESULT getGroup           (const char *name, bool cacheevents, EventGroup **group) = 0;
        virtual FMOD_RESULT getGroupByIndex    (int index,        bool cacheevents, EventGroup **group) = 0;
        virtual FMOD_RESULT getParentGroup     (EventGroup **group) = 0;
        virtual FMOD_RESULT getParentProject   (EventProject **project) = 0;
        virtual FMOD_RESULT getNumGroups       (int *numgroups) = 0;
        virtual FMOD_RESULT getEvent           (const char *name, FMOD_EVENT_MODE mode, Event **event) = 0;
        virtual FMOD_RESULT getEventByIndex    (int index,        FMOD_EVENT_MODE mode, Event **event) = 0;
        virtual FMOD_RESULT getNumEvents       (int *numevents) = 0;
        virtual FMOD_RESULT getProperty        (const char *propertyname, void *value) = 0;
        virtual FMOD_RESULT getPropertyByIndex (int propertyindex, void *value) = 0;
        virtual FMOD_RESULT getNumProperties   (int *numproperties) = 0;
        virtual FMOD_RESULT getState           (FMOD_EVENT_STATE *state) = 0;
        virtual FMOD_RESULT setUserData        (void *userdata) = 0;
        virtual FMOD_RESULT getUserData        (void **userdata) = 0;

        virtual FMOD_RESULT getMemoryInfo      (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details) = 0;
        virtual ~EventGroup(){};
    };

    /*
       'EventCategory' API
    */
    class EventCategory
    {
        public :

        virtual FMOD_RESULT getInfo            (int *index, char **name) = 0;
        virtual FMOD_RESULT getCategory        (const char *name, EventCategory **category) = 0;
        virtual FMOD_RESULT getCategoryByIndex (int index, EventCategory **category) = 0;
        virtual FMOD_RESULT getNumCategories   (int *numcategories) = 0;
        virtual FMOD_RESULT getEventByIndex    (int index, FMOD_EVENT_MODE mode, Event **event) = 0;
        virtual FMOD_RESULT getNumEvents       (int *numevents) = 0;
        virtual FMOD_RESULT getParentCategory  (EventCategory **category) = 0;

        virtual FMOD_RESULT stopAllEvents      () = 0;
        virtual FMOD_RESULT setVolume          (float volume) = 0;
        virtual FMOD_RESULT getVolume          (float *volume) = 0;
        virtual FMOD_RESULT setPitch           (float pitch, FMOD_EVENT_PITCHUNITS units = FMOD_EVENT_PITCHUNITS_RAW) = 0;
        virtual FMOD_RESULT getPitch           (float *pitch, FMOD_EVENT_PITCHUNITS units = FMOD_EVENT_PITCHUNITS_RAW) = 0;
        virtual FMOD_RESULT setPaused          (bool paused) = 0;
        virtual FMOD_RESULT getPaused          (bool *paused) = 0;
        virtual FMOD_RESULT setMute            (bool mute) = 0;
        virtual FMOD_RESULT getMute            (bool *mute) = 0;
        virtual FMOD_RESULT getChannelGroup    (ChannelGroup **channelgroup) = 0;
        virtual FMOD_RESULT setUserData        (void *userdata) = 0;
        virtual FMOD_RESULT getUserData        (void **userdata) = 0;

        virtual FMOD_RESULT getMemoryInfo      (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details) = 0;
        virtual ~EventCategory(){};
    };

    /*
       'Event' API
    */
    class Event
    {
        public :

        FMOD_RESULT release                    (bool freeeventdata = false, bool waituntilready = true);

        FMOD_RESULT start                      ();
        FMOD_RESULT stop                       (bool immediate = false);

        FMOD_RESULT getInfo                    (int *index, char **name, FMOD_EVENT_INFO *info);
        FMOD_RESULT getState                   (FMOD_EVENT_STATE *state);
        FMOD_RESULT getParentGroup             (EventGroup **group);
        FMOD_RESULT getChannelGroup            (ChannelGroup **channelgroup);
        FMOD_RESULT setCallback                (FMOD_EVENT_CALLBACK callback, void *userdata);

        FMOD_RESULT getParameter               (const char *name, EventParameter **parameter);
        FMOD_RESULT getParameterByIndex        (int index, EventParameter **parameter);
        FMOD_RESULT getNumParameters           (int *numparameters);
        FMOD_RESULT getProperty                (const char *propertyname, void *value, bool this_instance = false);
        FMOD_RESULT getPropertyByIndex         (int propertyindex, void *value, bool this_instance = false);
        FMOD_RESULT setProperty                (const char *propertyname, void *value, bool this_instance = false);
        FMOD_RESULT setPropertyByIndex         (int propertyindex, void *value, bool this_instance = false);
        FMOD_RESULT getNumProperties           (int *numproperties);
        FMOD_RESULT getPropertyInfo            (int *propertyindex, char **propertyname, FMOD_EVENTPROPERTY_TYPE *type = 0);
        FMOD_RESULT getCategory                (EventCategory **category);

        FMOD_RESULT setVolume                  (float volume);
        FMOD_RESULT getVolume                  (float *volume);
        FMOD_RESULT setPitch                   (float pitch, FMOD_EVENT_PITCHUNITS units = FMOD_EVENT_PITCHUNITS_RAW);
        FMOD_RESULT getPitch                   (float *pitch, FMOD_EVENT_PITCHUNITS units = FMOD_EVENT_PITCHUNITS_RAW);
        FMOD_RESULT setPaused                  (bool paused);
        FMOD_RESULT getPaused                  (bool *paused);
        FMOD_RESULT setMute                    (bool mute);
        FMOD_RESULT getMute                    (bool *mute);
        FMOD_RESULT set3DAttributes            (const FMOD_VECTOR *position, const FMOD_VECTOR *velocity, const FMOD_VECTOR *orientation = 0);
        FMOD_RESULT get3DAttributes            (FMOD_VECTOR *position, FMOD_VECTOR *velocity, FMOD_VECTOR *orientation = 0);
        FMOD_RESULT set3DOcclusion             (float directocclusion, float reverbocclusion);
        FMOD_RESULT get3DOcclusion             (float *directocclusion, float *reverbocclusion);
        FMOD_RESULT setReverbProperties        (const FMOD_REVERB_CHANNELPROPERTIES *props);
        FMOD_RESULT getReverbProperties        (FMOD_REVERB_CHANNELPROPERTIES *props);
        FMOD_RESULT setUserData                (void *userdata);
        FMOD_RESULT getUserData                (void **userdata);

        FMOD_RESULT getMemoryInfo              (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details);
    };

    /*
       'EventParameter' API
    */
    class EventParameter
    {
        public :

        FMOD_RESULT getInfo                    (int *index, char **name);
        FMOD_RESULT getRange                   (float *rangemin, float *rangemax);
        FMOD_RESULT setValue                   (float value);
        FMOD_RESULT getValue                   (float *value);
        FMOD_RESULT setVelocity                (float value);
        FMOD_RESULT getVelocity                (float *value);
        FMOD_RESULT setSeekSpeed               (float value);
        FMOD_RESULT getSeekSpeed               (float *value);
        FMOD_RESULT setUserData                (void *userdata);
        FMOD_RESULT getUserData                (void **userdata);
        FMOD_RESULT keyOff                     ();
        FMOD_RESULT disableAutomation          (bool disable);

        FMOD_RESULT getMemoryInfo              (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details);
    };

    /*
       'EventReverb ' API
    */
    class EventReverb
    {
        public :

        virtual FMOD_RESULT release            () = 0;
        virtual FMOD_RESULT set3DAttributes    (const FMOD_VECTOR *position, float mindistance, float maxdistance) = 0;
        virtual FMOD_RESULT get3DAttributes    (FMOD_VECTOR *position, float *mindistance,float *maxdistance) = 0;
        virtual FMOD_RESULT setProperties      (const FMOD_REVERB_PROPERTIES *props) = 0;
        virtual FMOD_RESULT getProperties      (FMOD_REVERB_PROPERTIES *props) = 0;
        virtual FMOD_RESULT setActive          (bool active) = 0;
        virtual FMOD_RESULT getActive          (bool *active) = 0;
        virtual FMOD_RESULT setUserData        (void *userdata) = 0;
        virtual FMOD_RESULT getUserData        (void **userdata) = 0;

        virtual FMOD_RESULT getMemoryInfo      (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details) = 0;
        virtual ~EventReverb(){};
    };

    /*
       'EventQueue' API
    */
    class EventQueue
    {
        public :

        virtual FMOD_RESULT release            () = 0;
        virtual FMOD_RESULT add                (EventQueueEntry *entry, bool allow_duplicates = true) = 0;
        virtual FMOD_RESULT remove             (EventQueueEntry *entry) = 0;
        virtual FMOD_RESULT removeHead         () = 0;
        virtual FMOD_RESULT clear              (bool stopallevents = true) = 0;
        virtual FMOD_RESULT findFirstEntry     (EventQueueEntry **entry) = 0;
        virtual FMOD_RESULT findNextEntry      (EventQueueEntry **entry) = 0;
        virtual FMOD_RESULT setPaused          (bool paused) = 0;
        virtual FMOD_RESULT getPaused          (bool *paused) = 0;
        virtual FMOD_RESULT includeDuckingCategory (EventCategory *category, float ducked_volume, float unducked_volume, unsigned int duck_time, unsigned int unduck_time) = 0;
        virtual FMOD_RESULT excludeDuckingCategory (EventCategory *category) = 0;
        virtual FMOD_RESULT setCallback        (FMOD_EVENTQUEUE_CALLBACK callback, void *callbackuserdata) = 0;
        virtual FMOD_RESULT setUserData        (void *userdata) = 0;
        virtual FMOD_RESULT getUserData        (void **userdata) = 0;
        virtual FMOD_RESULT dump               () = 0;

        virtual FMOD_RESULT getMemoryInfo      (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details) = 0;
        virtual ~EventQueue(){};
    };

    /*
       'EventQueueEntry' API
    */
    class EventQueueEntry
    {
        public :

        virtual FMOD_RESULT release            () = 0;
        virtual FMOD_RESULT getInfoOnlyEvent   (Event **infoonlyevent) = 0;
        virtual FMOD_RESULT getRealEvent       (Event **realevent) = 0;
        virtual FMOD_RESULT setPriority        (unsigned char priority) = 0;
        virtual FMOD_RESULT getPriority        (unsigned char *priority) = 0;
        virtual FMOD_RESULT setExpiryTime      (unsigned int expirytime) = 0;
        virtual FMOD_RESULT getExpiryTime      (unsigned int *expirytime) = 0;
        virtual FMOD_RESULT setDelayTime       (unsigned int delay) = 0;
        virtual FMOD_RESULT getDelayTime       (unsigned int *delay) = 0;
        virtual FMOD_RESULT setInterrupt       (bool interrupt) = 0;
        virtual FMOD_RESULT getInterrupt       (bool *interrupt) = 0;
        virtual FMOD_RESULT setCrossfadeTime   (int crossfade) = 0;
        virtual FMOD_RESULT getCrossfadeTime   (int *crossfade) = 0;
        virtual FMOD_RESULT setUserData        (void *userdata) = 0;
        virtual FMOD_RESULT getUserData        (void **userdata) = 0;

        virtual FMOD_RESULT getMemoryInfo      (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details) = 0;
        virtual ~EventQueueEntry(){};
    };

    /*
        'MusicSystem' API
    */
    class MusicSystem
    {
        public :

        virtual FMOD_RESULT reset              () = 0;
        virtual FMOD_RESULT setVolume          (float volume) = 0;
        virtual FMOD_RESULT getVolume          (float *volume) = 0;
        virtual FMOD_RESULT setReverbProperties(const FMOD_REVERB_CHANNELPROPERTIES *props) = 0;
        virtual FMOD_RESULT getReverbProperties(FMOD_REVERB_CHANNELPROPERTIES *props) = 0;
        virtual FMOD_RESULT setPaused          (bool paused) = 0;
        virtual FMOD_RESULT getPaused          (bool *paused) = 0;
        virtual FMOD_RESULT setMute            (bool mute) = 0;
        virtual FMOD_RESULT getMute            (bool *mute) = 0;
        virtual FMOD_RESULT getInfo            (FMOD_MUSIC_INFO *info) = 0;
        virtual FMOD_RESULT promptCue          (FMOD_MUSIC_CUE_ID id) = 0;
        virtual FMOD_RESULT prepareCue         (FMOD_MUSIC_CUE_ID id, MusicPrompt **prompt) = 0;
        virtual FMOD_RESULT getParameterValue  (FMOD_MUSIC_PARAM_ID id, float *parameter) = 0;
        virtual FMOD_RESULT setParameterValue  (FMOD_MUSIC_PARAM_ID id, float parameter) = 0;

        virtual FMOD_RESULT getCues            (FMOD_MUSIC_ITERATOR *it, const char *filter = 0) = 0;
        virtual FMOD_RESULT getNextCue         (FMOD_MUSIC_ITERATOR *it) = 0;
        virtual FMOD_RESULT getParameters      (FMOD_MUSIC_ITERATOR *it, const char *filter = 0) = 0;
        virtual FMOD_RESULT getNextParameter   (FMOD_MUSIC_ITERATOR *it) = 0;

        virtual FMOD_RESULT loadSoundData      (FMOD_EVENT_RESOURCE resource = FMOD_EVENT_RESOURCE_SAMPLES, FMOD_EVENT_MODE mode = FMOD_EVENT_DEFAULT) = 0;
        virtual FMOD_RESULT freeSoundData      (bool waituntilready = true) = 0;

        virtual FMOD_RESULT setCallback        (FMOD_MUSIC_CALLBACK callback, void *userdata) = 0;

        virtual FMOD_RESULT getMemoryInfo      (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details) = 0;
        virtual ~MusicSystem(){};
    };

    /*
        'MusicPrompt' API
    */
    class MusicPrompt
    {
        public :

        virtual FMOD_RESULT release            () = 0;
        virtual FMOD_RESULT begin              () = 0;
        virtual FMOD_RESULT end                () = 0;
        virtual FMOD_RESULT isActive           (bool *active) = 0;

        virtual FMOD_RESULT getMemoryInfo      (unsigned int memorybits, unsigned int event_memorybits, unsigned int *memoryused, FMOD_MEMORY_USAGE_DETAILS *memoryused_details) = 0;
        virtual ~MusicPrompt(){};
    };
}


#endif
