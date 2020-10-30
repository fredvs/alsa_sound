program alsa_sound_test;

uses
  alsa_sound;
  
  
begin
{ function ALSAbeep1: Boolean; }// beep at 660 HZ, mono, 100 ms, 75 % volume
  ALSAbeep1;

{ function ALSAbeep2: Boolean; }// beep at 440 HZ, mono, 100 ms, 75 % volume
  ALSAbeep2;

{ function ALSAbeep3: Boolean; }// beep at 220 HZ, mono, 100 ms, 75 % volume
  ALSAbeep3;

{ function ALSAglide(StartFreq, EndFreq, Duration, Volume: integer;
  CloseLib : boolean): Boolean; }
  ALSAglide(20, 880, 500, 75, False);
  ALSAglide(880, 20, 500, 75, False);

{ function ALSAbeep(Frequency, Duration, Volume: integer; Warble: Boolean; 
  CloseLib: boolean): Boolean; }
  ALSAbeep(880, 100, 75, False, False);
  ALSAbeep(840, 100, 75, False, False);

{ function ALSAbeepStereo(Frequency1, Frequency2, Duration,
  Volume1, Volume2: integer; warble: Boolean; CloseLib : boolean): Boolean; }
  ALSAbeepStereo(440, 660, 750, 75, 50, False, False);

{ function ALSApolice(BaseFreq,duration, volume: integer; speed: single; CloseLib: boolean): Boolean; }
  ALSApolice(440, 3000, 100, 0.5, True); // CloseLib = true to close the library
end.

