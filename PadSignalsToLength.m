function SIGNALS = PadSignalsToLength(SIGNALS,value,len)

% PADSIGNALSTOLENGTH - Pad a signal group or signal-group array to length.
% SIGNALS = PadSignalsToLength(SIGNALS,value)
% SIGNALS = PadSignalsToLength(SIGNALS,value,['max'|'min'])
% SIGNALS = PadSignalsToLength(SIGNALS,value,len)
% SIGNALS = PadSignalsToLength(SIGNALS,'extrap',len)
% Signals = PadSignalsToLength(Signals, ...)
% Time = PadSignalsToLength(Time,'extrap',len)
%
% Pads (or truncates) signals a signal group or signal-group 
% array to a specified data length. Input 'SIGNALS' is a length-N 
% or multidimensional array of homogeneous signal groups of M signals 
% each, but with data length possibly varying from one array element 
% to the next, to be extended or truncated to a desired uniform length.  
% Alternatively, 'Signals' is a signal group, or 'Time' is a time 
% signal group, to be padded, extrapolated, or truncated to a specified 
% length.  Input 'value' specifies a padding value (typically 0 or NaN) 
% or the keyword 'extrap', designating extrapolation based on the last 
% two values in the time series.  Input 'len' is the desired data length. 
% For signal group arrays, 'len' may also be specified as 'min' or 'max', 
% referring to the minimum or maximum data length present in the array. 
% If 'len' is omitted or empty, the 'max' option is assumed. 
%
% See also "PadDataToLength". 
%
% P.G. Bonanni
% 10/10/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 3
  len = 'max';
end

% Check 'SIGNALS' input
[flag,valid,errmsg] = IsSignalGroupArray(SIGNALS);
if ~flag
  error('Input ''SIGNALS'' is not a signal group array: %s',errmsg)
elseif ~valid
  error('Input ''SIGNALS'' is not a valid signal group array: %s  See "IsSignalGroupArray".',errmsg)
end

% Determine signal length
nvec = arrayfun(@(x)size(x.Values,1),SIGNALS(:));
if isnumeric(len) && isempty(len)
  len = max(nvec);
elseif ischar(len) && strcmp(len,'max')
  len = max(nvec);
elseif ischar(len) && strcmp(len,'min')
  len = min(nvec);
elseif ~isnumeric(len) || ~isscalar(len) || rem(len,1)~=0 || len < 0
  error('Specified signal length is invalid.')
end

% Check 'value' input
if ~(isnumeric(value) && isscalar(value)) && ~(ischar(value) && strcmp(value,'extrap'))
  error('Input ''value'' must be a scalar numeric value or the keyword ''extrap''.')
end

% Number of signals
nsignals = size(SIGNALS(1).Values,2);

% Perform padding or truncation
for k = 1:numel(SIGNALS)
  len1 = size(SIGNALS(k).Values,1);
  if len1 < len      % ---- PAD OR EXTRAPOLATE
    if isnumeric(value)  % pad to length
      padding = repmat(value,len-len1,nsignals);
    else         % extrapolate to length
      if len1 < 2
        error('Need at least 2 points to extrapolate.')
      end  % /------- linear extrapolation -------\
      padding = interp1((1:len1)',SIGNALS(k).Values,((len1+1):len)','linear','extrap');
    end
    SIGNALS(k).Values = [SIGNALS(k).Values; padding];
  elseif len1 > len  % ---- TRUNCATE TO LENGTH
    SIGNALS(k).Values = SIGNALS(k).Values(1:len,:);
  end
end
