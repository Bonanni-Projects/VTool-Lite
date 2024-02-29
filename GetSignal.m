function [x,units,description,index] = GetSignal(selection,obj)

% GETSIGNAL - Extract a signal from a signal group or dataset.
% [x,units,description,index] = GetSignal(name,Signals)
% [x,units,description,index] = GetSignal(index,Signals)
% [x,units,description] = GetSignal(name,Data)
% [x,units,description] = GetSignal(index,Data)
%
% Extracts signal data from signal group 'Signals' or dataset 
% 'Data' and returns the result as column vector 'x'.  Input 
% 'name' specifies the desired signal.  The name entry from 
% any available name layer may be used.  Alternatively, the 
% scalar integer 'index' may be supplied. 
%
% Along with signal data, the function returns 'units' and 
% 'description' string for the located signal.  If a signal 
% group is input, output 'index' returns the index of the 
% signal within the signal group.  (Note: in the event of 
% a duplicated name, only the first match is considered.) 
%
% See also "GetTime". 
%
% P.G. Bonanni
% 4/7/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check input
[flag1,valid1] = IsSignalGroup(obj);
[flag2,valid2] = IsDataset(obj);
if ~flag1 && ~flag2
  error('Works for scalar signal groups or datasets only.')
elseif flag1 && ~valid1
  error('Input #2 is not a valid signal group.  See "IsSignalGroup".')
elseif flag2 && ~valid2
  error('Input #2 is not a valid dataset.  See "IsDataset".')
end

% Get signal group
if flag1  % if input is a signal group
  Signals = obj;
else  % if input is a dataset
  Data = obj;
  Signals = CollectSignals(Data);
end

% If 'name' specified ...
if ischar(selection)
  name = selection;

  % Exclude 'Time' as a choice
  if strcmpi(name,'Time')
    error('The time vector is excluded.  Use "GetTime" instead.')
  end

  % Ensure the named signal exists, and if so, extract it
  [Signals1,ismatched,index1] = SelectFromGroup(name,Signals);
  if ~ismatched
    error('Signal ''%s'' was not found.',name)
  end

% ... else if scalar integer 'index' specified ...
elseif isnumeric(selection) && isscalar(selection) && rem(selection,1)==0
  index = selection;

  % Ensure the specified index is valid, and if so, extract the corresponding signal
  [Signals1,ismatched,index1] = SelectFromGroup(index,Signals);
  if ~ismatched
    error('Signal index ''%d'' was not found.',index)
  end

else
  error('Input #1 is not a valid selection.')
end

% Extract the data vector
x = Signals1.Values;

% Extract units and description
units       = Signals1.Units{1};
description = Signals1.Descriptions{1};

% Output index value
if flag1  % if input is a signal group
  index = index1;
else  % if input is a dataset
  index = [];
end
