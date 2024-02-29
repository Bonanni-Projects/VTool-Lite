function DATA = PadDataToLength(DATA,value,len)

% PADDATATOLENGTH - Pad a dataset or dataset array to length.
% DATA = PadDataToLength(DATA,value)
% DATA = PadDataToLength(DATA,value,['max'|'min'])
% DATA = PadDataToLength(DATA,value,len)
% DATA = PadDataToLength(DATA,'extrap',len)
% Data = PadDataToLength(Data, ...)
%
% Pads (or truncates) signals in a dataset or dataset array to a  
% specified data length. Input 'DATA' is a length-N or multidimensional 
% array of homogeneous datasets, but with data length possibly varying 
% from one array element to the next, to be extended or truncated to a 
% desired uniform length.  Alternatively, 'Data' is a scalar dataset 
% to be padded, extrapolated, or truncated to a specified length. Input 
% 'value' specifies a padding value (typically 0 or NaN) or the keyword 
% 'extrap', designating extrapolation based on the last two values in the 
% time series. (A 'value' specification applies to all contained signal 
% groups except for 'Time', for which the 'extrap' method always applies.) 
% Input 'len' is the desired data length. For dataset arrays, 'len' may 
% also be specified as 'min' or 'max', referring to the minimum or maximum 
% data length present in the array. If 'len' is omitted or empty, the 
% 'max' option is assumed. 
%
% See also "PadSignalsToLength". 
%
% P.G. Bonanni
% 1/19/23

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 3
  len = 'max';
end

% Check 'SIGNALS' input
[flag,valid,errmsg] = IsDatasetArray(DATA);
if ~flag
  error('Input ''DATA'' is not a dataset array: %s',errmsg)
elseif ~valid
  error('Input ''DATA'' is not a valid dataset array: %s  See "IsDatasetArray".',errmsg)
end

% Determine signal length
nvec = arrayfun(@(x)size(x.Time.Values,1),DATA(:));
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

% Get signal groups
[~,groups] = GetSignalGroups(DATA(1));

% Loop over groups
for k = 1:length(groups)
  group = groups{k};

  % Collect groups
  SIGNALS = [DATA.(group)];

  % Perform the padding or truncation
  if strcmp(group,'Time')
    SIGNALS = PadSignalsToLength(SIGNALS,'extrap',len);
  else  % all other cases
    SIGNALS = PadSignalsToLength(SIGNALS,value,len);
  end

  % Reload onto the original array
  C = num2cell(SIGNALS); 
  [DATA.(group)] = deal(C{:});
end
