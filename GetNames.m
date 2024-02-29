function [names,str] = GetNames(obj,selection)

% GETNAMES - Get names from a name layer or signal channel.
% names = GetNames(Signals,layer)
% names = GetNames(Data,layer)
% [names,str] = GetNames(Signals,index)
% [names,str] = GetNames(Data,index)
%
% Returns the non-empty names on the given 'layer' for an input 
% signal group 'Signals' or dataset 'Data'.  If an integer 'index' 
% is supplied, returns the non-empty names on the given signal 
% channel. 
%
% When retrieving names for a signal channel, optional second 
% output argument 'str' returns a corresponding "name signature" 
% for the channel, which lists the extracted names as a single 
% string delimited by colon (':') characters. 
%
% See also "GetDefaultNames", "GetNamesMatrix". 
%
% P.G. Bonanni
% 4/4/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check first input
[flag1,valid1,errmsg1] = IsSignalGroup(obj);
[flag2,valid2,errmsg2] = IsDataset(obj);
if ~flag1 && ~flag2
  error('Input #1 is not a valid signal group or dataset.')
elseif flag1 && ~valid1
  error('Input #1 is not a valid signal group: %s  See "IsSignalGroup".',errmsg1)
elseif flag2 && ~valid2
  error('Input #1 is not a valid dataset: %s  See "IsDataset".',errmsg2)
end

% Check selection input
if ~( ischar(selection) || ...
      (isnumeric(selection) && isscalar(selection) && rem(selection,1)==0) )
  error('Input #2 is not valid.')
end

% If array provided
obj = obj(1);

% If input is a dataset ...
if IsDataset(obj)
  Data = obj;
  Signals = CollectSignals(Data);
  [names,str] = GetNames(Signals,selection);
  return
end

% Input is a signal group
Signals = obj;

% If 'layer' specified ...
if ischar(selection)
  layer = selection;

  % In case 'layer' is a source string ...
  layer = Source2Layer(layer);

  % Identify available name layers
  Layers = GetLayers(Signals);

  % Check 'layer' input
  if ~ismember(layer,Layers)
    error('The string ''%s'' is not a valid name layer.',layer)
  end

  % Collect names and remove empties
  names = Signals.(layer);
  names(cellfun(@isempty,names)) = [];

  % Null second output
  str = [];

else  % if 'index' provided ...
  index = selection;

  % Get names array
  NAMES = GetNamesMatrix(Signals);

  % Check 'index' input
  if index < 1 || index > size(NAMES,1)
    error('Input ''index'' is not a signal index.')
  end

  % Collect names and remove empties
  names = NAMES(index,:)';
  names(cellfun(@isempty,names)) = [];

  % For a name signature, concatenate into a string
  if length(names) >= 1
    DELIM = repmat({':'},length(names),1);
    C = [DELIM,names]'; str=[C{:}]; str(1)=[];
  else
    str = '';
  end
end
