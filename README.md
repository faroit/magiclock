# Magiclock

[![GitHub release](https://img.shields.io/github/release/faroit/magiclock.svg?style=flat-square)](https://github.com/faroit/magiclock/releases/tag/v0.2)
[![Github All Releases](https://img.shields.io/github/downloads/faroit/magiclock/total.svg?style=flat-square)]()
[![CI](https://github.com/faroit/magiclock/actions/workflows/ci.yml/badge.svg)](https://github.com/faroit/magiclock/actions/workflows/ci.yml)

Ever found the beepy metronome in your DAW annoying while producing music? Now you can turn off of the metronome and feel the beat on you trackpad. __Magiclock__ is an OS X app that uses haptic feedback (also called Taptic Engine™) to give you the MIDI clock beat within your Magic Trackpad.

Latest release: **v0.2**.

[Download Magiclock v0.2](https://github.com/faroit/magiclock/releases/download/v0.2/magiclock.zip)

## Features

![out](https://cloud.githubusercontent.com/assets/72940/16177370/e492626a-362a-11e6-9f66-2291040f98c1.gif)

* Magiclock is a menu-bar-only app that
receives MIDI Clock events and performs haptic feedback every beat/quarter note.
* Magiclock can also join an Ableton Link session and perform haptic feedback on Link beat boundaries.
* For convenience, it also calculates the BPM and shows the results in the menu bar (can be switched off).
* To align the MIDI clock to quarter notes, the MIDI start and stop events are used.
* It provides a virtual MIDI Output port called "Magiclock" that can be connected to and from anywhere inside Mac OS X.

## Requirements

The latest version, Magiclock v0.2, requires:

* macOS 10.13 High Sierra and later.
* Force Touch trackpad (2013 Macbook Pro, New Macbook, [Magic Trackpad 2](http://www.apple.com/magic-accessories/))
* MIDI clock output from DAW or hardware MIDI device, or an Ableton Link session
* For source builds: Swift 5.9 or newer with Apple Command Line Tools or Xcode.


## Download/Installation

[Download the latest v0.2 zip](https://github.com/faroit/magiclock/releases/download/v0.2/magiclock.zip) and launch __magiclock.app__. Be aware, that this app is not signed, so you might need to adjust your [security settings](https://support.apple.com/kb/PH18657?locale=en_US) Drag the app into your Applications folder, if you like.


## Usage

### Ableton Link

Open the Magiclock menu and enable **Use Ableton Link**. Magiclock will join the local Link session and tap on Link beat boundaries while Link transport is playing. Link start/stop sync is enabled, so stop messages pause haptics and the next start resumes them. While Ableton Link is enabled, incoming MIDI Clock ticks are ignored for haptics to avoid double triggering.

The menu shows the number of discovered Link peers. If **Show BPM** is enabled, the menu bar displays the current Link session tempo while Link mode is active.

Use **Downbeat Accent** to make the first beat in each 4/4 bar stand out. AppKit does not expose true haptic force control, so the Light and Strong options simulate intensity with different haptic patterns.

### Ableton Live

To use __magiclock__ with Ableton Live through MIDI Clock, activate the sync functionality for the Magiclock device from within the user preferences. For Ableton Link, enable Link in Live and enable **Use Ableton Link** in Magiclock.

![screen shot 2016-06-18 at 20 48 27](https://cloud.githubusercontent.com/assets/72940/16173080/63252bf2-3596-11e6-9c43-cff0b5e8e557.png)

### Bitwig

In Bitwig you have to manually add a "Generic MIDI Clock Transmitter" device and then select __Magiclock__ from the output devices list.

![](https://cloud.githubusercontent.com/assets/72940/16177257/f28dfce8-3626-11e6-878e-e427966dbcc9.png)

### External Devices / MIDI Patchbay

You can use the [MIDI Patch bay app](http://notahat.com/midi_patchbay/) to route MIDI clock events from any device to the __magiclock__ virtual MIDI Output Device. Filter the input for clock events only as shown in the screen shot:

![screen shot 2016-06-19 at 14 41 28](https://cloud.githubusercontent.com/assets/72940/16177393/ff662d32-362b-11e6-978e-faff9e2920e4.png)

## FAQ

- **Q**: Can you support [Ableton Link](https://www.ableton.com/en/link/) so that the magiclock can also align beats?

  **A**: Yes. Enable **Use Ableton Link** from the Magiclock menu.

- **Q**: If you connect multiple devices to magiclock and set up a high BPM, my trackpad goes crazy!

  **A**: Yes, you should not do that. Currently magiclock does not prevent the trackpad from triggering too many haptic events. While this does not cause any damage, [Apples states in their API documentation](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSHapticFeedbackPerformer_protocol/index.html#//apple_ref/occ/intf/NSHapticFeedbackPerformer):

  > Haptic feedback is intended to be provided in response to a user action, such as aligning one object to another. Do not use it to provide feedback for events that are not user initiated. Excessive or unnecessary haptic feedback could be interpreted by the user as a malfunction and could encourage the user to disable haptic feedback entirely.

- **Q**: Can you make the haptic feedback stronger? I don't feel it.

  **A**: AppKit does not expose true force control. Magiclock can simulate a stronger first beat with the **Downbeat Accent** menu.

## Contributors

Thanks to [Patrici-o](https://github.com/patrici-o) for beta testings.

## License

Magiclock is distributed under the GNU General Public License version 2 or later.

Ableton Link source is vendored under `Vendor/AbletonLink`. Ableton Link is dual licensed under GPLv2+ or a proprietary license from Ableton; this repository uses the GPLv2+ path. See `Vendor/AbletonLink/LICENSE.md` and `Vendor/AbletonLink/GNU-GPL-v2.0.md`.
