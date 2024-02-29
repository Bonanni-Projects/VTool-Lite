function DisplayDataset(Data)

% DISPLAYDATASET - Display contents of a dataset.
% DisplayDataset(Data)
%
% Displays the contents of a dataset to the screen in 
% tabular form, showing descriptions of all fields and 
% signal groups.
%
% P.G. Bonanni
% 3/30/18

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

% Show structure
disp(Data)

% List the signal groups
[~,groups] = GetSignalGroups(Data);

% Display each group
for k = 1:length(groups)
  group = groups{k};
  fprintf('\n');
  fprintf('%s:\n',group);
  DisplaySignalGroup(Data.(group))
end

% Display time vector statistics
fprintf('\n');
fprintf('Time Statistics:\n')
if ~isempty(Data.Time.Values)
  DisplaySampleTime(Data.Time)
else
  disp('(empty)')
end
