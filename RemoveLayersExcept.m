function obj = RemoveLayersExcept(selections,obj)

% REMOVELAYERSEXCEPT - Remove extra name layers.
% Data = RemoveLayersExcept(selections,Data)
% DATA = RemoveLayersExcept(selections,DATA)
% Signals = RemoveLayersExcept(selections,Signals)
% SIGNALS = RemoveLayersExcept(selections,SIGNALS)
%
% Removes extra name layers from dataset 'Data', dataset array 
% 'DATA', signal group 'Signals', or signal group array 'SIGNALS', 
% leaving only the name layers specified by 'selections'. Input 
% 'selections' may be provided as a single character string (if 
% a single name layer), or a cell array of same. All entries in 
% 'selections' must be present in the input object. 
%
% See also "RemoveNameLayer", "AddNameLayer". 
%
% P.G. Bonanni
% 1/12/22

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
if isempty(selections) || (~ischar(selections) && ~iscellstr(selections))
  error('Invalid ''layer'' input.')
end

% If a single name layer provided
if ischar(selections)
  selections = cellstr(selections);
end

% In case one or more 'layer' selections is a source string ...
selections1 = cellfun(@Source2Layer,selections,'Uniform',false);

% Identify existing name layers
layers = GetLayers(obj);

% Check for layer validity
if ~all(ismember(selections1,layers))
  error('Input ''selections'' contains one or more invalid entries.')
end

% List of layers to remove
layersX = setdiff(layers,selections1);

% Perform the removal
obj = RemoveNameLayer(obj,layersX);
