function obj = RemoveNameLayer(obj,selections)

% REMOVENAMELAYER - Remove one or more name layers.
% Data = RemoveNameLayer(Data,layer)
% Data = RemoveNameLayer(Data,{'layer1','layer2',...})
% DATA = RemoveNameLayer(DATA, ...)
% Signals = RemoveNameLayer(Signals, ...)
% SIGNALS = RemoveNameLayer(SIGNALS, ...)
%
% Removes name layer 'layer' from all signal groups contained 
% in dataset 'Data' and returns the modified dataset as output.  
% Performs the analogous function for dataset arrays ('DATA'), 
% signal groups ('Signals') or signal group arrays ('SIGNALS').  
% Also accepts a cell array of layer names. 
%
% See also "AddNameLayer", "RemoveLayersExcept". 
%
% P.G. Bonanni
% 9/23/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


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

% Check 'selections' ('layer') argument
if ~ischar(selections) && ~iscellstr(selections)
  error('Invalid ''layer'' input.')
end

% Make cell array
if ischar(selections)
  selections = cellstr(selections);
end

% In case one or more 'layer' selections is a source string ...
selections1 = cellfun(@Source2Layer,selections,'Uniform',false);

% Identify existing name layers
layers = GetLayers(obj);

% Check that at least one name layer remains
if isempty(setdiff(layers,selections1))
  error('Removing all existing name layers is not permitted.')
end

% If input is a dataset ...
if IsDataset(obj)
  Data = obj;

  % Identify signal group fields
  [~,groups] = GetSignalGroups(Data);

  % Check selections for validity
  for k = 1:length(selections)

    % Check if layer selection is valid
    if ~ismember(selections1{k},layers) && ~strcmp(selections1{k},selections{k})
      error('The selection ''%s'' (''%s'') is not present in the input dataset.',selections{k},selections1{k})
    elseif ~ismember(selections1{k},layers) && strcmp(selections1{k},selections{k})
      error('The selection ''%s'' is not present in the input dataset.',selections{k})
    end
  end

  % Remove selection(s) from each signal group
  for k = 1:length(groups)
    group = groups{k};
    Data.(group) = rmfield(Data.(group),selections1);
  end

  % Return the result
  obj = Data;

% If input is a dataset array ...
elseif IsDatasetArray(obj)
  DATA = obj;

  % Loop over signal groups
  for k = 1:numel(DATA)
    try
      DATA(k) = RemoveNameLayer(DATA(k),selections);
    catch
      error('Error occurred at dataset #%d.',k)
    end
  end

  % Return the result
  obj = DATA;

% If input is a signal group or signal group array ...
elseif IsSignalGroupArray(obj)

  % Check selections for validity
  for k = 1:length(selections)

    % Check if layer selection is valid
    if ~ismember(selections1{k},layers) && ~strcmp(selections1{k},selections{k})
      error('The selection ''%s'' (''%s'') is not present in the input dataset.',selections{k},selections1{k})
    elseif ~ismember(selections1{k},layers) && strcmp(selections1{k},selections{k})
      error('The selection ''%s'' is not present in the input dataset.',selections{k})
    end
  end

  % Perform the removal
  obj = rmfield(obj,selections1);

end
