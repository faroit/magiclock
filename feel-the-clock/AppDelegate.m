#import "AppDelegate.h"

#include <CoreMIDI/CoreMIDI.h>

#define BEAT_TICKS 24
#define SMOOTHING_FACTOR 0.5f


@interface AppDelegate ()

@property bool showBPM;

@property (readwrite) int clock_count;
@property (nonatomic) double bpm;

@property double currentClockTime;
@property double previousClockTime;

@property int currentNumTicks;

@property double intervalInNanoseconds;
@property double tickDelta;

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) NSMenuItem * bpmMenu;
@property NSNumberFormatter *formatter;


@end

@implementation AppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    self.clock_count = BEAT_TICKS;
    self.bpm = 0;
    self.currentClockTime = 0;
    self.tickDelta = 0;

    [self setupStatusItem];

    // Set Number formatter for MIDI tempo
    self.formatter = [[NSNumberFormatter alloc] init];

    [self.formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [self.formatter setRoundingMode:NSNumberFormatterRoundHalfUp];
    [self.formatter setMaximumFractionDigits:1];
    [self.formatter setMinimumFractionDigits:1];

    OSStatus status;
    
    MIDIClientRef   midiClient;
    MIDIEndpointRef     inPort;
    
    status = MIDIClientCreate(CFSTR("FtC MIDI client"), NULL, (__bridge void *)(self), &midiClient);
    status = MIDIDestinationCreate(midiClient, CFSTR("HaptiClock"), midiInputCallback, (__bridge void *)(self), &inPort);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {

}

- (void)setupStatusItem
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.title = @"";

    // The image that will be shown in the menu bar
    self.statusItem.image = [NSImage imageNamed:@"trayicon"];
    self.statusItem.highlightMode = NO;

    [self updateStatusItemMenu];
}


- (void)resetStatusIconTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)(0.06f)
                                         target: self
                                       selector: @selector(resetStatusIcon:)
                                       userInfo: nil
                                        repeats: NO];
    });
}

- (void)resetStatusIcon:(NSTimer *)timer {
    self.statusItem.image = [NSImage imageNamed:@"trayicon"];
}

- (void)updateStatusItemMenu
{
    NSMenu *menu = [[NSMenu alloc] init];
    

    self.bpmMenu = [menu addItemWithTitle:@"Show BPM" action:@selector(toggleBPM) keyEquivalent:@""];
    [self.bpmMenu setState: NSOnState];
    self.showBPM = true;

    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];

    self.statusItem.menu = menu;
}

- (void)toggleBPM {
    if (self.showBPM) {
        self.showBPM = false;
        [self.bpmMenu setState: NSOffState];
    } else {
        self.showBPM = true;
        [self.bpmMenu setState: NSOnState];
    }
    
}

static void midiInputCallback (const MIDIPacketList *list, void *procRef, void *srcRef) {
    UInt16 nBytes;
    
    // set pointer to app delegate to have access to the main UI thread
    AppDelegate * ad = (__bridge AppDelegate*)procRef;
    
    const MIDIPacket *packet = &list->packet[0];
    for (unsigned int i = 0; i < list->numPackets; i++) {
        nBytes = packet->length;
        UInt16 iByte, size;
        
        iByte = 0;
        while (iByte < nBytes) {
            size = 0;
            unsigned char status = packet->data[iByte];
            if (status < 0xC0) {
                size = 3;
            } else if (status < 0xE0) {
                size = 2;
            } else if (status < 0xF0) {
                size = 3;
            } else if (status < 0xF3) {
                size = 3;
            } else if (status == 0xF3) {
                size = 2;
            } else {
                size = 1;
            }
            
            if (status == 0xF8) {
                ad.previousClockTime = ad.currentClockTime;
                ad.currentClockTime = packet->timeStamp;

                if(ad.previousClockTime > 0 && ad.currentClockTime > 0)
                {
                    if (ad.tickDelta==0) {
                        ad.tickDelta = ad.currentClockTime - ad.previousClockTime;
                    }
                    else {
                        ad.tickDelta = ((ad.currentClockTime - ad.previousClockTime) * SMOOTHING_FACTOR) +
                                       ( ad.tickDelta * ( 1.0 - SMOOTHING_FACTOR) );
                    
                        const int64_t kOneThousand = 1000;
                        static mach_timebase_info_data_t s_timebase_info;
                        
                        if (s_timebase_info.denom == 0)
                        {
                            (void) mach_timebase_info(&s_timebase_info);
                        }
                        
                        // mach_absolute_time() returns billionth of seconds,
                        // so divide by one thousand to get nanoseconds
                        ad.intervalInNanoseconds = (uint64_t)((ad.tickDelta * s_timebase_info.numer) / (kOneThousand * s_timebase_info.denom));
                        
                        double newBPM = (1000000 / ad.intervalInNanoseconds / BEAT_TICKS) * 60;
                        ad.bpm = (newBPM*SMOOTHING_FACTOR) + ( ad.bpm * ( 1.0f - SMOOTHING_FACTOR) );
                        if (ad.bpm > 0 && ad.showBPM) {
                            ad.statusItem.title = [ad.formatter stringFromNumber:[NSNumber numberWithFloat:ad.bpm]];
                        } else {
                            ad.statusItem.title = @"";
                        }
                        
                    }
                }

                if (ad.clock_count % BEAT_TICKS == 0) {
                    ad.clock_count = 0;
                    ad.statusItem.image = [NSImage imageNamed:@"trayicon-tic"];

                    // Provide haptic feedback                   
                    [[NSHapticFeedbackManager defaultPerformer] performFeedbackPattern:NSHapticFeedbackPatternLevelChange performanceTime:NSHapticFeedbackPerformanceTimeNow];
                    [ad resetStatusIconTimer];
                }
                ad.clock_count++;
                
            }
            // Get MIDI stop msg
            else if (status == 0xFC) {
                ad.clock_count = BEAT_TICKS;
                ad.statusItem.title = @"";
            }

            iByte += size;
        }
        packet = MIDIPacketNext(packet);
    }
}


@end
