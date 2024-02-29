function obj = ConvertToDouble(obj)

% CONVERTTODOUBLE - Convert data to 'double'.
% Data = ConvertToDouble(Data)
% DATA = ConvertToDouble(DATA)
% Signals = ConvertToDouble(Signals)
% SIGNALS = ConvertToDouble(SIGNALS)
%
% Converts the 'Values' array of all contained signal groups 
% to type 'double'.  Works for datasets, dataset arrays, 
% signal groups, or signal group arrays. 
%
% P.G. Bonanni
% 3/1/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check input
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

% If input is a dataset ...
if IsDataset(obj)
  Data = obj;

  % Identify the signal groups
  [~,groups] = GetSignalGroups(Data);
  if isempty(groups)
    fprintf('WARNING: Input structure has no signal-group fields.\n')
  end

  % Recast all real data to double
  for k = 1:length(groups)
    group = groups{k};
    if strcmp(group,'Time') && strcmp(Data.Time.Units,'datetime'), continue, end
    Data.(group).Values = double(Data.(group).Values);
  end

  % Return the result
  obj = Data;

% If input is a dataset array ...
elseif IsDatasetArray(obj)
  DATA = obj;

  % Loop over datasets
  for k = 1:numel(DATA)
    DATA(k) = ConvertToDouble(DATA(k));
  end

  % Return the result
  obj = DATA;

% If input is a signal group ...
elseif IsSignalGroup(obj)
  Signals = obj;

  % Convert to double
  Signals.Values = double(Signals.Values);

  % Return the result
  obj = Signals;

% If input is a signal group array ...
elseif IsSignalGroupArray(obj)
  SIGNALS = obj;

  % Loop over signal groups
  for k = 1:numel(SIGNALS)
    SIGNALS(k).Values = double(SIGNALS(k).Values);
  end

  % Return the result
  obj = SIGNALS;

end
