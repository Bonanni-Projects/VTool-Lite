function obj = ConvertSignalsToDB(obj,option)

% CONVERTSIGNALSTODB - Convert signal group to dB units.
% Signals = ConvertSignalsToDB(Signals, ['field' | 'power'])
% SIGNALS = ConvertSignalsToDB(SIGNALS, ['field' | 'power'])
%
% Converts the 'Values' array of all signals in signal-group 
% 'Signals' to dB, and updates the 'Units' field to reflect 
% the change. 
%
% The second argument specifies whether 'Signals' contains 
% "field" quantities (e.g., voltage or current), or "power" 
% quantities.  Field quantities are converted via 20*log10(.), 
% and power quantities via 10*log10(.).
%
% Also works for signal-group array 'SIGNALS'. 
%
% P.G. Bonanni
% 8/17/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check first input
[flag,valid] = IsSignalGroupArray(obj);
if ~flag || ~valid
  error('Input #1 is not a valid signal group or signal group array.')
end

% Check option
if ~ischar(option)
  error('Specified ''option'' is invalid.')
elseif ~strcmp(option,'field') && ~strcmp(option,'power')
  error('Must specify ''field'' or ''power''.')
end

% Input length
N = length(obj);

% If input is a signal-group array ...
if IsSignalGroupArray(obj) && N > 1

  % Convert signal groups
  for k = 1:N
    obj(k) = ConvertSignalsToDB(obj(k),option);
  end

else
  Signals = obj;

  % Check 'Signals' input
  [flag,valid,errmsg] = IsSignalGroup(Signals);
  if ~flag
    error('Input ''Signals'' is not a signal group: %s',errmsg)
  elseif ~valid
    error('Input ''Signals'' is not a valid signal group: %s  See "IsSignalGroup".',errmsg)
  end

  % Convert all signals to dB
  if strcmp(option,'field')
    Signals.Values = 20*log10(Signals.Values);
  else  % if strcmp(option,'power')
    Signals.Values = 10*log10(Signals.Values);
  end

  % Modify units
  [Signals.Units{:}] = deal('dB');

  obj = Signals;
end
