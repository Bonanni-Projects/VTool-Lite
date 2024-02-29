function Names = GetDefaultNames(obj)

% GETDEFAULTNAMES - Get default signal names from a signal group or dataset.
% Names = GetDefaultNames(Signals)
% Names = GetDefaultNames(SIGNALS)
% Names = GetDefaultNames(Data)
% Names = GetDefaultNames(DATA)
%
% Returns the list of default signal names for a signal group,  
% dataset, signal group array, or dataset array. Default names 
% are drawn from the default name layer, defined in function 
% "GetParam".  If a name entry on the default name layer is 
% missing, the first available non-empty name on the given 
% signal channel is used. 
%
% P.G. Bonanni
% 7/20/19

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
  error('Input array length is zero.')
end

% If array provided
obj = obj(1);

% If input is a dataset ...
if IsDataset(obj)
  Data = obj;
  Signals = CollectSignals(Data);
  Names = GetDefaultNames(Signals);
  return
end

% Input is a signal group
Signals = obj;

% Get the default name layer
layer0 = GetParam('DefaultNameLayer');
if ~isempty(layer0)
  layer0 = Source2Layer(layer0);
end

% Revert to the first available layer if 'layer0' is not present
Layers = GetLayers(Signals);
if ~ismember(layer0,Layers)
  layer0 = Layers{1};
end

% Signal count
nsignals = size(Signals.Values,2);

% Get the NAMES matrix for the group
NAMES = GetNamesMatrix(Signals);

% Initialize
if ~isempty(layer0)
  Names = Signals.(layer0);
else  % if "default" layer not defined
  Names = repmat({''},nsignals,1);
end

% Loop over signal channels
for k = 1:nsignals
  % If no name exists on the default layer, or name is empty ...
  if isempty(Names{k})  % ... retrieve first non-empty name
    mask = ~cellfun(@isempty,NAMES(k,:));
    i = find(mask,1,'first');  if isempty(i), i=1; end
    Names{k} = NAMES{k,i};
  end
end

% Warn if empty names entries exist
if any(cellfun(@isempty,Names))
  fprintf('Warning: one or more default names does not exist.\n');
end
