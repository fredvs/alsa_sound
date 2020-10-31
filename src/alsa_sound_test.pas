program alsa_sound_test;

uses
 sysutils, alsa_sound;
  
var
i : integer;  
  
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

// By Winni: Germany: ambulace, fire brigade, police 
// 440 Hz und 585 Hz: a1 - d2  
   for i := 1 to 3 do
   begin
   ALSAbeep(440,400,50,false, False);
   AlsaBeep(585,400,50,false, False);
   end;  

// By Winni: swiss mountain bus
// cis'–e–a :   277.183  164.814  220.000
   for i := 1 to 3 do
   begin
   ALSAbeep(277,400,50,false, False);
   AlsaBeep(165, 400,59,false, False);
   AlsaBeep(220, 400,50,false, False);
   sleep(100);
   end;   

{ function ALSAbeepStereo(Frequency1, Frequency2, Duration, Volume1, Volume2: cint;
 warble: Boolean; WaveType: cint; CloseLib : boolean): Boolean; } // WaveType: 0=sine, 1=square, 2=tooth 
  ALSAbeepStereo(440, 660, 750, 75, 50, False, 0, False);
 
{ function ALSApolice(BaseFreq,duration, volume: integer; speed: single; CloseLib: boolean): Boolean; }
  ALSApolice(440, 3000, 100, 0.5, True); // CloseLib = true to close the library
end.

