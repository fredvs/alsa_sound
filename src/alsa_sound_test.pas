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
ALSAbeep(840, 100, 75, true, true);
end.
