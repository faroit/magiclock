#ifndef AbletonLinkBridge_h
#define AbletonLinkBridge_h

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct MagicAbletonLink *MagicAbletonLinkRef;
typedef struct MagicAbletonLinkSessionState *MagicAbletonLinkSessionStateRef;

MagicAbletonLinkRef MagicAbletonLinkCreate(double bpm);
void MagicAbletonLinkDestroy(MagicAbletonLinkRef link);

bool MagicAbletonLinkIsEnabled(MagicAbletonLinkRef link);
void MagicAbletonLinkEnable(MagicAbletonLinkRef link, bool enabled);

bool MagicAbletonLinkIsStartStopSyncEnabled(MagicAbletonLinkRef link);
void MagicAbletonLinkEnableStartStopSync(MagicAbletonLinkRef link, bool enabled);

uint64_t MagicAbletonLinkNumPeers(MagicAbletonLinkRef link);
int64_t MagicAbletonLinkClockMicros(MagicAbletonLinkRef link);

MagicAbletonLinkSessionStateRef MagicAbletonLinkSessionStateCreate(void);
void MagicAbletonLinkSessionStateDestroy(MagicAbletonLinkSessionStateRef sessionState);
void MagicAbletonLinkCaptureAppSessionState(
    MagicAbletonLinkRef link,
    MagicAbletonLinkSessionStateRef sessionState
);

double MagicAbletonLinkSessionTempo(MagicAbletonLinkSessionStateRef sessionState);
double MagicAbletonLinkSessionBeatAtTime(
    MagicAbletonLinkSessionStateRef sessionState,
    int64_t timeMicros,
    double quantum
);
double MagicAbletonLinkSessionPhaseAtTime(
    MagicAbletonLinkSessionStateRef sessionState,
    int64_t timeMicros,
    double quantum
);
bool MagicAbletonLinkSessionIsPlaying(MagicAbletonLinkSessionStateRef sessionState);

#ifdef __cplusplus
}
#endif

#endif
