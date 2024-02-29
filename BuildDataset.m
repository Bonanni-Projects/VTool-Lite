function Data = BuildDataset(casename,pathnames,groups,layers,source)

% BUILDDATASET - Build a signal evaluation dataset based on NameTables.
% Data = BuildDataset(casename,pathnames,groups,layers,source)
% Data = BuildDataset(casename,pathnames,groups,layers)
%
% Builds a "signal evaluation dataset" based on definition information 
% recorded in "NameTables.xlsx".  The result is a structure containing 
% one or more "signal groups" as fields, where each signal group is 
% itself a structure with fields:
%    '<Layer1>Names'  -  cell array of "Layer 1" signal names, 
%    '<Layer2>Names'  -  cell array of "Layer 2" signal names, 
%       ...           -  cell array of ...       signal names,
%    '<LayerN>Names'  -  cell array of "Layer N" signal names, 
%    'Values'         -  matrix with columns containing signal sequences, 
%    'Units'          -  cell array of unit designations ('m', 'kN', etc.), 
%    'Descriptions'   -  cell array of signal descriptions. 
% where the number of signal channels defines the length of the 
% cell arrays and the number of columns in the 'Values' field. 
%
% The signal groups included in the output structure are specified 
% by input cell array 'groups', and the signals contained in these 
% groups are defined on the "MASTER" tab of "NameTables.xlsx".  
%
% Each signal group includes one or more "name layers", specified 
% by input cell array 'layers'.  These refer to column headers also 
% appearing on the "MASTER" tab spreadsheet.  The signal names from 
% these columns are used to populate the various 'Names' fields, so 
% that each signal can be associated with one or more names. However, 
% the data used to populate the 'Values' field comes from a single 
% source, that source being either specified directly, via the 
% 'source' argument, or defined by the "primary" name layer, which 
% is taken to be the first layer specified in 'layers' if 'source' 
% is not specified. 
%
% The file(s) from which the data are drawn are given by input 
% 'pathnames', which can be either a single string pathname or 
% a cell array of pathnames.  In the latter case, data from 
% successive files are concatenated.  Any file formats supported 
% by "ExtractData" are permissible, and file formats need not be 
% the same for all pathnames. 
%
% Data read from the specified pathnames are subject to units 
% conversions and description changes prescribed in "NameTables.xlsx" 
% on the "sourcetype" tab that corresponds to the determined 'source' 
% ("Sourcetypes" are specified below "sources" on row 2 of the MASTER 
% tab.) However, NO CONVERSION is applied to .vtl files, as these are 
% assumed to be converted in advance, and no conversion is applied 
% if the 'sourcetype' is ''. 
%
% Though not listed in "NameTables.xlsx", a signal group 'Time' is 
% always included in the output structure, with fields paralleling 
% those of the other signal groups.  Time is returned in either 
% real-valued or absolute date-time units, depending on the input 
% file type. 
%
% Input 'casename' is a user-specified identification string, which 
% is returned as the first field of the output structure, along with 
% a 'pathnames' field to record the data file(s) read.  A final field 
% 'source' is also included.  The source string is derived by removing 
% the final "Names" characters from the primary, or source, name layer.
%
% P.G. Bonanni
% 2/13/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 5
  source = [];
end

% Check 'casename' and 'pathnames'
if ~ischar(casename)
  error('Input ''casename'' is invalid.')
elseif (~ischar(pathnames) && ~iscell(pathnames)) || ...
       (iscell(pathnames) && ~all(cellfun(@ischar,pathnames)))
  error('Input ''pathnames'' is invalid.')
end

% Make rows
groups = groups(:)';
layers = layers(:)';

% Check 'groups' and 'layers' inputs
if ~iscell(groups) || isempty(groups) || ~all(cellfun(@ischar,groups))
  error('Input ''groups'' is invalid or not specified.')
elseif ~iscell(layers) || isempty(layers) || ~all(cellfun(@ischar,layers))
  error('Input ''layers'' is invalid or not specified.')
end

% Remove any duplicates from 'groups' and 'layers'
groups = unique(groups,'stable');
layers = unique(layers,'stable');

% Allow source strings to be mixed in with layer names
layers = cellfun(@Source2Layer,layers,'Uniform',false);

% Read MASTER Look-Up Table from Excel file
[Names,SourceType,Layers] = ReadMasterLookup;
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

% If 'source' specified ...
if ~isempty(source)
  % ... the "primary layer" is determined by 
  layer1 = Source2Layer(source);

  % In case 'source' was a layer string ...
  source = Layer2Source(layer1);

  % If primary layer not present, add it
  if ~ismember(layer1,layers), layers=[layer1,layers]; end
else
  % First name layer is the "primary layer"
  layer1 = layers{1};

  % Derive 'source' string from the primary layer
  source = Layer2Source(layer1);

  % Warn the user
  fprintf('Input ''source'' not specified.  Assuming ''%s'' as source.\n',layer1);
end

% Re-order the layers to the standard order
layers = intersect(Layers,layers,'stable');

% Map specified source to a "source type"
sourcetype = SourceType.(layer1);
if isempty(sourcetype)
  fprintf('NOTE: Sourcetype is ''''.\n');
end

% Add 'Time' to 'Names' structure
Names.Time = cell2struct(repmat({{'Time'}},length(Layers),1),Layers,1);

% If single pathname specified
if ischar(pathnames)
  pathnames = cellstr(pathnames);
end

% Loop over pathnames
for i = 1:length(pathnames)
  pathname = pathnames{i};
  fprintf('Reading file "%s" for source type ''%s''.\n', pathname,sourcetype);

  % Initialize data structure based on 'groups' and 'layers' (including 'Time')
  Data1 = rmfield(Names,setdiff(Groups,groups));
  Data1 = orderfields(Data1,groups);
  for k = 1:length(groups)
    group = groups{k};
    Data1.(group) = rmfield(Data1.(group),setdiff(Layers,layers));
    Data1.(group) = orderfields(Data1.(group),layers);
  end

  % Extract data according to sourcetype
  s = ExtractData(pathname,sourcetype,'nowarn');

  % Populate the 'Time' group separately (because it may be of special type)
  Data1.Time.Values       = s.Time.Values;
  Data1.Time.Units        = s.Time.Units;
  Data1.Time.Descriptions = s.Time.Descriptions;

  % Build a master signal group from the signal groups in 's'
  Master = CollectSignals(s);

  % Number of time points
  npoints = size(Master.Values,1);

  % Loop over 'groups1' (without 'Time') to populate remaining signal groups
  fprintf('Populating signal groups ...\n');
  for k = 1:length(groups1)
    group = groups1{k};

    % Get signal names for the current group
    names = Data1.(group).(layer1);
    mask = cellfun(@isempty,names);
    if any(mask)  % Issue warning if empty names are present
      fprintf('There are %d empty name(s) on layer ''%s'' in signal group ''%s''. ',sum(mask),layer1,group);
      fprintf('Substituting NaNs.\n');
    end

    % Number of signals (empty or not)
    nsignals = length(names);

    % Initialize
    class0 = class(Master.Values);  % preserve original class (single/double)
    Data1.(group).Values       = nan(npoints,nsignals,class0);
    Data1.(group).Units        = repmat({''},nsignals,1);
    Data1.(group).Descriptions = repmat({''},nsignals,1);

    % Populate with signal data extracted from Master
    [Signals,ismatched] = SelectFromGroup(names,Master);
    if any(~mask & ~ismatched)
      fprintf('WARNING: These names for signal group ''%s'' are not available. ',group);
      fprintf('Substituting NaNs.\n');
      disp(names(~mask & ~ismatched))
    end
    Data1.(group).Values(:,ismatched)     = Signals.Values;
    Data1.(group).Units(ismatched)        = Signals.Units;
    Data1.(group).Descriptions(ismatched) = Signals.Descriptions;
  end
  fprintf('Done.\n');

  % Concatenate
  if i == 1
    Data = Data1;
  else
    for k = 1:length(groups)
      group = groups{k};
      Data.(group).Values = [Data.(group).Values; Data1.(group).Values];
    end
  end
end

% Add attribute fields
Data.casename = casename;
Data.pathnames = pathnames;
[~,groups] = GetSignalGroups(Data);  % list groups successfully added
Data = orderfields(Data,['casename','pathnames',groups(:)']);
Data.source = source;
