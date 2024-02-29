function m = GetNumSignals(obj)

% GETNUMSIGNALS - Get number of signals in a signal group, dataset, etc.
% m = GetNumSignals(Signals)
% m = GetNumSignals(SIGNALS)
% m = GetNumSignals(Data)
% m = GetNumSignals(DATA)
%
% Returns the number of signals represented in a signal group, 
% dataset, or array of either. 
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

  % Get total number of signals
  Signals = CollectSignals(Data);
  m = size(Signals.Values,2);

elseif IsSignalGroup(obj)

  % Input is a signal group
  Signals = obj;

  % Get number of signals
  m = size(Signals.Values,2);

elseif IsDatasetArray(obj) || IsSignalGroupArray(obj)

  % Get number of signals from first element
  m = GetNumSignals(obj(1));

end
