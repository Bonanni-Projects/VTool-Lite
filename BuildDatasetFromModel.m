function Data = BuildDatasetFromModel(source,pathnames,Data0)

% BUILDDATASETFROMMODEL - Build a supplementary dataset from a model.
% Data = BuildDatasetFromModel(source,pathnames,Data0)
% Data = BuildDatasetFromModel(layer,pathnames,Data0)
%
% Builds supplementary dataset 'Data' from a new data source, based 
% on a model dataset 'Data0'.  The source for the dataset is determined 
% by 'source', or, alternatively, 'layer', these referring to a column 
% on the "MASTER" tab of "NameTables.xlsx".  Input 'Data0' is a dataset 
% structure with signal-group fields.  This sample dataset establishes 
% the signal groups and the order of signals within groups for the new 
% dataset 'Data'.  The file(s)  from which to extract new data replacing 
% the existing data is specified by string or cell array 'pathnames'.  
% The 'source' field of the new dataset is updated to reflect the new 
% source.  All other non-signal-group fields of 'Data0' are transferred 
% directly to 'Data'. 
%
% Data read from the specified pathnames are subject to units 
% conversions and description changes prescribed in "NameTables.xlsx" 
% on the "sourcetype" tab that corresponds to the determined 'source' 
% ("Sourcetypes" are specified below "sources" on row 2 of the MASTER 
% tab.) However, NO CONVERSION is applied to .vtl files, as these are 
% assumed to be converted in advance, and no conversion is applied 
% if the 'sourcetype' is ''. 
%
% See also "RebuildDatasetFromModel". 
%
% P.G. Bonanni
% 2/18/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'source' and 'pathnames'
if ~ischar(source)
  error('Input ''source'' is invalid.')
elseif (~ischar(pathnames) && ~iscell(pathnames)) || ...
       (iscell(pathnames) && ~all(cellfun(@ischar,pathnames)))
  error('Input ''pathnames'' is invalid.')
end

% Check 'Data0' argument
if numel(Data0) > 1
  error('Works for scalar datasets only.')
end
[flag1,valid1] = IsDataset(Data0);
if ~flag1 || ~valid1
  error('Input ''Data0'' is not a valid dataset.  See "IsDataset".')
end

% Initialize output dataset
Data = Data0;

% Derive 'layer' from source string
layer = Source2Layer(source);

% In case 'source' was a layer string ...
source = Layer2Source(layer);

% Add a new name layer to the dataset
Data = AddNameLayer(Data,layer);

% Identify signal groups
[~,groups] = GetSignalGroups(Data);

% Empty the 'Values' fields of all groups
for k = 1:length(groups)
  group = groups{k};
  Data.(group).Values = [];
end

% Exclude 'Time' from 'groups'
groups1 = setdiff(groups,'Time','stable');

% Read MASTER Look-Up Table from Excel file
[~,SourceType,~] = ReadMasterLookup;

% Map specified source to a "source type"
sourcetype = SourceType.(layer);
if isempty(sourcetype)
  fprintf('NOTE: Sourcetype is ''''.\n');
end

% If single pathname specified
if ischar(pathnames)
  pathnames = cellstr(pathnames);
end

% Loop over pathnames
for i = 1:length(pathnames)
  pathname = pathnames{i};
  fprintf('Reading file "%s" for source type ''%s''.\n', pathname,sourcetype);

  % Extract data according to sourcetype
  s = ExtractData(pathname,sourcetype);

  % Build a master signal group from the signal groups in 's'
  Master = CollectSignals(s);

  % Number of time points
  npoints = size(Master.Values,1);

  % Loop over 'groups1' (without 'Time') to populate signal groups
  fprintf('Populating signal groups ...\n');
  for k = 1:length(groups1)
    group = groups1{k};

    % Get signal names for the current group
    names = Data.(group).(layer);
    mask = cellfun(@isempty,names);
    if any(mask)  % Issue warning if empty names are present
      fprintf('There are %d empty name(s) on layer ''%s'' in signal group ''%s''. ',sum(mask),layer,group);
      fprintf('Substituting NaNs.\n');
    end

    % Number of signals (empty or not)
    nsignals = length(names);

    % Initialize 'Values' matrix
    class0 = class(Master.Values);  % preserve original class (single/double)
    Data1.(group).Values = nan(npoints,nsignals,class0);

    % Populate with signal data extracted from Master
    [Signals,ismatched] = SelectFromGroup(names,Master);
    if any(~mask & ~ismatched)
      fprintf('WARNING: These names for signal group ''%s'' are not available. ',group);
      fprintf('Substituting NaNs.\n');
      disp(names(~mask & ~ismatched))
    end
    Data1.(group).Values(:,ismatched) = Signals.Values;

    % Concatenate
    Data.(group).Values = [Data.(group).Values; Data1.(group).Values];
  end
  fprintf('Done.\n');

  % Concatenate time data in a similar manner, but using s.Time. 
  % Also, take units and description from the read-in data. 
  Data.Time.Values = [Data.Time.Values; s.Time.Values];
  Data.Time.Units        = s.Time.Units;
  Data.Time.Descriptions = s.Time.Descriptions;
end

% Recover the absolute time grid for the model dataset, if necessary ...
if isfield(Data0,'start') && ~any(ismember(Data0.Time.Units,{'datetime','datenum'}))
  if isa(Data0.start,'datetime')
    tvec = Data0.start + seconds(Data0.Time.Values);
  elseif Data0.start > 1e5  % assume 'datenum'
    tvec = Data0.start + Data0.Time.Values / 86400;
  else  % if a real-valued absolute offset
    tvec = Data0.start + Data0.Time.Values;
  end
else  % ... or use the provided time vector
  tvec = Data0.Time.Values;
end

% Resample the dataset onto the applicable grid
Data = ResampleDataset(Data, tvec);

% Apply the 'Time' info from the model
Data.Time = Data0.Time;

% Rename 'pathname' field to 'pathnames', if necessary
if ismember('pathname',fieldnames(Data))
  fprintf('Renaming ''pathname'' field to ''pathnames''.\n');
  fields = fieldnames(Data);  C = struct2cell(Data);
  fields{strcmp('pathname',fields)} = 'pathnames';
  Data = cell2struct(C,fields,1);
end

% Revise 'pathnames' and 'source' fields
Data.pathnames = pathnames;
Data.source    = source;
