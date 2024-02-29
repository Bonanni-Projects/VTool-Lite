function Signals = CollectSignals(Data)

% COLLECTSIGNALS - Collect signals from a dataset into a master group.
% Signals = CollectSignals(Data)
%
% Given dataset 'Data' containing one or more "signal groups" 
% (see "BuildDataset"), collect all signals into a master signal 
% group and return as output structure 'Signals'.  The 'Time' 
% signal group and any fields of 'Data' that are not of "signal 
% group" type are ignored. 
%
% P.G. Bonanni
% 1/26/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'Data' argument
if numel(Data) > 1
  error('Works for scalar datasets only.')
end
[flag,valid] = IsDataset(Data);
if ~flag || ~valid
  error('Input ''Data'' is not a valid dataset.  See "IsDataset".')
end

% Exclude the 'Time' group (because it is potentially 
% of different type than the other groups)
Data = rmfield(Data,'Time');

% Get signal groups and group names
[s,fields] = GetSignalGroups(Data);
if isempty(fields)
  error('Input structure has no signal-group fields.')
end

% Ensure all field names of the groups are identical
Fieldnames = cellfun(@fieldnames,struct2cell(s),'Uniform',false);
Fieldnames = cellfun(@sort,Fieldnames,'Uniform',false);
if length(Fieldnames)>1 && ~all(isequal(Fieldnames{:}))
  error('Signal groups must have matching fields.')
end

% Make a structure array from the signal groups
C = struct2cell(s);  % cell array of groups
S = cat(1,C{:});     % structure array

% Ensure all signal data types are identical
Class = cellfun(@class,{S.Values},'Uniform',false);
if length(Class)>1 && ~isequal(Class{:})
  error('Signal groups must have matching data types.')
end

% Combine groups into a single group
fields = fieldnames(S);
for k = 1:length(fields)
  if strcmp(fields{k},'Values')
    Signals.(fields{k}) = cat(2, S.(fields{k}));
  else  % all other fields
    Signals.(fields{k}) = cat(1, S.(fields{k}));
  end
end
