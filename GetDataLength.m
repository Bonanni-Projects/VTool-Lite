function n = GetDataLength(obj)

% GETDATALENGTH - Get data length(s) in a dataset, signal group, etc.
% n = GetDataLength(Data)
% n = GetDataLength(Signals)
% nvec = GetDataLength(DATA)
% nvec = GetDataLength(SIGNALS)
%
% Returns the data length (number of time points) in dataset 
% 'Data' or signal group 'Signals' as scalar output 'n'.  If 
% input is a dataset array 'DATA' or signal-group array 'SIGNALS', 
% output 'nvec' is returned as a vector (or numerical array) of 
% matching size. 
%
% P.G. Bonanni
% 8/29/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check input
[flag1,valid1,errmsg1] = IsDataset(obj);
[flag2,valid2,errmsg2] = IsSignalGroup(obj);
[flag3,valid3,errmsg3] = IsDatasetArray(obj);
[flag4,valid4,errmsg4] = IsSignalGroupArray(obj);
if ~flag1 && ~flag2 && ~flag3 && ~flag4
  error('Input is not a valid dataset, signal group, or array.')
elseif flag1 && ~valid1
  error('Input is not a valid dataset: %s  See "IsDataset".',errmsg1)
elseif flag2 && ~valid2
  error('Input is not a valid signal group: %s  See "IsSignalGroup".',errmsg2)
elseif flag3 && ~valid3
  error('Input is not a valid dataset array: %s  See "IsDatasetArray".',errmsg3)
elseif flag4 && ~valid4
  error('Input is not a valid signal group array: %s  See "IsSignalGroupArray".',errmsg4)
end

% If input is a dataset ...
if IsDataset(obj)

  % Input is a dataset
  Data = obj;

  % Get data length from the 'Time' signal group
  n = length(Data.Time.Values);

elseif IsSignalGroup(obj)

  % Input is a signal group
  Signals = obj;

  % Get first dimension of the 'Values' field
  n = size(Signals.Values,1);

elseif IsDatasetArray(obj)

  % Input is a dataset array
  DATA = obj;

  % Get all data lengths
  n = arrayfun(@(x)length(x.Time.Values),DATA);

elseif IsSignalGroupArray(obj)

  % Input is a signal group array
  SIGNALS = obj;

  % Get all data lengths
  n = arrayfun(@(x)size(x.Values,1),SIGNALS);

end
