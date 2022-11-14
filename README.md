# BBC Micro SquatM 1-bit Beeper Engine Player

- SquatM beeper music engine
- Originally written by Shiru 06'17 for ZX Spectrum 48K
- Ported to Atari 8-bit by Shiru 07'21
- Ported to the BBC Micro by Negative Charge 11'22

The track currently needs to be included at the bottom of main.6502 (samples are in the tracks directory)

SquatM tracks can be composed in 1Tracker (https://shiru.untergrund.net/software.shtml) - you will need to export the track in Atari ca65 format, and manually convert to BeebAsm format (see samples for changes required).

This still needs heavily optimizing.  It does not play back at full speed at present.

SSD file for emulators/hardware: https://github.com/NegativeCharge/ca65-SquatM-Player/blob/master/SquatM_Beeper_Engine.ssd?raw=true

**NOTE:**

Release Notes:

- v0.1 - Initial BeebAsm port
