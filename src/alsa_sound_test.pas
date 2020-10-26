program alsa_sound_test;

uses
alsa_sound;

begin
ALSAglide(20, 880, 500, 75); 
ALSAglide(880, 20, 500, 75); 
ALSAbeep(880, 100, 75, false);   
ALSAbeep(880, 100, 75, true);
end.
