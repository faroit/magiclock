# Magiclock

[![Build Status](https://travis-ci.org/faroit/magiclock.svg?branch=master)](https://travis-ci.org/faroit/magiclock)

Ever found the beepy metronome in your DAW annoying while producing music? Now you can turn off of the metronome and feel the beat on you trackpad. __Magiclock__ is an OS X app that uses haptic feedback (also called Taptic Engine™) to give you the MIDI clock beat within your Magic Trackpad.

## Features

![out](https://cloud.githubusercontent.com/assets/72940/16177370/e492626a-362a-11e6-9f66-2291040f98c1.gif)

* Magiclock is a menu-bar-only app that
receives MIDI Clock events and performs haptic feedback every beat/quarter note.
* For convenience, it also calculates the BPM and shows the results in the menu bar (can be switched off).
* To align the MIDI clock to quarter notes, the MIDI start and stop events are used.
* It provides a virtual MIDI Output port called "Magiclock" that can be connected to and from anywhere inside Mac OS X.

## Requirements

* OS X 10.11 El Capitan and later.
* Force Touch trackpad (2013 Macbook Pro, New Macbook, [Magic Trackpad 2](http://www.apple.com/magic-accessories/))
* MIDI clock output from DAW or hardware MIDI device


## Download/Installation

[Download the zip](https://github.com/faroit/magiclock/releases/download/v0.1/magiclock.zip) and launch __magiclock.app__. Be aware, that this app is not signed, so you might need to adjust your [security settings](https://support.apple.com/kb/PH18657?locale=en_US) Drag the app into your Applications folder, if you like.


## Usage

### Ableton Live

To use __magiclock__ with Ableton, just activate the sync functionality for the Magiclock device from within the user preferences.

![screen shot 2016-06-18 at 20 48 27](https://cloud.githubusercontent.com/assets/72940/16173080/63252bf2-3596-11e6-9c43-cff0b5e8e557.png)

### Bitwig

In Bitwig you have to manually add a "Generic MIDI Clock Transmitter" device and then select __Magiclock__ from the output devices list.

![](https://cloud.githubusercontent.com/assets/72940/16177257/f28dfce8-3626-11e6-878e-e427966dbcc9.png)

### External Devices / MIDI Patchbay

You can use the [MIDI Patch bay app](http://notahat.com/midi_patchbay/) to route MIDI clock events from any device to the __magiclock__ virtual MIDI Output Device. Filter the input for clock events only as shown in the screen shot:

![screen shot 2016-06-19 at 14 41 28](https://cloud.githubusercontent.com/assets/72940/16177393/ff662d32-362b-11e6-978e-faff9e2920e4.png)

## FAQ

- **Q**: Can you support [Ableton Link](https://www.ableton.com/en/link/) so that the magiclock can also align beats?

  **A**: For now [Ableton only supports iOS](http://ableton.github.io/linkkit), so there is no (legal) way to add Link support.

- **Q**: If you connect multiple devices to magiclock and set up a high BPM, my trackpad goes crazy!

  **A**: Yes, you should not do that. Currently magiclock does not prevent the trackpad from triggering too many haptic events. While this does not cause any damage, [Apples states in their API documentation](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSHapticFeedbackPerformer_protocol/index.html#//apple_ref/occ/intf/NSHapticFeedbackPerformer):

  > Haptic feedback is intended to be provided in response to a user action, such as aligning one object to another. Do not use it to provide feedback for events that are not user initiated. Excessive or unnecessary haptic feedback could be interpreted by the user as a malfunction and could encourage the user to disable haptic feedback entirely.

- **Q**: Can you make the haptic feedback stronger? I don't feel it.

  **A**: Unfortunately, no. Even though there are multiple levels of pressure the trackpad can sense, there is only [one type of haptic feedback](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSHapticFeedbackPerformer_protocol/index.html#//apple_ref/occ/intf/NSHapticFeedbackPerformer) which is a simple __tap__. Maybe this will change in the future, so that it would be possible to differentiate offbeats from onbeats.

## Contributors

Thanks to [Patrici-o](https://github.com/patrici-o) for beta testings.

## License

MIT License
