function Display(obj,pattern)

% DISPLAY - Display a dataset or a signal group.
% Display(Data)
% Display(Signals)
% Display(..., pattern)
% Display
%
% Wrapper function for "DisplayDataset" and "DisplaySignalGroup". 
% Displays contents of dataset 'Data' or signal group 'Signals'. 
% Uses editor if number of lines exceeds the 'MaxDisplayLines' 
% limit (see "GetParam"). Also works for arrays. 
%
% Optional string or regular expression 'pattern' may be provided 
% as a second argument, restricting output to only those lines 
% matching the specified pattern. Case is ignored. 
%
% If called without an input argument, the most recent object 
% is displayed in the editor. 
%
% P.G. Bonanni
% 4/4/18, updated 4/6/22

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  pattern = '';
end

% Check 'pattern' input
if ~ischar(pattern)
  error('Invalid ''pattern'' input.')
end

% Pathname to temporary file
tmpfile = fullfile(getenv('TMP'),'displayed_object.txt');

% If called with no argument
if nargin < 1
  if exist(tmpfile,'file')
    edit(tmpfile)
  else
    fprintf('No object to display!\n');
  end
  return
end

% Identify input type, and display
if IsDataset(obj)
  Str = evalc('DisplayDataset(obj)');
  DisplayStr(Str,'dataset',1,1)
elseif IsSignalGroup(obj)
  Str = evalc('DisplaySignalGroup(obj)');
  DisplayStr(Str,'signal group',1,1)
elseif IsDatasetArray(obj)
  N = numel(obj);
  for k = 1:N
    Str = evalc('DisplayDataset(obj(k))');
    DisplayStr(Str,'dataset array',k,N)
    pause
  end
elseif IsSignalGroupArray(obj)
  N = numel(obj);
  for k = 1:N
    Str = evalc('DisplaySignalGroup(obj(k))');
    DisplayStr(Str,'signal group array',k,N)
    pause
  end
else
  error('Works for datasets, signal groups, and their arrays only.')
end



% -------------------------------------------------------------------------------
% Display to screen if number of lines is less than maximum, otherwise to editor
function DisplayStr(Str,objtype,k,N)

  % Allowable number of display lines to screen
  maxlines = GetParam('MaxDisplayLines');

  % If 'pattern' specified, sift out matching lines
  if ~isempty(pattern)
    C = strread(Str,'%s','delimiter','\n');
    match = regexpi(C,pattern,'match');
    mask = ~cellfun(@isempty,match);
    Str = sprintf('%s\n',C{mask});
  end

  % Build header text
  Text1 = sprintf('<%s> --------------------------------------\n',objtype);
  Text2 = [ ...
    sprintf('==============================================================================================================\n'), ...
    sprintf('Displaying element %d of %d\n',k,N), ...
    sprintf('==============================================================================================================\n')];

  % If number of lines is less than the limit
  if sum(Str==newline) <= maxlines
    if N>1, Str=[Text2,newline,Str]; end
    fprintf('%s\n',Str);
  else
    if N==1, Str=[Text1,newline,Str]; else Str=[Text2,newline,Str]; end
    fid = fopen(tmpfile,'w');
    fprintf(fid,'%s',Str);
    fclose(fid);
    edit(tmpfile)
    if N>1, fprintf('Displaying element %d of %d\n',k,N); end
  end
end

end
