function [out1,out2] = FindName(name,obj)

% FINDNAME - Find a signal name in a signal group or dataset.
% index = FindName(name,Signals)
% [Index,groups] = FindName(name,Data)
% FindName(name,Signals)
% FindName(name,Data)
%
% Locates a signal name, including duplicates, within a signal 
% group or dataset.  Input 'name' specifies the desired signal.  
% The name entry from any available name layer may be used.  
% If input 'Signals' is a signal group, output 'index' returns 
% the list of index values for the signal within the signal 
% group, or [] if the signal name is not found.  The empty 
% string name ('') is considered a match only if it appears on 
% all name layers.
%
% If input 'Data' is a dataset, the signal name is searched 
% over all available signal groups.  Output 'groups' is a cell 
% array of group names found to contain the signal name, and 
% output 'Index' is a corresponding cell array of index vectors. 
%
% If called without output arguments a chart showing results 
% of the search is printed, and no outputs are returned. 
%
% P.G. Bonanni
% 4/8/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'obj' input
[flag1,valid1] = IsSignalGroup(obj);
[flag2,valid2] = IsDataset(obj);
if ~flag1 && ~flag2
  error('Works for scalar signal groups or datasets only.')
elseif flag1 && ~valid1
  error('Input ''Signals'' is not a valid signal group.  See "IsSignalGroup".')
elseif flag2 && ~valid2
  error('Input ''Data'' is not a valid dataset.  See "IsDataset".')
end

% Check 'name' input
if ~ischar(name)
  error('Invalid ''name'' input.')
end

% Initialize
msg1 = '  (primary)';
msg2 = '  <-- First location is primary.';

% If input is a dataset ...
if flag2
  Data = obj;

  % Get signal groups and group names
  [s,fields] = GetSignalGroups(Data);

  % Locate instances of the name within each group
  Index = cellfun(@(x)FindName(name,x),struct2cell(s),'Uniform',false);

  % Find empties, and build output cell arrays
  mask = ~cellfun(@isempty,Index);
  Index  = Index(mask);
  groups = fields(mask);

  % Reset messages if no multiple instances
  if length(cat(1,Index{:})) < 2
    msg1 = '';
    msg2 = '';
  end

  if nargout
    out1 = Index;
    out2 = groups;

  else
    % Print information to screen
    fprintf('''%s''\n',name);
    if ~isempty(Index)
      for k = 1:length(Index)
        index = Index{k};
        group = groups{k};
        nsignals = size(Data.(group).Values,2);
        if length(index) == 1
          fprintf('  ''%s'': location %d out of %d.%s\n',group,index,nsignals,msg1);
        else  % multiple locations
          fprintf('  ''%s'': locations %s out of %d.%s\n',group,mat2str(index'),nsignals,msg2);
        end
        msg1 = '';
        msg2 = '';
      end
    else
      fprintf('  Not found.\n');
    end
  end

else  % if input is a signal group ...
  Signals = obj;

  % Get the names matrix for the signal group
  NAMES = GetNamesMatrix(Signals);

  % Define 'name1' and 'NAMES1' to handle empty names
  name1  = name;   % initialize
  NAMES1 = NAMES;  % initialize
  if isempty(name), name1='(empty)'; end
  mask = all(cellfun(@isempty,NAMES1),2); [NAMES1{mask,:}]=deal('(empty)');

  % Find all instances of 'name1' in the signal list, considering all name layers
  index1 = find(strcmp(name1,NAMES1(:)));  [index,~]=ind2sub(size(NAMES1),index1);
  index = unique(index);  % sort and remove duplicates (duplicates here correspond to same row, different layers)
  if isempty(index), index=[]; end  % make [] if empty

  % Reset messages if no multiple instances
  if length(index) < 2
    msg1 = '';
    msg2 = '';
  end

  if nargout
    out1 = index;
    out2 = {};

  else
    % Print information to screen
    nsignals = size(Signals.Values,2);
    fprintf('''%s''\n',name);
    if isempty(index)
      fprintf('  Not found.\n');
    elseif length(index) == 1
      fprintf('  Location %d out of %d.%s\n',index,nsignals,msg1);
    else  % multiple locations
      fprintf('  Locations %s out of %d.%s\n',mat2str(index'),nsignals,msg2);
    end
  end
end
