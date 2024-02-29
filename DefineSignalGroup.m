function Data = DefineSignalGroup(Data,group,names,option)

% DEFINESIGNALGROUP - Define a new signal group on a dataset.
% Data = DefineSignalGroup(Data,group,names)
% Data = DefineSignalGroup(Data,group,names,'nowarn')
% Data = DefineSignalGroup(Data,group)
%
% Defines a new signal group on dataset 'Data', or re-defines an 
% existing signal group, based on a list of signal names present 
% on the dataset.  Input 'group' specifies the group name to be 
% defined (or re-defined), and 'names' is the list of signal names.  
% Each entry in 'names' is a signal name drawn from any name layer 
% present in 'Data'. 
%
% If 'names' contains empty names, or names not found in the input 
% dataset, then placeholder signals are included in the new (or 
% re-defined) group at the corresponding locations.  The placeholder 
% signals are assigned all-NaN signal values, and the given names are 
% recorded on all name layers.  These conditions normally result in 
% warnings, but the 'nowarn' option may be specified to suppress 
% the warnings. 
%
% The 'names' list may also be specified as {} or omitted entirely. 
% This produces a signal group that is initialized with zero signals, 
% with all name layers represented. 
%
% P.G. Bonanni
% 2/18/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin == 3
  option = '';
elseif nargin == 2
  names  = {};
  option = '';
end

% Check inputs #2 and #3
if ~ischar(group)
  error('Input ''group'' is not valid.')
elseif ~iscellstr(names) && ~ischar(names)
  error('Input ''names'' is not valid.')
end

% Check for group names on input #1
[~,groups] = GetSignalGroups(Data);

% Check for 'Time' group
if ~ismember('Time',groups)
  error('Input ''Data'' is not valid.  The ''Time'' group is missing.')
end

% If input 'Data' contains 'Time' only ...
if numel(groups) == 1        % (only 'Time' possible here)
  Data.(group) = Data.Time;  % temporary; ensures 'Data' is a valid dataset
  Data.(group).Values = nan(size(Data.(group).Values));
  option = 'nowarn';  % suppress warnings in this case
end

% Make cell array
if ischar(names)
  names = cellstr(names);
end

% Make column
names = names(:);

% Identify name layers
layers = GetLayers(Data);

% Collect signal groups into a master signal group
Master = CollectSignals(Data);

% Note and account for any empty names
mask = cellfun(@isempty,names);
if any(mask)  % If empty names are present ...
  if ~strcmp(option,'nowarn')  % issue a warning unless 'nowarn' is specified
    fprintf('WARNING: There are %d empty name(s) in the new signal group ''%s''. ',sum(mask),group);
    fprintf('Substituting NaNs.\n');
  end

  % Append a signal named '' to the master signal group
  for k = 1:length(layers), Master.(layers{k}){end+1,1} = ''; end
  class0 = class(Master.Values);  % preserve original class (single/double)
  Master.Values(:,end+1) = nan(1,class0);
  Master.Units{end+1,1} = '';
  Master.Descriptions{end+1,1} = '';
end

% Make a new group with signal data extracted from Master
[Signals,ismatched] = SelectFromGroup(names,Master);
if any(~ismatched)
  names1 = names(~mask & ~ismatched);  n=length(names1);
  if ~isempty(names1) && ~strcmp(option,'nowarn')  % issue a warning unless 'nowarn' is specified
    fprintf('WARNING: These signals for the new signal group ''%s'' are not available. ',group);
    fprintf('Adding names to all layers, and substituting NaNs.\n');
    disp(names1)
  end

  % Append placeholders for the unmatched signals to the master signal group
  for k = 1:length(layers), Master.(layers{k})(end+(1:n),1) = names1; end
  class0 = class(Master.Values);  % preserve original class (single/double)
  Master.Values(:,end+(1:n)) = nan(1,class0);
  [Master.Units{end+(1:n),1}] = deal('');
  [Master.Descriptions{end+(1:n),1}] = deal('');

  % Re-select signals from Master
  Signals = SelectFromGroup(names,Master);
end
Data.(group) = Signals;

% Move 'source' field to end
if isfield(Data,'source')
  source = Data.source;
  Data = rmfield(Data,'source');
  Data.source = source;
end
