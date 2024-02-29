function out = CopyNamesFromModel(obj,obj0,option)

% COPYNAMESFROMMODEL - Copy all names from a model dataset or signal group.
% Data = CopyNamesFromModel(Data,Data0)
% DATA = CopyNamesFromModel(DATA,Data0)
% Signals = CopyNamesFromModel(Signals,Signals0)
% SIGNALS = CopyNamesFromModel(SIGNALS,Signals0)
% {...} = CopyNamesFromModel(..., 'keep')
%
% Copy all names, name layers, and units from a model dataset or 
% signal group. The "model" is specified by 'Data0' or 'Signals0', 
% and the target object is 'Data' or 'Signals', respectively. This 
% operation can be employed to force name and units matching in 
% preparation for plotting or comparison.  It is only valid if the 
% model object has matching structure.  For signal groups, the 
% requirement is a matching number of signals (though signal lengths 
% need not match). vFor datasets, matching signal group names must 
% be present, and all groups must have matching number of signals. 
%
% Also accepts dataset arrays and signal-group arrays. The model 
% 'Data0' in the case of dataset array 'DATA' may itelf be a dataset 
% array of any size.  Similarly, the model 'Signals0' in the case of 
% signal-group array 'SIGNALS' may also be a signal-group array of 
% any size. 
%
% If the 'keep' option is chosen, the function adds missing 
% name layers only.  It does not overwrite or replace name 
% layers in the original object. 
%
% See also "AddNameLayer", "AddMissingLayers". 
%
% P.G. Bonanni
% 7/16/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 3
  option = '';
end

% Identify input type, and perform action
if IsDataset(obj)

  % Check that model is a dataset
  if ~IsDataset(obj0)
    error('Input #2 must also be a dataset.')
  end

  % Datasets
  Data  = obj;
  Data0 = obj0;

  % Check for matching fields
  fields  = fieldnames(Data);
  fields0 = fieldnames(Data0);
  if ~isempty(setxor(fields,fields0))
    fprintf('Warning: The provided datasets do not have the same field names.\n')
  end

  % Get signal group names
  [~,Groups] = GetSignalGroups(Data);

  % Check each group for matching number of signals
  for k = 1:length(Groups)
    group = Groups{k};
    if size(Data.(group).Values,2) ~= size(Data0.(group).Values,2)
      error('Non-matching signal group detected (''%s''). Wrong number of signals.',group)
    end
  end

  % Perform the copy operation, by group
  for k = 1:length(Groups)
    group = Groups{k};
    Data.(group) = CopyNamesFromModel(Data.(group),Data0.(group),option);
  end

  % Output
  out = Data;

elseif IsSignalGroup(obj)

  % Check that model is a signal group
  if ~IsSignalGroup(obj0)
    error('Input #2 must also be a signal group.')
  end

  % Signal groups
  Signals  = obj;
  Signals0 = obj0;

  % Check for matching number of signals
  if size(Signals.Values,2) ~= size(Signals0.Values,2)
    error('The provided signal groups do not have matching number of signals.')
  end

  % Remove any existing name layers
  if ~strcmp(option,'keep')  % unless option is 'keep'
    Layers = GetLayers(Signals);
    Signals = rmfield(Signals,Layers);
  end

  % Transfer name layers from model
  Layers0 = GetLayers(Signals0);
  for k = 1:length(Layers0)
    layer = Layers0{k};
    Signals.(layer) = Signals0.(layer);
  end

  % Transfer units from model
  Signals.Units = Signals0.Units;

  % Revised list of fields
  Layers = GetLayers(Signals);

  % Re-order the fields to standard order
  if ~isempty(which('NameTables.xlsx'))
    [~,~,LayersNT] = ReadMasterLookup;
  else  % if "NameTables.xlsx" does not exist
    LayersNT = {};
  end
  if all(ismember(Layers,LayersNT))
    fields = [intersect(LayersNT,Layers,'stable');'Values';'Units';'Descriptions'];
    Signals = orderfields(Signals,fields);
  else  % if one or more layers is not registered in NameTables
    fields = [Layers;'Values';'Units';'Descriptions'];
    Signals = orderfields(Signals,fields);
  end

  % Output
  out = Signals;

elseif IsDatasetArray(obj)

  % Check that model is valid
  if ~IsDatasetArray(obj0)
    error('Input #2 must be a dataset or dataset array.')
  end

  % Dataset array and model
  DATA  = obj;
  Data0 = obj0(1);

  % Loop over datasets
  for k = 1:numel(DATA)
    DATA(k) = CopyNamesFromModel(DATA(k),Data0,option);
  end

  % Output
  out = DATA;

elseif IsSignalGroupArray(obj)

  % Check that model is valid
  if ~IsSignalGroupArray(obj0)
    error('Input #2 must be a signal group or signal-group array.')
  end

  % Signal-group array and model
  SIGNALS  = obj;
  Signals0 = obj0(1);

  % Get name layers
  layers  = GetLayers(SIGNALS);   % original name layers
  layers0 = GetLayers(Signals0);  % name layers in model

  % Remove name layers that are not in model
  if ~strcmp(option,'keep')  % unless option is 'keep'
    SIGNALS = rmfield(SIGNALS,setdiff(layers,layers0));
    layers = GetLayers(SIGNALS);  % revised name layers
  end

  % Prepare 'SIGNALS' by ensuring the needed fields are initialized
  fields = setdiff(layers0,layers,'stable');  % fields to add
  for k = 1:length(fields)
    layer = fields{k};
    [SIGNALS.(layer)] = deal(SIGNALS(1).(layers{1}));
    layers = union(layers,layer,'stable');  % add to list
  end

  % Transfer name layers from model
  for k = 1:length(layers0)
    layer = layers0{k};
    [SIGNALS.(layer)] = deal(Signals0.(layer));
  end

  % Transfer units from model
  [SIGNALS.Units] = deal(Signals0.Units);

  % Re-order the fields to standard order
  if ~isempty(which('NameTables.xlsx'))
    [~,~,LayersNT] = ReadMasterLookup;
  else  % if "NameTables.xlsx" does not exist
    LayersNT = {};
  end
  if all(ismember(layers,LayersNT))
    fields = [intersect(LayersNT,layers,'stable');'Values';'Units';'Descriptions'];
    SIGNALS = orderfields(SIGNALS,fields);
  else  % if one or more layers is not registered in NameTables
    fields = [layers;'Values';'Units';'Descriptions'];
    SIGNALS = orderfields(SIGNALS,fields);
  end

  % Output
  out = SIGNALS;

else
  error('Works for datasets and signal groups only.')
end
