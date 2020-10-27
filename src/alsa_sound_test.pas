program alsa_sound_test;

uses
alsa_sound;

begin
{ function ALSAglide(StartFreq, EndFreq, Duration, Volume: integer;
  CloseLib : boolean): Boolean; }
ALSAglide(20, 880, 500, 75, false); 
ALSAglide(880, 20, 500, 75, false); 

{ function ALSAbeep(Frequency, Duration, Volume: integer; Warble: Boolean; 
  CloseLib: boolean): Boolean; }
ALSAbeep(880, 100, 75, false, false);   
ALSAbeep(840, 100, 75, true, false);

{ function ALSAbeepStereo(Frequency1, Frequency2, Duration,
  Volume1, Volume2: integer; warble: Boolean; CloseLib : boolean): Boolean; }
ALSAbeepStereo(440, 660, 1000, 75, 50, false, true); // CloseLib = true to close the library
end.
