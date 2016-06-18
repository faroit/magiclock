#import "AppDelegate.h"
#import "ESSApplicationCategory.h"

#include <CoreMIDI/CoreMIDI.h>

#define BEAT_TICKS 24
#define SMOOTHING_FACTOR 0.5f

#define kAlreadyBeenLaunched @"AlreadyBeenLaunched"

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

@property (strong, nonatomic) NSImage *notic;
@property (strong, nonatomic) NSImage *tic;

@property (strong, nonatomic) NSMenuItem * bpmMenu;
@property NSNumberFormatter *formatter;


@end

@implementation AppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    if (!([[NSUserDefaults standardUserDefaults] boolForKey:kAlreadyBeenLaunched] || [[NSUserDefaults standardUserDefaults] boolForKey:@"showBPM"])) {
        // First launch
        // Setting userDefaults for next time
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:kAlreadyBeenLaunched];
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:@"showBPM"];
        
        [self showHelpModal];
    }
    
    self.showBPM = [[NSUserDefaults standardUserDefaults] boolForKey:@"showBPM"];

    // Check if Trackpad does exist
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(testForceTouchAvailability:) name:ESS_FORCETOUCHAVAILABILITY_NOTIFICATIONNAME object:nil];

    [self showModalForceTouchAvailable:[NSApp isForceTouchCapableDeviceAvailable:nil]];

    self.clock_count = BEAT_TICKS;
    self.bpm = 0;
    self.currentClockTime = 0;
    self.tickDelta = 0;

    // The image that will be shown in the menu bar
    self.notic = [NSImage imageNamed:@"trayicon"];
    [self.notic setTemplate:YES];
    self.tic = [NSImage imageNamed:@"trayicon-tic"];
    [self.tic setTemplate:YES];

    [self setupStatusItem];

    // Set Number formatter for MIDI tempo
    self.formatter = [[NSNumberFormatter alloc] init];

    [self.formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [self.formatter setRoundingMode:NSNumberFormatterRoundHalfUp];
    [self.formatter setMaximumFractionDigits:1];
    [self.formatter setMinimumFractionDigits:1];
    
    // Setting up Core MIDI
    OSStatus status;
    
    MIDIClientRef   midiClient;
    MIDIEndpointRef     inPort;
    
    status = MIDIClientCreate(CFSTR("Magiclock MIDI client"), NULL, (__bridge void *)(self), &midiClient);
    status = MIDIDestinationCreate(midiClient, CFSTR("Magiclock"), midiInputCallback, (__bridge void *)(self), &inPort);
    
    // Update the Menubar every 1s to show the BPM    
    [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)(1.0f)
                                     target: self
                                   selector: @selector(renderBPM:)
                                   userInfo: nil
                                    repeats: YES];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {

}

- (void)testForceTouchAvailability:(NSNotification *)note
{
    [self showModalForceTouchAvailable:((NSNumber *)note.userInfo[kESSForceTouchAvailableUserInfoKey]).boolValue];
}

- (void)showModalForceTouchAvailable:(BOOL)available
{
    if (available == NO) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"No supported Trackpad found"];
        [alert setInformativeText:@"Your trackpad does not support haptic feedback."];
        [alert addButtonWithTitle:@"Ok"];
        [alert runModal];

    }
}


- (void)showHelpModal
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"How to use Magiclock?"];
    [alert setInformativeText:@"Connect any MIDI Clock Output to \"Magiclock\" and feel the beat..."];
    [alert addButtonWithTitle:@"Ok"];
    [alert runModal];
}

- (void)setupStatusItem
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.title = @"";

    self.statusItem.image = self.notic;
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
    self.statusItem.image = self.notic;
}

- (void)updateStatusItemMenu
{
    NSMenu *menu = [[NSMenu alloc] init];

    self.bpmMenu = [menu addItemWithTitle:@"Show BPM" action:@selector(toggleBPMmenu) keyEquivalent:@""];
    if (self.showBPM) {
         [self.bpmMenu setState: NSOnState];
    } else {
         [self.bpmMenu setState: NSOffState];
    }

    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Help" action:@selector(showHelpModal) keyEquivalent:@""];
    [menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];

    self.statusItem.menu = menu;
}

- (void)toggleBPMmenu {
    if (self.showBPM) {
        self.showBPM = false;
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO] forKey:@"showBPM"];
        [self.bpmMenu setState: NSOffState];
    } else {
        self.showBPM = true;
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:@"showBPM"];
        [self.bpmMenu setState: NSOnState];
    }
    
}

- (void)renderBPM:(NSTimer *)timer {
    if (self.bpm > 0 && self.showBPM) {
        self.statusItem.title = [self.formatter stringFromNumber:[NSNumber numberWithFloat:self.bpm]];
    } else {
        self.statusItem.title = @"";
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
                        // Moving average of clock rate
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
                        
                    }
                }

                if (ad.clock_count % BEAT_TICKS == 0) {
                    ad.clock_count = 0;
                    ad.statusItem.image = ad.tic;

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
                ad.bpm = 0;
            }

            iByte += size;
        }
        packet = MIDIPacketNext(packet);
    }
}


@end
