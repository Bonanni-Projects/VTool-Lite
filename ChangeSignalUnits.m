function out = ChangeSignalUnits(obj,name,factor,units)

% CHANGESIGNALUNITS - Change signal units in a dataset or signal group.
% Data = ChangeSignalUnits(Data,name,factor,units)
% DATA = ChangeSignalUnits(DATA,name,factor,units)
% Signals = ChangeSignalUnits(Signals,name,factor,units)
% SIGNALS = ChangeSignalUnits(SIGNALS,name,factor,units)
%
% Converts the units assignment for all instances of a signal in 
% a dataset, signal group, dataset array, or signal-group array.  
% Input 'name' specifies the signal name, input 'factor' the 
% conversion factor to apply, and 'units' the units string to 
% assign after the conversion. 
%
% See also "ChangeTimeUnits". 
%
% P.G. Bonanni
% 7/3/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Handle arrays
if isstruct(obj) && numel(obj) > 1
  fun = @(x)ChangeSignalUnits(x,name,factor,units);
  out = arrayfun(fun,obj);
  return
end

% Check 'obj' argument
[flag1,valid1] = IsSignalGroup(obj);
[flag2,valid2] = IsDataset(obj);
if ~flag1 && ~flag2
  error('Works for signal groups or datasets only.')
elseif flag1 && ~valid1
  error('Input ''Signals'' is not a valid signal group.  See "IsSignalGroup".')
elseif flag2 && ~valid2
  error('Input ''Data'' is not a valid dataset.  See "IsDataset".')
end

% Check 'name' argument
if ~ischar(name)
  error('Invalid ''name'' input.')
end

% Check 'factor' argument
if ~isscalar(factor) || ~isnumeric(factor)
  error('Invalid ''factor'' input.')
end

% Check 'units' argument
if ~ischar(units)
  error('Invalid ''units'' input.')
end

% If input is a dataset ...
if flag2
  Data = obj;

  % Find all instances of the specified signal
  [Index,groups] = FindName(name,Data);

  % Perform the conversion
  if ~isempty(Index)
    for j = 1:length(groups)
      group = groups{j};
      Data.(group).Values(:,Index{j}) = factor * Data.(group).Values(:,Index{j});
      [Data.(group).Units{Index{j}}] = deal(units);
    end
  else
    error('Specified name ''%s'' not found in dataset.',name)
  end

  % Return output
  out = Data;
  
else  % if input is a signal group ...
  Signals = obj;

  % Find all instances of the specified signal
  index = FindName(name,Signals);

  % Perform the conversion
  if ~isempty(index)
    Signals.Values(:,index) = factor * Signals.Values(:,index);
    [Signals.Units{index}] = deal(units);
  else
    error('Specified name ''%s'' not found in signal group.',name)
  end

  % Return output
  out = Signals;

end
