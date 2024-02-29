function Time = BuildTimeGroup(Signals,name,Ts,units,description)

% BUILDTIMEGROUP - Build a time signal group.
% Time = BuildTimeGroup(Signals,name,Ts,units,description)
% Time = BuildTimeGroup(Signals,name,[t0,Ts],units,description)
% Time = BuildTimeGroup(Signals,name,t,units,description)
% Time = BuildTimeGroup(Signals,name,Time,units,description)
%
% Builds time signal group 'Time' corresponding to signal group 
% 'Signals'.  Input string 'name' specifies the time signal name, 
% scalar 'Ts' the sample time, string 'units' the time units, and 
% 'description' the description string.  For example, the command 
% "Time = BuildTimeGroup(Signals,'Time',0.5,'sec','Time vector')" 
% results in a time signal named 'Time' with 0.5-sec sampling and 
% description string 'Time vector'.  As an alternative, a 2-vector 
% [t0,Ts] defining start time 't0' and sample time 'Ts',or an 
% appropriately sized time vector ('t' signifying elapsed time 
% or 'Time' designating absolute time), may be specified in place 
% of 'Ts'.  All name layers in 'Signals' are represented in the 
% result. 
%
% P.G. Bonanni
% 2/28/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'Signals' input
[flag,valid,errmsg] = IsSignalGroup(Signals);
if ~flag
  error('Input #1 is not a signal group: %s',errmsg)
elseif ~valid
  error('Input #1 is not a valid signal group: %s  See "IsSignalGroup".',errmsg)
end

% Check other inputs
if ~ischar(name)
  error('Invalid ''name'' input.')
elseif ~isscalar(Ts) && ~(isrow(Ts) && length(Ts)==2) && (length(Ts) ~= size(Signals.Values,1))
  error('Invalid ''Ts'', ''[t0,Ts]'', ''t'', or ''Time'' input.')
elseif ~ischar(units)
  error('Invalid ''units'' input.')
elseif ~ischar(description)
  error('Invalid ''description'' input.')
end

if isscalar(Ts)
  % Build time vector
  n = size(Signals.Values,1);
  t = Ts*(0:n-1)';
elseif isrow(Ts) && length(Ts)==2
  n = size(Signals.Values,1);
  t = Ts(1) + Ts(2)*(0:n-1)';
else
  % Time vector supplied
  t = Ts(:);  % applies to 't' or 'Time'
end

% Initialize, copying name layers
Time = Signals;

% Set name on all layers
layers = GetLayers(Time);
for k = 1:length(layers)
  layer = layers{k};
  Time.(layer) = {name};
end

% Set remaining fields
Time.Values       = t;
Time.Units        = {units};
Time.Descriptions = {description};
