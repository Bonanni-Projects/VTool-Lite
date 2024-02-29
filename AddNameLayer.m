function obj = AddNameLayer(obj,selections,option)

% ADDNAMELAYER - Add a new name layer to a dataset or signal group.
% Data = AddNameLayer(Data,layer)
% Data = AddNameLayer(Data,{'layer1','layer2',...})
% Data = AddNameLayer(...,'null')
% DATA = AddNameLayer(DATA, ...)
% Signals = AddNameLayer(Signals, ...)
% SIGNALS = AddNameLayer(SIGNALS, ...)
%
% Accepts a dataset 'Data', dataset array 'DATA', signal group 'Signals', 
% or signal group array 'SIGNALS', and adds a new name layer to all signal 
% groups, to correspond with the existing name layers.  The name layer is 
% populated based on information on the "MASTER" tab of "NameTables.xlsx". 
% Each new name is drawn from the first row within the NameTables that 
% yields a match to the names in the existing name layers. 
%
% The new name layer is specified by input string 'layer', which refers 
% to the column in the MASTER table from which the new names are drawn. 
% If "NameTables.xlsx" does not exist, or if 'layer' is not a registered 
% MASTER tab column, a new name layer with all blank names is added.  
% This behavior can also be forced by specifying the 'null' option as 
% a final argument. 
%
% Also accepts a cell array of layer names.  Any entries in the array 
% that are already part of the dataset are ignored. 
%
% See also "RemoveNameLayer", "AddMissingLayers". 
%
% P.G. Bonanni
% 2/18/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 3
  option = '';
end

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

% Check 'layer' argument
if ~ischar(selections) && ~iscellstr(selections)
  error('Invalid ''layer'' input.')
end

% Make cell array
if ischar(selections)
  selections = cellstr(selections);
end

% Make column
selections = selections(:);

% Read NameTables if available and 'null' option not chosen
if exist('NameTables.xlsx','file') && ~strcmp(option,'null')
  % Read MASTER Look-Up Table from Excel file
  [~,~,Layers,ALLNAMES0] = ReadMasterLookup;
else
  Layers = {};
end

% In case any selections are source strings
selections = cellfun(@Source2Layer,selections,'Uniform',false);

% Re-sort selections to place recognized name layers first
mask = ismember(selections,Layers);
selections = [selections(mask); selections(~mask)];

% Loop over layer names
for k = 1:length(selections)
  layer = selections{k};

  % Identify existing name layers
  layers = GetLayers(obj);

  % Skip if layer is already present
  if ismember(layer,layers), continue, end

  % Initialize the name layer with blank names
  obj = AddBlankNameLayer(obj,layer);

  % If NameTables exists and 'layer' is recognized ...
  if exist('NameTables.xlsx','file') && any(ismember(layers,Layers)) && ismember(layer,Layers)

    % Initialize/reset 'ALLNAMES' array
    ALLNAMES = ALLNAMES0;

    % Extract the new layer from 'ALLNAMES'
    [~,i] = ismember(layer,Layers);
    NewNames = ALLNAMES(:,i);

    % Reduce 'ALLNAMES' to include the recognized original layers only
    [maskL,i] = ismember(layers,Layers);
    ALLNAMES = ALLNAMES(:,i(maskL));

    % ----------------------------------
    % Populate the name layer
    % ----------------------------------

    % Populate according to input type
    if IsDatasetArray(obj)  % if scalar dataset or dataset array
      DATA = obj;

      % Identify signal-group fields
      [~,groups] = GetSignalGroups(DATA(1));
      groups = setdiff(groups,'Time','stable');

      % Loop over signal groups
      for j = 1:length(groups)
        group = groups{j};

        % Collect existing signal names - all signals and all layers
        NAMES = GetNamesMatrix(DATA(1).(group));
        NAMES = NAMES(:,1:end-1);  % new layer excluded
        NAMES = NAMES(:,maskL);    % recognized layers only

        % Locate 'NAMES' within 'ALLNAMES'
        C1 = num2cell(NAMES,1);    C1=strcat(C1{:});
        C2 = num2cell(ALLNAMES,1); C2=strcat(C2{:});
        [mask,i] = ismember(C1,C2);
        if any(~mask)
          index = find(i==0);
          fprintf('These name combination(s) are not recognized: ');
          for j = index', disp(NAMES(j,:)), end
          fprintf('Leaving the corresponding entry(ies) in layer ''%s'' blank.\n',layer)
        end

        % Extract and append the new layer
        names = repmat({''},size(mask));  % initialize
        [names{mask}] = deal(NewNames{i(mask)});
        for i = 1:numel(DATA)
          DATA(i).(group).(layer) = names;
        end
      end

      % Re-order fields to standard order
      DATA = ReorderFields(DATA);

      % Output
      obj = DATA;

    % otherwise ...
    elseif IsSignalGroupArray(obj)  % if scalar signal group, or signal group array
      SIGNALS = obj;

      % Collect existing signal names - all signals and all layers
      NAMES = GetNamesMatrix(SIGNALS(1));
      NAMES = NAMES(:,1:end-1);  % new layer excluded
      NAMES = NAMES(:,maskL);    % recognized layers only

      % Locate 'NAMES' within 'ALLNAMES'
      C1 = num2cell(NAMES,1);    C1=strcat(C1{:});
      C2 = num2cell(ALLNAMES,1); C2=strcat(C2{:});
      [mask,i] = ismember(C1,C2);
      if any(~mask)
        index = find(i==0);
        fprintf('These name combination(s) are not recognized: ');
        for j = index', disp(NAMES(j,:)), end
        fprintf('Leaving the corresponding entry(ies) in layer ''%s'' blank.\n',layer)
      end

      % Extract and append the new layer
      names = repmat({''},size(mask));  % initialize
      [names{mask}] = deal(NewNames{i(mask)});
      [SIGNALS.(layer)] = deal(names);

      % Re-order fields to standard order
      SIGNALS = ReorderFields(SIGNALS);

      % Output
      obj = SIGNALS;
    end
  end
end



% -----------------------------------------------------------------------
function obj = AddBlankNameLayer(obj,layer)

% Adds the specified name 'layer' to the input object, using 
% all blank names.  The object is assumed to be a valid dataset, 
% signal group, dataset array, or signal group array, and the 
% name layer is assumed not already present.

% Identify existing name layers
layers = GetLayers(obj);

% Add new name layer to list
layers = [layers; layer];

% Derive the new fieldname order
fields1 = [layers',{'Values','Units','Descriptions'}];

% Perform the layer addition according to input type
if IsDatasetArray(obj)  % if scalar dataset or dataset array
  DATA = obj;

  % Identify signal-group fields
  [~,groups] = GetSignalGroups(DATA(1));

  % Special treatment for the 'Time' field
  for i = 1:numel(DATA)
    DATA(i).Time.(layer) = DATA(i).Time.(layers{1});
    DATA(i).Time = orderfields(DATA(i).Time, fields1);
  end

  % Loop over remaining signal groups
  groups = setdiff(groups,'Time','stable');
  for j = 1:length(groups)
    group = groups{j};

    % Append the new layer
    for i = 1:numel(DATA)
      DATA(i).(group).(layer) = repmat({''},size(DATA(i).(group).Units));
      DATA(i).(group) = orderfields(DATA(i).(group), fields1);
    end
  end

  % Output
  obj = DATA;

% otherwise ...
elseif IsSignalGroupArray(obj)  % if scalar signal group, or signal group array
  SIGNALS = obj;

  % Append the new layer
  n = size(SIGNALS(1).Units,1);
  [SIGNALS.(layer)] = deal(repmat({''},n,1));
  SIGNALS = orderfields(SIGNALS, fields1);

  % Output
  obj = SIGNALS;
end
