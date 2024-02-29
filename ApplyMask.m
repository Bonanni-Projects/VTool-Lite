function obj = ApplyMask(obj,locations,value,Selections)

% APPLYMASK - Mask signals or groups at selected locations.
% Data = ApplyMask(Data,locations,value,{'group1','group2', ...})
% Data = ApplyMask(Data,locations,value,{'signal1','signal2', ...})
% Data = ApplyMask(Data,locations,value)
% Data = ApplyMask(Data,mask,value, ...)
% DATA = ApplyMask(DATA, ...)
% Signals = ApplyMask(Signals, ...)
% SIGNALS = ApplyMask(SIGNALS, ...)
%
% Applies a user-specified mask 'value' (e.g., NaN, 0, or any 
% scalar 'value') to dataset 'Data' at specified locations.  
% The locations are specified by an index vector 'locations', 
% or by a binary 'mask' vector of length matching the dataset's 
% data length, or by one of the keywords {'first','last','all'} 
% (to indicate first point, last point, or all points, respectively).  
% The modified dataset is returned. 
%
% The 'Selections' input specifies a list of signal and/or group 
% names to which the operation should be applied.  If 'Selections' 
% is omitted, the operation is applied to all signals in the dataset. 
%
% The function works analogously for dataset arrays ('DATA'), 
% signal groups ('Signals'), or signal group arrays ('SIGNALS'), 
% with the 'Selections' argument appropriately specified. 
%
% P.G. Bonanni
% 2/6/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 4
  Selections = {};
end

% Check first input
[flag1,valid1,errmsg1] = IsSignalGroupArray(obj);
[flag2,valid2,errmsg2] = IsDatasetArray(obj);
if ~flag1 && ~flag2
  error('Input is not a valid signal group, dataset, or array.')
elseif flag1 && ~valid1
  error('Input is not a valid signal group or signal group array: %s  See "IsSignalGroup".',errmsg1)
elseif flag2 && ~valid2
  error('Input is not a valid dataset or dataset array: %s  See "IsDataset".',errmsg2)
elseif isempty(obj)
  error('Input array is empty.')
end

% Determine data length
if IsDatasetArray(obj)  % if dataset or dataset array
  N = length(obj(1).Time.Values);  % data length
else  % if signal group or signal group array
  N = size(obj(1).Values,1);  % data length
end

% Check 'locations' input
if ~isnumeric(locations) && ~islogical(locations) && ~ischar(locations)
  error('Invalid ''locations'' input.')
elseif isnumeric(locations) && (any(locations < 1) || any(locations > N))
  error('One or more ''locations'' values is out of range.')
elseif isnumeric(locations) && any(rem(locations,1)~=0)
  error('One or more ''locations'' values is not valid.')
elseif islogical(locations) && (~isvector(locations) || length(locations)~=N)
  error('Invalid or wrong size ''locations'' input.')
elseif ischar(locations) && ~any(strcmp(locations,{'first','last','all'}))
  error('Invalid ''locations'' keyword.')
elseif ischar(locations) && N==0
  error('Invalid ''locations'' keyword with zero data length.')
end

% Convert 'locations' input
mask = false(N,1);  % initialize
if     ischar(locations) && strcmp(locations,'first'), mask(1)         = true;
elseif ischar(locations) && strcmp(locations,'last'),  mask(end)       = true;
elseif ischar(locations) && strcmp(locations,'all'),   mask(1:end)     = true;
else,                                                  mask(locations) = true;  % works for numeric or logical 'locations'
end

% Check 'Selections' input
if ~iscell(Selections) || ~all(cellfun(@ischar,Selections))
  error('Invalid ''Selections'' input.')
end

% Check 'value' input
if ~isnumeric(value) || ~isscalar(value)
  error('Invalid ''value'' input.')
end

% If input is a dataset ...
if IsDataset(obj)
  Data = obj;

  % Get signal group names
  [~,Groups] = GetSignalGroups(Data);

  % Default 'Selections' to all groups except 'Time'
  if isempty(Selections), Selections=setdiff(Groups,'Time'); end

  % Loop over selections
  for k = 1:length(Selections)
    selection = Selections{k};

    % If selection is a group ...
    if ismember(selection,Groups)

      % Apply mask to group
      Data.(selection).Values(mask,:) = value;

    else  % assume selection is a signal name

      % Apply mask to signal
      x = GetSignal(selection,Data);
      x(mask) = value;
      Data = ReplaceSignalInDataset(Data,selection,x);
    end
  end

  % Return the result
  obj = Data;

% If input is a dataset array ...
elseif IsDatasetArray(obj)
  DATA = obj;

  % Loop over signal groups
  for k = 1:numel(DATA)
    try
      DATA(k) = ApplyMask(DATA(k),locations,value,Selections);
    catch
      error('Error occurred at dataset #%d.',k)
    end
  end

  % Return the result
  obj = DATA;

% If input is a signal group ...
elseif IsSignalGroup(obj)
  Signals = obj;

  % If 'Selections' specified
  if ~isempty(Selections)

    % Loop over selections
    for k = 1:length(Selections)
      selection = Selections{k};

      % Apply mask to signal
      x = GetSignal(selection,Signals);
      x(mask) = value;
      Signals = ReplaceSignalInGroup(Signals,selection,x);
    end

  else  % if no 'Selections' specified

    % Apply mask to group
    Signals.Values(mask,:) = value;
  end

  % Return the result
  obj = Signals;

% If input is a signal group array ...
elseif IsSignalGroupArray(obj)
  SIGNALS = obj;

  % Loop over signal groups
  for k = 1:numel(SIGNALS)
    try
      SIGNALS(k) = ApplyMask(SIGNALS(k),locations,value,Selections);
    catch
      error('Error occurred at signal group #%d.',k)
    end
  end

  % Return the result
  obj = SIGNALS;

end
