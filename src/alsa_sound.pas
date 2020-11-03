// Original ALSAbeep() from beeper.inc by
// Robert Rozee, 30-April-2020
// <rozee@mail.com>
 
// The ALSA types, constants and functions
// are copied from pwm.inc of fpAlsa by
// Nikolay Nikolov <nickysn@users.sourceforge.net>

// Turned into unit and dynamic loading by
// Fred vS <fiens@hotmail.com>
 
// ALSAbeep by Robert Rozee.
// ALSAbeepstereo by Fred vS.
// ALSAbeepflanger by Winni
// ALSAglide by Winni.
// ALSApolice by Winni.
// ALSAambulance by Winni.
// ALSAswissbus by Winni.
// ALSAmexicantruck by Winni
 
unit alsa_sound;

{$mode objfpc}{$H+}
{$PACKRECORDS C}

interface

uses
  dynlibs,
  CTypes;

function ALSAbeep(frequency, duration, volume: cint; warble: Boolean;
WaveType: cint; CloseLib : boolean): Boolean; // WaveType: 0=sine, 1=square, 2=tooth

function ALSAbeep1: Boolean; // fixed beep at 660 HZ, mono, 100 ms, 75 % volume
function ALSAbeep2: Boolean; // fixed beep at 440 HZ, mono, 100 ms, 75 % volume
function ALSAbeep3: Boolean; // fixed beep at 220 HZ, mono, 100 ms, 75 % volume

function ALSAbeepstereo(Frequency1, Frequency2, Duration, Volume1, Volume2: cint;
 warble: Boolean; WaveType: cint; CloseLib : boolean): Boolean; // WaveType: 0=sine, 1=square, 2=tooth

function ALSAbeepflanger(Frequency,  Duration, Volume : cint;
 warble: Boolean; WaveType: cint; CloseLib : boolean): Boolean;

function ALSAglide(StartFreq,EndFreq, duration, volume: cint; CloseLib: boolean): Boolean;

function ALSApolice(BaseFreq,duration, volume: cint; speed: cfloat; CloseLib: boolean): Boolean;

function ALSAsilence(milliseconds: Cardinal;  CloseLib: boolean): boolean;

function ALSAambulance(loop, volume: integer; CloseLib: boolean): boolean;

function ALSAswissbus(loop,volume: integer; CloseLib: boolean): boolean;

function AlSAmexicantruck(Loop, Volume: Integer; CloseLib: boolean): boolean;

implementation

type
  // Signed frames quantity
  snd_pcm_sframes_t = cint;

  // PCM handle
  PPsnd_pcm_t = ^Psnd_pcm_t;
  Psnd_pcm_t  = Pointer;

  // PCM stream (direction) 
  snd_pcm_stream_t = cint;

  // PCM sample format
  snd_pcm_format_t = cint;

  // PCM access type
  snd_pcm_access_t = cint;

  // Unsigned frames quantity
  snd_pcm_uframes_t = cuint;
  
const
  // Playback stream
  SND_PCM_STREAM_PLAYBACK: snd_pcm_stream_t = 0;

  // Unsigned 8 bit
  SND_PCM_FORMAT_U8: snd_pcm_format_t       = 1;

  // snd_pcm_readi/snd_pcm_writei access
  SND_PCM_ACCESS_RW_INTERLEAVED: snd_pcm_access_t = 3;
  
// Dynamic load : Vars that will hold our dynamically loaded ALSA methods...
var
  snd_pcm_open: function(pcm: PPsnd_pcm_t; Name: PChar; stream: snd_pcm_stream_t; mode: cint): cint; cdecl;

  snd_pcm_set_params: function(pcm: Psnd_pcm_t; format: snd_pcm_format_t; access: snd_pcm_access_t; channels, rate: cuint; soft_resample: cint; latency: cuint): cint; cdecl;

  snd_pcm_writei: function(pcm: Psnd_pcm_t; buffer: Pointer; size: snd_pcm_uframes_t): snd_pcm_sframes_t; cdecl;

  snd_pcm_recover: function(pcm: Psnd_pcm_t; err, silent: cint): cint; cdecl;

  snd_pcm_drain: function(pcm: Psnd_pcm_t): cint; cdecl;

  snd_pcm_close: function(pcm: Psnd_pcm_t): cint; cdecl;

// Special function for dynamic loading of lib ...
  as_Handle: TLibHandle = dynlibs.NilHandle; // this will hold our handle for the lib

  ReferenceCounter: integer = 0;  // Reference counter
  
type TAr360 =  array[0..359] of shortint;

procedure SetWave (var SA: TAr360; WaveType, Volume: integer); inline;
var i : integer;
begin
    if NOT (waveType in [0..2]) then waveType := 0;

         case WaveType of
      0: begin
          for I := 0 to 359 do
          SA[I] := round(sin(pi * I / 180.0) * volume);  // create sine wave pattern
         end;

      1: begin
          for I := 0 to 359 do
          if I < 180 then SA[i] := +1*volume else  SA[i] := -1* volume;//  sqare wave
         end;

      2: begin
          for I := 0 to 359 do
          SA[i] := (round((360 - i)/180) -1)*volume;   //   saw tooth wave
         end;
      end;
end;
  
function Max(a, b: cint): cint; inline;
begin
if a > b then
    Result := a
  else
    Result := b;
end;

function EnsureFreq(const AValue: cint): cint; inline;
begin
  Result:=abs(AValue);
  If Result<20 then
    Result:=20;
  if Result>20000 then
    Result:=20000;
end;

function EnsureSpeed(const AValue: cfloat): cfloat; inline;
begin
 result := abs(AValue);
 if result < 0.1 then result := 0.1
end;

function EnsureDuration(const AValue: cint): cint; inline;
begin
 result := abs(AValue);
 if result < 50 then result := 50;
end;

function EnsureVolume(const AValue: cint): cint; inline;
begin
 result := AValue;
 if result < 0 then result := 0
 else if result > 100 then result := 100;
end;

function EnsureLoop(const AValue: cint): cint; inline;
begin
 result := AValue;
 if result < 1 then result := 1;
end;

function EnsureWave(const AValue: cint): cint; inline;
begin
 result := AValue;
 if result < 0 then result := 0
 else if result > 2 then result := 0;
end;

function as_IsLoaded: Boolean;
begin
  Result := (as_Handle <> dynlibs.NilHandle);
end;

function as_Load: Boolean; // load the lib
var
  thelib: string = 'libasound.so.2';
begin
  Result := False;
  if as_Handle <> dynlibs.NilHandle then // is it already there ?
  begin
    Inc(ReferenceCounter);
    Result := True; 
  end
  else
  begin // go & load the library
    as_Handle := DynLibs.SafeLoadLibrary(thelib); // obtain the handle we want
    if as_Handle <> DynLibs.NilHandle then
    begin // now we tie the functions to the VARs from above

      Pointer(snd_pcm_open)       := DynLibs.GetProcedureAddress(as_Handle, PChar('snd_pcm_open'));
      Pointer(snd_pcm_set_params) := DynLibs.GetProcedureAddress(as_Handle, PChar('snd_pcm_set_params'));
      Pointer(snd_pcm_writei)     := DynLibs.GetProcedureAddress(as_Handle, PChar('snd_pcm_writei'));
      Pointer(snd_pcm_recover)    := DynLibs.GetProcedureAddress(as_Handle, PChar('snd_pcm_recover'));
      Pointer(snd_pcm_drain)      := DynLibs.GetProcedureAddress(as_Handle, PChar('snd_pcm_drain'));
      Pointer(snd_pcm_close)      := DynLibs.GetProcedureAddress(as_Handle, PChar('snd_pcm_close'));

      Result           := as_IsLoaded;
      ReferenceCounter := 1;
    end;
  end;
end;

procedure as_Unload();
begin
  // < Reference counting
  if ReferenceCounter > 0 then
    Dec(ReferenceCounter);
  if ReferenceCounter < 0 then
    Exit;
  // >
  if as_IsLoaded then
  begin
    DynLibs.UnloadLibrary(as_Handle);
    as_Handle := DynLibs.NilHandle;
  end;
end;

// ALSA methods:

function ALSApolice(BaseFreq,duration,volume: cint; speed: cfloat; CloseLib: boolean): Boolean;
var
  buffer: array[0..9600 - 1] of byte;
  frames: snd_pcm_sframes_t;    
  pcm: PPsnd_pcm_t;
  I, FC: cint;
  SA: array[0..359] of shortint;
const
  device = 'default' + #0; // name of sound device
var
  count1, count2, N, X: cint;
  DeltaStep: cfloat;   //winni
  delta : cint;     //  "
  PeakFreq: cint;   // "
  upDown  : cint;   // "
begin
  Result := False;
 
  as_Load;
 
  if snd_pcm_open(@pcm, @device[1], SND_PCM_STREAM_PLAYBACK, 0) = 0 then
    if snd_pcm_set_params(pcm, SND_PCM_FORMAT_U8,
      SND_PCM_ACCESS_RW_INTERLEAVED,
      1,                        // number of channels
      48000,                    // sample rate (Hz)
      1,                        // resampling on/off
      500000) = 0 then          // latency (us)
    begin
      Result := True;
      BaseFreq:= EnsureFreq(BaseFreq);
      PeakFreq := round (BaseFreq * 4/3); //fourth - most used in signal horns
      speed := EnsureSpeed(speed); // avoid div by zero
      speed := 1/speed *2400;
      duration := EnsureDuration(duration);
      volume   := EnsureVolume(Volume);
      // 48 samples per ms -->
      // 360 / 48 = 7.5
      upDown := 400; // ms interval
      DeltaStep := 7.5*(PeakFreq - BaseFreq) /upDown;
      SetWave(SA,2,volume);

      X       := 0;
      N       := 0;          // up/down counter used by unequal interval division
 
       count1 := 0;             // count1 counts up, count2 counts down
      count2 := duration * 48;  // (at 48000Hz there are 48 samples per ms)
 
      while count2 > 0 do           // start making sound!
      begin
        FC    := 0;
        for I := 0 to sizeof(buffer) - 1 do    // fill buffer with samples
        begin
          if count2 > 0 then
          begin
            if count1 < 480 then
              buffer[I] := 128 + ((count1 * SA[X]) div 480)
            else   // 10ms feather in
            if count2 < 480 then
              buffer[I] := 128 + ((count2 * SA[X]) div 480)
            else   // 10ms feather out
              buffer[I] := 128 + SA[X];
            Inc(FC);
          end
          else
          begin
            buffer[I] := 128;   // no signal on trailing end of buffer, just in case
            if (FC mod 2400) <> 0 then
              Inc(FC);       // keep increasing FC until is a multiple of 2400
          end;
 
         delta := round (sin(Count1/speed)*DeltaStep*upDown*48/2);   // winni
         Inc(N,BaseFreq*360+Delta);          // winni
          while (N > 0) do
          begin                // (a variation on Bresenham's Algorithm)
            Dec(N, 48000);
            Inc(X);
          end;
          X := X mod 360;
 
          Inc(count1);
          Dec(count2);
        end;
 
        frames   := snd_pcm_writei(pcm, @buffer, max(2400, FC)); // write AT LEAST one full period
        if frames < 0 then
          frames := snd_pcm_recover(pcm, frames, 0); // try to recover from any error
        if frames < 0 then
          break;                               // give up if failed to recover
      end;
      snd_pcm_drain(pcm);                      // drain any remaining samples
      snd_pcm_close(pcm);
    end;
    if CloseLib then as_unload;  // Unload library if param CloseLib is true
 end; //AlsaPolice

function ALSAglide(StartFreq,EndFreq, duration, volume: cint; CloseLib: boolean): Boolean;
    var
      buffer: array[0..9600 - 1] of byte; // 1/5th second worth of samples @48000Hz
      frames: snd_pcm_sframes_t;   // number of frames written (negative if an error occurred)
      pcm: PPsnd_pcm_t;            // sound device handle
      I, FC: cint;
      SA: array[0..359] of shortint;  // array of sine wave values for a single cycle
    const
      device = 'default' + #0;        // name of sound device
    var
      count1, count2, N, X: cint;
      DeltaStep: cfloat;   //winni
      delta : cint;     //  "
    begin
      Result := False;
     
      as_Load;     // load the library
     
      if snd_pcm_open(@pcm, @device[1], SND_PCM_STREAM_PLAYBACK, 0) = 0 then
        if snd_pcm_set_params(pcm, SND_PCM_FORMAT_U8,
          SND_PCM_ACCESS_RW_INTERLEAVED,
          1,                  // number of channels
          48000,              // sample rate (Hz)
          1,                  // resampling on/off
          500000) = 0 then    // latency (us)
        begin
          Result := True;
         
          StartFreq:= EnsureFreq(StartFreq);
          EndFreq  := EnsureFreq(EndFreq);
          duration := EnsureDuration(duration);
          volume   := EnsureVolume(Volume);
                       
          // 48 samples per ms -->
          // 360 / 48 = 7.5
          DeltaStep := 7.5*(EndFreq - startFreq) /(duration);   // winni
          SetWave(SA,2,volume);

          for I := 0 to 359 do
            SA[I] := round(sin(pi * I / 180.0) * volume); // create sine wave pattern
    
          X       := 0;
          N       := 0;   // up/down counter used by unequal interval division
     
          count1 := 0;              // count1 counts up, count2 counts down
          count2 := duration * 48;  // (at 48000Hz there are 48 samples per ms)
     
          while count2 > 0 do              // start making sound!
          begin
            FC    := 0;
            for I := 0 to sizeof(buffer) - 1 do   // fill buffer with samples
            begin
              if count2 > 0 then
              begin
                if count1 < 480 then
                  buffer[I] := 128 + ((count1 * SA[X]) div 480)
                else   // 10ms feather in
                if count2 < 480 then
                  buffer[I] := 128 + ((count2 * SA[X]) div 480)
                else   // 10ms feather out
                  buffer[I] := 128 + SA[X];
                Inc(FC);
              end
              else
              begin
                buffer[I] := 128;  // no signal on trailing end of buffer, just in case
                if (FC mod 2400) <> 0 then
                  Inc(FC);   // keep increasing FC until is a multiple of 2400
              end;
     
             delta := round (Count1*DeltaStep);   // winni
             Inc(N,StartFreq*360+Delta);          // winni
              while (N > 0) do
              begin                  // (a variation on Bresenham's Algorithm)
                Dec(N, 48000);
                Inc(X);
              end;
              X := X mod 360;
     
              Inc(count1);
              Dec(count2);
            end;
            
          frames   := snd_pcm_writei(pcm, @buffer, max(2400,FC)); // write AT LEAST one full period
      
            if frames < 0 then
              frames := snd_pcm_recover(pcm, frames, 0); // try to recover from any error
            if frames < 0 then
              break;                            // give up if failed to recover
          end;
          snd_pcm_drain(pcm);                   // drain any remaining samples
          snd_pcm_close(pcm);
        end;
        if CloseLib then as_unload;  // Unload library if param CloseLib is true
    end; //AlsaGlide

function ALSAbeep(frequency, duration, volume: cint; warble: Boolean;
 WaveType: cint; CloseLib : boolean): Boolean;
var
  buffer: array[0..(9600) - 1] of byte;  // 1/5th second worth of samples @48000Hz
 frames: snd_pcm_sframes_t;           // number of frames written (negative if an error occurred)
  pcm: PPsnd_pcm_t;                    // sound device handle
  I, FC: cint;
  SA: array[0..359] of shortint;       // array of sine wave values for a single cycle

 const
  device = 'default' + #0;             // name of sound device
var
  count1, count2, N, X: cint;
begin
  Result := False;

  as_Load;       // load the library

  if snd_pcm_open(@pcm, @device[1], SND_PCM_STREAM_PLAYBACK, 0) = 0 then
    if snd_pcm_set_params(pcm, SND_PCM_FORMAT_U8,
      SND_PCM_ACCESS_RW_INTERLEAVED,
      1,                        // number of channels
      48000,                    // sample rate (Hz)
      1,                        // resampling on/off
      500000) = 0 then            // latency (us)
    begin
      Result := True;
    
      frequency:= EnsureFreq(frequency);
      duration := EnsureDuration(duration);
      volume   := EnsureVolume(Volume);

      SetWave(SA,WaveType, volume);

      X       := 0;
      N       := 0;       // up/down counter used by unequal interval division

      count1 := 0;        // count1 counts up, count2 counts down
      count2 := duration * 48;     // (at 48000Hz there are 48 samples per ms)

      while count2 > 0 do       // start making sound!
      begin
        FC    := 0;
        for I := 0 to sizeof(buffer) - 1 do   // fill buffer with samples
        begin
          if count2 > 0 then
          begin
            if count1 < 480 then
              buffer[I] := 128 + ((count1 * SA[X]) div 480)
            else   // 10ms feather in
            if count2 < 480 then
              buffer[I] := 128 + ((count2 * SA[X]) div 480)
            else   // 10ms feather out
              buffer[I] := 128 + SA[X];
            if warble and odd(count1 div 120) then
              buffer[I] := 128;              // 200Hz warble
            Inc(FC);
          end
          else
          begin
            buffer[I] := 128;  // no signal on trailing end of buffer, just in case
            if (FC mod 2400) <> 0 then
              Inc(FC);        // keep increasing FC until is a multiple of 2400
          end;

          Inc(N, frequency * 360); // unequal interval division routine
          while (N > 0) do
          begin                    // (a variation on Bresenham's Algorithm)
            Dec(N, 48000);
            Inc(X);
          end;
          X := X mod 360;

          Inc(count1);
          Dec(count2);
        end; 
        
        frames   := snd_pcm_writei(pcm, @buffer, max(2400,FC)); // write AT LEAST one full period
    
        if frames < 0 then
          frames := snd_pcm_recover(pcm, frames, 0); // try to recover from any error
        if frames < 0 then
          break;                        // give up if failed to recover
      end;
      snd_pcm_drain(pcm);              // drain any remaining samples
      snd_pcm_close(pcm);
    end;
   if CloseLib then as_unload;  // Unload library if param CloseLib is true
end; // ALSAbeep

function ALSAbeep1: Boolean; // beep at 660 HZ, mono, 100 ms, 75 % volume
begin
result := ALSAbeep(660, 100, 75, false, 0, true);
end;

function ALSAbeep2: Boolean; // beep at 440 HZ, mono, 100 ms, 75 % volume
begin
result := ALSAbeep(440, 100, 75, false, 0, true);
end;

function ALSAbeep3: Boolean; // beep at 220 HZ, mono, 100 ms, 75 % volume
begin
result := ALSAbeep(220, 100, 75, false, 0, true);
end;

function ALSAsilence(milliseconds: Cardinal;  CloseLib: boolean): boolean;
begin
result := ALSAbeep(20, milliseconds, 0, false, 0, CloseLib);
end;

function ALSAambulance(loop, volume: integer; CloseLib: boolean): boolean;
// By Winni: Germany ambulace, fire brigade, police 
// 440 Hz und 585 Hz: a1 - d2  
var
x : integer;
begin
  result := true;
  for x:= 1 to  EnsureLoop(loop) do
   begin
   if not ALSAbeep(440,400,volume,false, 2, False) then result := false;
   if not AlsaBeep(585,400,volume,false, 2, false) then result := false;
   end;
  if CloseLib then as_unload;
end;   

function ALSAswissbus(loop, volume: integer; CloseLib: boolean): boolean;
// By Winni: Swiss mountain bus
// cis'–e–a :   277.183  164.814  220.000
var
x : integer;
begin
  result := true;
  for x:= 1 to  EnsureLoop(loop) do
   begin
   if not ALSAbeep(277,400,volume,false, 2, False) then result := false;
   if not AlsaBeep(165, 400,volume,false, 2, False) then result := false;
   if not AlsaBeep(220, 400,volume,false, 2, False) then result := false;
   if not ALSAsilence(200, false) then result := false;
   end;
  if CloseLib then as_unload;
end;   


function ALSAbeepFlanger(Frequency,  Duration, Volume: cint;
 warble: Boolean; WaveType: cint; CloseLib : boolean): Boolean;
var
  buffer: array[0..(9600*2) - 1] of byte;  // 1/5th second worth of samples @48000Hz
  frames: snd_pcm_sframes_t;           // number of frames written (negative if an error occurred)
  pcm: PPsnd_pcm_t;                    // sound device handle
  I, FC: cint;
  SA, SA2: array[0..359] of shortint;       // array of sine wave values for a single cycle
const
  device = 'default' + #0;             // name of sound device
var
  count1, count2, N, N2, X, X2: cint;
  Frequency2: integer;
begin
  Result := False;
   as_Load;       // load the library

  if snd_pcm_open(@pcm, @device[1], SND_PCM_STREAM_PLAYBACK, 0) = 0 then
    if snd_pcm_set_params(pcm, SND_PCM_FORMAT_U8,
      SND_PCM_ACCESS_RW_INTERLEAVED,
      2,                        // number of channels
      48000,                    // sample rate (Hz)
      1,                        // resampling on/off
      500000) = 0 then            // latency (us)
    begin
      Result := True;

       frequency:= EnsureFreq(frequency);
        volume   := EnsureVolume(Volume);
        duration := EnsureDuration(duration);
        WaveType := EnsureWave(WaveType);

      SetWave(SA,WaveType, volume);
      SetWave(SA2,WaveType, volume);

      X       := 0;
      N       := 0;       // up/down counter used by unequal interval division

      X2       := 0;   // stereo
      N2       := 0;

      count1 := 0;        // count1 counts up, count2 counts down
      count2 := duration * 48;     // (at 48000Hz there are 48 samples per ms)

      while count2 > 0 do       // start making sound!
      begin
        FC    := 0;
        I    := 0;
        while I < sizeof(buffer) do
        begin
          if count2 > 0 then
          begin
            if count1 < 480 then
            begin
           buffer[I] := 128 + ((count1 * SA[X]) div 480);
           buffer[I+1] := 128 + ((count1 * SA2[X2]) div 480);
            end
            else   // 10ms feather in
            if count2 < 480 then
            begin
            buffer[I] := 128 + ((count2 * SA[X]) div 480);
            buffer[I+1] := 128 + ((count2 * SA2[X2]) div 480);
            end
            else   // 10ms feather out
            begin
              buffer[I] := 128 + (SA[X]);
              buffer[I+1] := 128 + (SA2[X2]);
            end;
            if warble and odd(count1 div 120) then
            begin
            buffer[I] := 128;              // 200Hz warble
            buffer[I+1] := 128;
            end;
            Inc(FC);
          end
          else
          begin
            buffer[I] := 128;  // no signal on trailing end of buffer, just in case
            buffer[I+1] := 128;
            if (FC mod 2400) <> 0 then
              Inc(FC);        // keep increasing FC until is a multiple of 2400
          end;

          Inc(N, frequency * 360); // unequal interval division routine
          while (N > 0) do
          begin                    // (a variation on Bresenham's Algorithm)
            Dec(N, 48000);
            Inc(X);
          end;
          X := X mod 360;

          frequency2 := round(frequency + frequency*( 0.5 )*sin((count1*9600+i)/960 *pi/180) );
          Inc(N2, (frequency2 ) * 360); // unequal interval division routine
          while (N2 > 0) do
          begin                    // (a variation on Bresenham's Algorithm)
            Dec(N2, 48000);
            Inc(X2);
          end;
          X2 := X2 mod 360;

          Inc(count1);
          Dec(count2);

          inc(I,2);
        end; // I

       frames   := snd_pcm_writei(pcm, @buffer,max(2400,FC)); // write AT LEAST one full period

        if frames < 0 then
          frames := snd_pcm_recover(pcm, frames, 0); // try to recover from any error
        if frames < 0 then
          break;                        // give up if failed to recover
      end;
      snd_pcm_drain(pcm);              // drain any remaining samples
      snd_pcm_close(pcm);
    end;
   if CloseLib then as_unload;  // Unload library if param CloseLib is true
end; // ALSAbeepFlanger

function ALSAbeepStereo(Frequency1, Frequency2, Duration, Volume1, Volume2: cint;
 warble: Boolean; WaveType: cint; CloseLib : boolean): Boolean;
var
  buffer: array[0..(9600*2) - 1] of byte;  // 1/5th second worth of samples @48000Hz
  frames: snd_pcm_sframes_t;           // number of frames written (negative if an error occurred)
  pcm: PPsnd_pcm_t;                    // sound device handle
  I, FC: cint;
  SA, SA2: array[0..359] of shortint;       // array of sine wave values for a single cycle
const
  device = 'default' + #0;             // name of sound device
var
  count1, count2, N, N2, X, X2: cint;
begin
  Result := False;

  as_Load;       // load the library

  if snd_pcm_open(@pcm, @device[1], SND_PCM_STREAM_PLAYBACK, 0) = 0 then
    if snd_pcm_set_params(pcm, SND_PCM_FORMAT_U8,
      SND_PCM_ACCESS_RW_INTERLEAVED,
      2,                        // number of channels
      48000,                    // sample rate (Hz)
      1,                        // resampling on/off
      500000) = 0 then            // latency (us)
    begin
      Result := True;
  
        frequency1:= EnsureFreq(frequency1); 
        volume1   := EnsureVolume(Volume1);
        frequency2:= EnsureFreq(frequency2); 
        volume2   := EnsureVolume(Volume2);
        duration := EnsureDuration(duration);
        WaveType := EnsureWave(WaveType);

        SetWave(SA,WaveType, Volume1);
        SetWave(SA2,WaveType,Volume2);

      X       := 0;
      N       := 0;       // up/down counter used by unequal interval division
                             
      X2       := 0;   // stereo
      N2       := 0; 

      count1 := 0;        // count1 counts up, count2 counts down
      count2 := duration * 48;     // (at 48000Hz there are 48 samples per ms)

      while count2 > 0 do       // start making sound!
      begin
        FC    := 0;
        I    := 0;
        while I < sizeof(buffer) do
        begin
          if count2 > 0 then
          begin
            if count1 < 480 then
            begin
           buffer[I] := 128 + ((count1 * SA[X]) div 480);
           buffer[I+1] := 128 + ((count1 * SA2[X2]) div 480);
            end  
            else   // 10ms feather in
            if count2 < 480 then
            begin
            buffer[I] := 128 + ((count2 * SA[X]) div 480);
            buffer[I+1] := 128 + ((count2 * SA2[X2]) div 480);
            end  
            else   // 10ms feather out
            begin
              buffer[I] := 128 + (SA[X]);
              buffer[I+1] := 128 + (SA2[X2]);
            end;  
            if warble and odd(count1 div 120) then
            begin
            buffer[I] := 128;              // 200Hz warble
            buffer[I+1] := 128;
            end;
            Inc(FC);
          end
          else
          begin
            buffer[I] := 128;  // no signal on trailing end of buffer, just in case
            buffer[I+1] := 128;
            if (FC mod 2400) <> 0 then
              Inc(FC);        // keep increasing FC until is a multiple of 2400
          end;

          Inc(N, frequency1 * 360); // unequal interval division routine
          while (N > 0) do
          begin                    // (a variation on Bresenham's Algorithm)
            Dec(N, 48000);
            Inc(X);
          end;
          X := X mod 360;
          
           Inc(N2, (frequency2 div 2) * 360); // unequal interval division routine
          while (N2 > 0) do
          begin                    // (a variation on Bresenham's Algorithm)
            Dec(N2, 48000);
            Inc(X2);
          end;
          X2 := X2 mod 360;

          Inc(count1);
          Dec(count2);
          
          inc(I,2);
        end; 
        
       frames   := snd_pcm_writei(pcm, @buffer,max(2400,FC)); // write AT LEAST one full period
    
        if frames < 0 then
          frames := snd_pcm_recover(pcm, frames, 0); // try to recover from any error
        if frames < 0 then
          break;                        // give up if failed to recover
      end;
      snd_pcm_drain(pcm);              // drain any remaining samples
      snd_pcm_close(pcm);
    end;
   if CloseLib then as_unload;  // Unload library if param CloseLib is true
end; // ALSAbeepstereo

function ALSAmexicantruck(Loop, Volume: Integer; CloseLib: boolean): boolean;
const C= 262;
      F = 349;
      A = 440;
      EigthNote = 150;
var   i,k :integer;
     
begin
   // ||:  C/8 C/8 C/8 F/8*3 A/8*2  :||
   // https://www.free-notes.net/cgi-bin/noten_Song.pl?song=La+Cucaracha&profile=null&lang=de&db=Main
   result := true;
   for k := 1 to loop do
   begin
   for i := 1 to 3 do if not ALSAbeep(C, EigthNote, volume, false,2,false) then result := false;
   if not ALSAbeep(F, EigthNote*3, volume, false,2,false) then result := false;
   if not ALSAbeep(A, EigthNote*2, volume, false,2,false) then result := false;
   end;
   if CloseLib then as_unload;  // Unload library if param CloseLib is true
end;

finalization  // in case if library was not unloaded.
as_unload;

end.
