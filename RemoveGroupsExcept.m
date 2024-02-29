function DATA = RemoveGroupsExcept(selections,DATA)

% REMOVEGROUPSEXCEPT - Remove extra signal groups.
% Data = RemoveGroupsExcept(selections,Data)
% DATA = RemoveGroupsExcept(selections,DATA)
%
% Removes extra signal groups from a dataset or dataset array, 
% leaving only the list of signal groups specified by 'selections', 
% and returns the resulting dataset (or dataset array) as output. 
% Input 'selections' may be provided as a single character string 
% (if a single group name), or a cell array of same.  Specifying [] 
% or {} removes all groups (except 'Time', which is always excluded 
% from removal).  All entries in 'selections' must be present in the 
% input dataset. 
%
% P.G. Bonanni
% 1/18/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'Data' or 'DATA' input
[flag,valid,errmsg] = IsDatasetArray(DATA);
if ~flag
  error('Input #2 is not a dataset or dataset array: %s',errmsg)
elseif ~valid
  error('Input #2 is not a valid dataset or dataset array: %s  See "IsDataset".',errmsg)
end

% If a single group name provided
if ischar(selections)
  selections = cellstr(selections);
end

% If selections=[], interpret as {}
if isnumeric(selections) && isempty(selections)
  selections = {};
end

% Get list of existing groups
[~,groups] = GetSignalGroups(DATA(1));

% Check 'selections' input
if ~iscellstr(selections)
  error('Invalid ''selections'' input.')
elseif ~isempty(selections) && ~all(ismember(selections,groups))
  error('Input ''selections'' contains one or more unrecognized entries.')
end

% List of groups to remove
groupsX = setdiff(groups,union('Time',selections));

% Perform the removal
DATA = rmfield(DATA,groupsX);
