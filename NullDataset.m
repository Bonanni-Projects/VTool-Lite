function Data = NullDataset(Data,option)

% NULLDATASET - Build a null dataset from a model.
% Data = NullDataset(Data)
% Data = NullDataset(Data,'groups')
%
% Returns a null dataset modeled on a given input dataset.  The 
% output dataset contains the same structure as the input dataset, 
% but the signal group data arrays are set to all NaN, and the 
% non-signal group fields are set to [].  However, if the 'groups' 
% option is specified, the nulling operation is limited to the 
% signal group data only, and the non-signal group fields are 
% left unchanged. 
% 
% The 'Time' signal group is always retained, and signal names 
% on all name layers are preserved.  Signal units and descriptions 
% are also unchanged. 
%
% P.G. Bonanni
% 3/29/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  option = '';
end

% Check 'Data' argument
if numel(Data) > 1
  error('Works for scalar datasets only.')
end
[flag,valid] = IsDataset(Data);
if ~flag || ~valid
  error('Input ''Data'' is not a valid dataset.  See "IsDataset".')
end

% Check 'option' argument
if ~ischar(option) || (~isempty(option) && ~strcmp(option,'groups'))
  error('Invalid ''option'' argument.')
end

% Identify signal-group fields
[~,groups] = GetSignalGroups(Data);

% Exclude 'Time'
groups = setdiff(groups,'Time','stable');

% Loop over signal groups
for k = 1:length(groups)
  group = groups{k};

  % Set Values array to all NaNs
  Data.(group).Values = nan(size(Data.(group).Values));
end

% Stop here if 'groups' option specified
if strcmp(option,'groups'), return, end

% Set top-level fields to []
fields = fieldnames(Data);
fields = setdiff(fields,['Time'; groups]);
for k = 1:length(fields)
  field = fields{k};
  Data.(field) = [];
end
