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
  ALSAglide(20, 880, 500, 50, False);
  ALSAglide(880, 20, 500, 50, False);

{ function ALSAbeep(Frequency, Duration, Volume: integer; Warble: Boolean; 
  CloseLib: boolean): Boolean; }
  ALSAbeep(880, 100, 50, False, False);
  ALSAbeep(840, 100, 50, False, False);

{ function ALSAsilence(milliseconds: Cardinal;  CloseLib: boolean): boolean; }
  ALSAsilence(200, false);  

{ function ALSAambulance(loop: integer; CloseLib: boolean): boolean; }
  ALSAambulance(2, false);
  
{ function ALSAswissbus(loop: integer; CloseLib: boolean): boolean; }
  ALSAswissbus(3, false);
 
{ function ALSAbeepStereo(Frequency1, Frequency2, Duration, Volume1, Volume2: cint;
 warble: Boolean; WaveType: cint; CloseLib : boolean): Boolean; } // WaveType: 0=sine, 1=square, 2=tooth 
  ALSAbeepStereo(440, 660, 1000, 75, 50, False, 0, False);
 
{ function ALSApolice(BaseFreq,duration, volume: integer; speed: single; CloseLib: boolean): Boolean; }
  ALSApolice(440, 3000, 75, 0.5, True); // CloseLib = true to close the library
end.

