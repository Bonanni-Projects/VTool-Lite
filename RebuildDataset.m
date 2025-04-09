function Data = RebuildDataset(DataIn,groups,layers,layer0)

% REBUILDDATASET - Rebuild a dataset based on NameTables.
% Data = RebuildDataset(DataIn,groups,layers,layer0)
% Data = RebuildDataset(DataIn,groups,layers)
%
% Rebuilds dataset 'DataIn' based on signal groups and name layers 
% defined in "NameTables.xlsx".  Cell array 'groups' specifies the 
% list of desired groups, and 'layers' specifies the desired layers. 
% Input 'layer0' specifies the name layer providing the signal names 
% to be searched in 'DataIn'.  Any empty names on this layer result 
% in nan-valued signals in the output dataset.  The 'layer0' input 
% may be omitted if 'layers' has only one entry. 
%
% Names for each signal group are drawn from the relevant column 
% on the MASTER tab of NameTables, and the signals within 'DataIn' 
% that match these names are then used to populate the output dataset 
% 'Data'. All non-signal-group fields of 'DataIn' are preserved in 
% the output dataset. 
%
% See also "BuildDataset", "RebuildDatasetFromModel". 
%
% P.G. Bonanni
% 2/27/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 4
  layer0 = '';
end

% Check 'DataIn' argument
if numel(DataIn) > 1
  error('Works for scalar datasets only.')
end
[flag1,valid1] = IsDataset(DataIn);
if ~flag1 || ~valid1
  error('Input ''DataIn'' is not a valid dataset.  See "IsDataset".')
end

% Check 'layer0' type
if ~ischar(layer0)
  error('Input ''layer0'' is not valid.')
end

% Make rows
groups = groups(:)';
layers = layers(:)';

% Check 'groups' and 'layers' inputs
if ~iscell(groups) || isempty(groups) || ~all(cellfun(@ischar,groups))
  error('Input ''groups'' invalid or not specified.')
elseif ~iscell(layers) || isempty(layers) || ~all(cellfun(@ischar,layers))
  error('Input ''layers'' invalid or not specified.')
end

% Remove any duplicates from 'groups' and 'layers'
groups = unique(groups,'stable');
layers = unique(layers,'stable');

% Allow source strings to be mixed in with layer names
layers = cellfun(@Source2Layer,layers,'Uniform',false);

% In case 'layer0' is a source string and non-empty ...
if ~isempty(layer0), layer0=Source2Layer(layer0); end

% Check specified 'layer0'
if isempty(layer0) && length(layers) > 1
  error('Input ''layer0'' must be specified if ''layers'' contains more than one entry.')
elseif ~isempty(layer0) && ~ismember(layer0,layers)
  error('Specified ''layer0'' is not present in the ''layers'' list.')
end

% If default 'layer0' is required
if isempty(layer0), layer0=layers{1}; end

% Read MASTER Look-Up Table from Excel file
[Names,~,Layers] = ReadMasterLookup;
Groups = fieldnames(Names);

% Form two lists from the list of specified 'groups': 
% 'groups' always includes 'Time' as first element
% 'groups1' contains all groups except 'Time'
groups1 = setdiff(groups,'Time','stable');  % keep the specified order
groups = ['Time',groups1];                  % add 'Time' back in, as the first entry

% Check if valid groups and layers are specified
mask1 = ~ismember(groups1,Groups);
mask2 = ~ismember(layers,Layers);
if any(mask1)
  fprintf('Invalid group(s): '), disp(groups1(mask1))
  error('One or more invalid ''groups'' entry specified.')
elseif any(mask2)
  fprintf('Invalid layer(s): '), disp(layers(mask2))
  error('One or more invalid ''layers'' entry specified.')
end

% Re-order the layers to the standard order
layers = intersect(Layers,layers,'stable');

% Add 'Time' to 'Names' structure
Names.Time = cell2struct(repmat({{'Time'}},length(Layers),1),Layers,1);

% Initialize data structure based on 'groups' and 'layers' (including 'Time')
Data = rmfield(Names,setdiff(Groups,groups));
Data = orderfields(Data,groups);
for k = 1:length(groups)
  group = groups{k};
  Data.(group) = rmfield(Data.(group),setdiff(Layers,layers));
  Data.(group) = orderfields(Data.(group),layers);
end

% Populate the 'Time' group separately (because it may be of special type)
Data.Time.Values       = DataIn.Time.Values;
Data.Time.Units        = DataIn.Time.Units;
Data.Time.Descriptions = DataIn.Time.Descriptions;

% Build a master signal group from the signal groups in 'DataIn'
Master = CollectSignals(DataIn);

% Number of time points
npoints = size(Master.Values,1);

% Loop over 'groups1' (without 'Time') to populate remaining signal groups
fprintf('Rebuilding dataset ...\n');
for k = 1:length(groups1)
  group = groups1{k};

  % Get signal names for the current group
  names = Data.(group).(layer0);
  mask = cellfun(@isempty,names);
  if any(mask)  % Issue warning if empty names are present
    fprintf('There are %d empty name(s) on layer ''%s'' in signal group ''%s''. ',sum(mask),layer0,group);
    fprintf('Substituting NaNs.\n');
  end

  % Number of signals (empty or not)
  nsignals = length(names);

  % Initialize
  class0 = class(Master.Values);  % preserve original class (single/double)
  Data.(group).Values       = nan(npoints,nsignals,class0);
  Data.(group).Units        = repmat({''},nsignals,1);
  Data.(group).Descriptions = repmat({''},nsignals,1);

  % Populate with signal data extracted from Master
  [Signals,ismatched] = SelectFromGroup(names,Master);
  if any(~mask & ~ismatched)
    fprintf('WARNING: These names for signal group ''%s'' are not available. ',group);
    fprintf('Substituting NaNs.\n');
    disp(names(~mask & ~ismatched))
  end
  Data.(group).Values(:,ismatched)     = Signals.Values;
  Data.(group).Units(ismatched)        = Signals.Units;
  Data.(group).Descriptions(ismatched) = Signals.Descriptions;
end
fprintf('Done.\n');

% Add non-signal group fields
[~,groupsIn] = GetSignalGroups(DataIn);
fields = setdiff(fieldnames(DataIn),groupsIn,'stable');
for k = 1:length(fields)
  field = fields{k};
  Data.(field) = DataIn.(field);
end

% Re-order the fields
[~,groups] = GetSignalGroups(Data);
Data = orderfields(Data,[fields;groups]);

% If present, make 'source' field last
if isfield(Data,'source')
  source = Data.source;
  Data = rmfield(Data,'source');
  Data.source = source;
end
