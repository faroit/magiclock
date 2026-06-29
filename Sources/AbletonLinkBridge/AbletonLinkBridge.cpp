#include <AbletonLinkBridge.h>

#include <ableton/Link.hpp>

#include <chrono>

struct MagicAbletonLink {
  explicit MagicAbletonLink(double bpm)
    : link(bpm)
  {
  }

  ableton::Link link;
};

struct MagicAbletonLinkSessionState {
  MagicAbletonLinkSessionState()
    : state(ableton::link::ApiState{}, false)
  {
  }

  ableton::Link::SessionState state;
};

extern "C" {

MagicAbletonLinkRef MagicAbletonLinkCreate(double bpm)
{
  return new MagicAbletonLink(bpm);
}

void MagicAbletonLinkDestroy(MagicAbletonLinkRef link)
{
  delete link;
}

bool MagicAbletonLinkIsEnabled(MagicAbletonLinkRef link)
{
  return link && link->link.isEnabled();
}

void MagicAbletonLinkEnable(MagicAbletonLinkRef link, bool enabled)
{
  if (link) {
    link->link.enable(enabled);
  }
}

bool MagicAbletonLinkIsStartStopSyncEnabled(MagicAbletonLinkRef link)
{
  return link && link->link.isStartStopSyncEnabled();
}

void MagicAbletonLinkEnableStartStopSync(MagicAbletonLinkRef link, bool enabled)
{
  if (link) {
    link->link.enableStartStopSync(enabled);
  }
}

uint64_t MagicAbletonLinkNumPeers(MagicAbletonLinkRef link)
{
  if (!link) {
    return 0;
  }
  return static_cast<uint64_t>(link->link.numPeers());
}

int64_t MagicAbletonLinkClockMicros(MagicAbletonLinkRef link)
{
  if (!link) {
    return 0;
  }
  return link->link.clock().micros().count();
}

MagicAbletonLinkSessionStateRef MagicAbletonLinkSessionStateCreate(void)
{
  return new MagicAbletonLinkSessionState();
}

void MagicAbletonLinkSessionStateDestroy(MagicAbletonLinkSessionStateRef sessionState)
{
  delete sessionState;
}

void MagicAbletonLinkCaptureAppSessionState(
    MagicAbletonLinkRef link,
    MagicAbletonLinkSessionStateRef sessionState)
{
  if (link && sessionState) {
    sessionState->state = link->link.captureAppSessionState();
  }
}

double MagicAbletonLinkSessionTempo(MagicAbletonLinkSessionStateRef sessionState)
{
  if (!sessionState) {
    return 0.0;
  }
  return sessionState->state.tempo();
}

double MagicAbletonLinkSessionBeatAtTime(
    MagicAbletonLinkSessionStateRef sessionState,
    int64_t timeMicros,
    double quantum)
{
  if (!sessionState) {
    return 0.0;
  }
  return sessionState->state.beatAtTime(std::chrono::microseconds{timeMicros}, quantum);
}

double MagicAbletonLinkSessionPhaseAtTime(
    MagicAbletonLinkSessionStateRef sessionState,
    int64_t timeMicros,
    double quantum)
{
  if (!sessionState) {
    return 0.0;
  }
  return sessionState->state.phaseAtTime(std::chrono::microseconds{timeMicros}, quantum);
}

bool MagicAbletonLinkSessionIsPlaying(MagicAbletonLinkSessionStateRef sessionState)
{
  return sessionState && sessionState->state.isPlaying();
}

}
