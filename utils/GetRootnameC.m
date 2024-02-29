function rootname = GetRootnameC(pathnames)

% GETROOTNAMEC - Get common rootname from pathnames.
% rootname = GetRootnameC(pathnames)
%
% Given a cell array of 'pathnames', return that portion 
% of the individual rootnames, starting from the leftmost 
% character, that is shared by all pathnames in the list. 
%
% Rootnames are extracted using function "GetRootname", and 
% exclude some prefixes, such as "results_" and "S_".  The 
% returned rootname is cleared of any leading or trailing 
% space characters.  In addition, if an open and unmatched 
% '(' character is detected in the result, a closing ')' 
% character is appended. 
%
% P.G. Bonanni
% 1/31/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% If character array provided
if ischar(pathnames)
  pathnames = cellstr(pathnames);
end

% Check input
if ~iscellstr(pathnames)
  error('Invalid ''pathnames'' input.')
end

% In case folders provided, remove any trailing '\' chars
pathnames = regexprep(pathnames,'\\$','');

% Extract the rootnames
rootnames = cellfun(@GetRootname,pathnames,'Uniform',false);

% Find length of common portion
n = min(cellfun(@length,rootnames));
len = n;  % initialize
for j = n:-1:1
  C = cellfun(@(x)x(1:j),rootnames,'Uniform',false);
  if isscalar(C) || isequal(C{:}), break, end
  len = len-1;
end

% Assign the result
rootname = rootnames{1}(1:len);

% Remove leading and trailing space
rootname = regexprep(rootname,'^[ ]+','');
rootname = regexprep(rootname,'[ ]+$','');

% If an open '(' character is detected
if contains(rootname,'(') && ~contains(rootname,')')
  rootname = [rootname,')'];
end
