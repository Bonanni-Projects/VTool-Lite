function folderpath = FindGitHome(funname)

% FINDGITHOME - Find the pathname to the local Git folder containing a function.
% folderpath = FindGitHome(funname)
%
% Returns the full pathname to the local Git folder that contains 
% a specified function.  The specified function name 'funname' 
% must be on the Matlab path. 
%
% P.G. Bonanni
% 4/18/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Initialize
folderpath = [];

% Check input for validity
if ~ischar(funname) || isempty(regexp(funname,'^[A-Za-z]\w*$','once'))
  error('Input ''funname'' is invalid.  Must be a function name.')
end

% Get pathname to the specified function
pathname = which(funname);
if isempty(pathname)
  error('Function ''%s'' not found.',funname);
end

% Search upwards along the path for a .git folder, 
% ... and return the full pathname of its parent
while(~strcmp(pathname,fileparts(pathname)))
  pathname = fileparts(pathname);
  if isdir(fullfile(pathname,'.git'))
    folderpath = pathname;
    break
  end
end
