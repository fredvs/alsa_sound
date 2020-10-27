program alsa_sound_test;

uses
alsa_sound;

begin
{ function ALSAbeep1: Boolean; } // beep at 660 HZ, mono, 100 ms, 75 % volume
ALSAbeep1;

{ function ALSAbeep2: Boolean; } // beep at 440 HZ, mono, 100 ms, 75 % volume
ALSAbeep2;  

{ function ALSAbeep3: Boolean; } // beep at 220 HZ, mono, 100 ms, 75 % volume
ALSAbeep3;  

{ function ALSAglide(StartFreq, EndFreq, Duration, Volume: integer;
  CloseLib : boolean): Boolean; }
ALSAglide(20, 880, 500, 75, false); 
ALSAglide(880, 20, 500, 75, false); 

{ function ALSAbeep(Frequency, Duration, Volume: integer; Warble: Boolean; 
  CloseLib: boolean): Boolean; }
ALSAbeep(880, 100, 75, false, false);   
ALSAbeep(840, 100, 75, false, false);

{ function ALSAbeepStereo(Frequency1, Frequency2, Duration,
  Volume1, Volume2: integer; warble: Boolean; CloseLib : boolean): Boolean; }
ALSAbeepStereo(440, 660, 1000, 75, 50, false, true); // CloseLib = true to close the library
end.
