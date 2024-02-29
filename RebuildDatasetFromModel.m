function Data = RebuildDatasetFromModel(DataIn,Data0,layer0)

% REBUILDDATASETFROMMODEL - Rebuild a dataset based on a model.
% Data = RebuildDatasetFromModel(DataIn,Data0,layer0)
% Data = RebuildDatasetFromModel(DataIn,Data0)
%
% Rebuilds dataset 'DataIn' based on a model dataset 'Data0'. The 
% model dataset establishes the signal groups, the order of signals 
% within groups, the name layers, the units specifications, the 
% signal descriptions, and the time grid for the new dataset ('Data').  
% Input 'layer0' specifies the name layer in 'Data0' providing the 
% signal names to be searched in 'DataIn'. Any empty names on this 
% layer result in nan-valued signals in the output dataset.  If the 
% 'layer0' argument is omitted, signals in 'Data0' are identified 
% by their default names (see "GetDefaultNames").  
%
% In the manner specified, names for each signal group are drawn 
% from 'Data0', and the signals within 'DataIn' that match these 
% names are then used to populate the output dataset 'Data'. The 
% signals are then re-sampled as necessary to match the time vector 
% within 'Data0'. 
%
% All non-signal-group fields of 'Data0' are transferred directly 
% to 'Data'.  However, the 'source' field of the new dataset is 
% taken from 'DataIn', if such a field is present, and not from 
% 'Data0'. 
%
% See also "BuildDatasetFromModel". 
%
% P.G. Bonanni
% 2/27/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 3
  layer0 = '';
end

% Check dataset arguments
if numel(DataIn) > 1 || numel(Data0) > 1
  error('Works for scalar datasets only.')
end
[flag1,valid1] = IsDataset(DataIn);
[flag2,valid2] = IsDataset(Data0);
if ~flag1 || ~valid1
  error('Input ''DataIn'' is not a valid dataset.  See "IsDataset".')
elseif ~flag2 || ~valid2
  error('Input ''Data0'' is not a valid dataset.  See "IsDataset".')
end

% Check 'layer0' type
if ~ischar(layer0)
  error('Input ''layer0'' is not valid.')
end

% In case 'layer0' is a source string and non-empty ...
if ~isempty(layer0), layer0=Source2Layer(layer0); end

% Check specified 'layer0' against available layers
if ~isempty(layer0) && ~ismember(layer0,GetLayers(Data0))
  error('Specified ''layer0'' is not present in model.')
end

% Collect info on repeated names in 'DataIn'
Info = CheckNames(DataIn);

% Initialize output dataset
Data = Data0;

% Identify signal groups
[~,groups] = GetSignalGroups(Data);

% Exclude 'Time' from 'groups'
groups1 = setdiff(groups,'Time','stable');

% Build a master signal group from the signal groups in 'DataIn'
Master = CollectSignals(DataIn);

% Number of time points
npoints = size(Master.Values,1);

% Loop over 'groups1' (without 'Time') to populate signal groups
fprintf('Rebuilding dataset ...\n');
for k = 1:length(groups1)
  group = groups1{k};

  % Get signal names for the current group
  if ~isempty(layer0)
    names = Data.(group).(layer0);
  else  % get the default names from the group
    names = GetDefaultNames(Data.(group));
  end
  mask = cellfun(@isempty,names);
  if any(mask)  % Issue warning if empty names are present
    fprintf('There are %d empty name(s) on layer ''%s'' in signal group ''%s''. ',sum(mask),layer0,group);
    fprintf('Substituting NaNs.\n');
  end

  % Number of signals (empty or not)
  nsignals = length(names);

  % Issue a warning if any of the non-empty names are indeterminate within 'DataIn'
  if ~isempty(Info)
    [mask,i] = ismember(names(~cellfun(@isempty,names)),{Info.name});
    Info1 = Info(i(mask));
    if ~isempty(Info1)
      for j = 1:length(Info1)
        [Info1(j).list.name] = deal(Info1(j).name);
      end
      List = cat(1,Info1.list);
      mask = strcmp({List.Status},'DIFFERENT');
      if any(mask)
        fprintf('WARNING: These names for signal group ''%s'' are valued inconsistently in the input dataset.\n',group);
        disp(unique({List(mask).name},'stable'))
      end
    end
  end

  % Initialize 'Values' matrix
  class0 = class(Master.Values);  % preserve original class (single/double)
  Data.(group).Values = nan(npoints,nsignals,class0);

  % Populate with signal data extracted from Master
  [Signals,ismatched] = SelectFromGroup(names,Master);
  mask = cellfun(@isempty,names);
  if any(~mask & ~ismatched)
    fprintf('WARNING: These names for signal group ''%s'' are not available. ',group);
    fprintf('Substituting NaNs.\n');
    disp(names(~mask & ~ismatched))
  end
  Data.(group).Values(:,ismatched) = Signals.Values;
end
fprintf('Done.\n');

% Transfer original 'Time' data and properties, but get new name layers
Data.Time = Data0.Time;  % initialize
Data.Time.Values       = DataIn.Time.Values;
Data.Time.Units        = DataIn.Time.Units;
Data.Time.Descriptions = DataIn.Time.Descriptions;

% Recover the original/absolute time grid if necessary ...
if isfield(DataIn,'start') && ~isempty(DataIn.start) && ...
   ~any(ismember(DataIn.Time.Units,{'datetime','datenum'}))
  if isa(DataIn.start,'datetime')
    Data.Time.Values = DataIn.start + seconds(DataIn.Time.Values);
    Data.Time.Units = {'datetime'};
  elseif DataIn.start > 1e5  % assume 'datenum'
    Data.Time.Values = DataIn.start + DataIn.Time.Values / 86400;
    Data.Time.Units = {'datenum'};
  else  % if a real-valued absolute offset
    Data.Time.Values = DataIn.start + DataIn.Time.Values;
  end
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

% Get 'source' field from 'DataIn', if available
if isfield(DataIn,'source'), Data.source=DataIn.source; end
