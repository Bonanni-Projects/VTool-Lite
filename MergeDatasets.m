function Data = MergeDatasets(varargin)

% MERGEDATASETS - Merge two or more datasets into one.
% Data = MergeDatasets(Data1,Data2,...)
% Data = MergeDatasets(Data1,Data2,...,'nowarn')
%
% Merges two or more input datasets ('Data1','Data2',...) 
% into one output dataset 'Data'.  The input datasets 
% must have identical 'Time' groups.  The order of signal 
% groups within the dataset sequence is preserved in the 
% output.  If signal groups with the same name occur, the 
% later ones in the sequence overwrite the earlier ones 
% encountered, and a warning is issued.  The 'nowarn' 
% option may be specified to suppress this warning. 
%
% Non-signal-group fields from 'Data1' are preserved 
% in the output dataset, but those occurring in the 
% remaining arguments are ignored. 
%
% P.G. Bonanni
% 5/30/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


args = varargin;
if length(args) < 1
  error('Invalid usage.')
end
option = '';
if ischar(args{end}) && strcmp(args{end},'nowarn')
  option = 'nowarn';
  args(end) = [];
end
if length(args) < 1
  error('Invalid usage.')
end

% Check input validity
n = arrayfun(@numel,args);
if any(n > 1)
  error('Works for scalar datasets only.')
end
[flag,valid] = cellfun(@IsDataset,args);
if ~all(flag) || ~all(valid)
  error('One or more inputs is not a valid dataset.  See "IsDataset".')
end

% Number of inputs
ninputs = length(args);

% Check name-layer compatibility
Layers = cellfun(@GetLayers,args,'Uniform',false);
if ninputs > 1 && ~isequal(Layers{:})
  error('Inputs have incompatible name layers.')
end

% Check signal-length compatibility
len = cellfun(@(x)length(x.Time.Values),args);
if ~all(len == len(1))
  error('Inputs have incompatible signal lengths.')
end

% Check 'Time' group compatibility
C = cellfun(@(x)x.Time,args,'Uniform',false);
if ~isequal(C{:})
  error('Inputs have incompatible ''Time'' groups.')
end

% Initialize
Data = args{1};
Clist = {};  % conflicts

% Merge remaining datasets
for k = 2:length(args)
  Data1 = args{k};
  [~,groups0] = GetSignalGroups(Data);   groups0 = setdiff(groups0,'Time','stable');
  [~,groups1] = GetSignalGroups(Data1);  groups1 = setdiff(groups1,'Time','stable');
  for j = 1:length(groups1)
    group = groups1{j};
    if ismember(group,groups0)
      if ~isequal(Data.(group),Data1.(group))
        Clist = [Clist, group];        % if a conflict, record it
        Data.(group) = Data1.(group);  % then overwrite
      end
    else
      Data = DefineSignalGroup(Data,group);
      Data.(group) = Data1.(group);    % add the new group
    end
  end
end

% Warn about conflicts encountered
if ~strcmp(option,'nowarn') && ~isempty(Clist)
  fprintf('Warning: These groups were overwritten as a result of the merge:\n');
  disp(Clist)
end
