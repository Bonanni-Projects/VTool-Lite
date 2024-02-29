function rootname = GetRootname(pathname)

% GETROOTNAME - Extract rootname from a pathname.
% rootname = GetRootname(pathname)
% rootnames = GetRootname(pathnames)
%
% Returns the 'rootname' from an input 'pathname'. Except for 
% special cases, the rootname consists of the filename with the 
% file extension removed.  If the filename is an S-array filename 
% and includes the 'S_', prefix, this prefix is also excluded.  
% Similarly, if the filename is a "results" file with prefix 
% 'results_', that prefix is excluded as well. 
%
% Also accepts cell array 'pathnames', in which case an equal-sized 
% cell array of 'rootnames' is returned. 
%
% P.G. Bonanni
% 11/16/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% If cell array input
if iscellstr(pathname)
  rootname = cellfun(@GetRootname,pathname,'Uniform',false);
  return
end

% Check input
if ~ischar(pathname)
  error('Invalid ''pathname'' input. Not a character array.')
end

% Extract rootname from pathname
[~,rootname] = fileparts(pathname);

% Special cases
if IsFileType(pathname,'S-array')
  rootname = regexprep(rootname,'^S_','');
elseif IsFileType(pathname,'.mat') && ~isempty(regexp(rootname,'^results_.+'))
  rootname = regexprep(rootname,'^results_','');
end
