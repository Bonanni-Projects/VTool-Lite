function HELP(folder)

% HELP - Open HELP.html file for a folder.
% HELP(folder)
%
% Opens the HELP.html file associated with the named 'folder'.  
% The named folder must be on the Matlab path. 
%
% P.G. Bonanni
% 7/23/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% HELP file name
helpfile = 'HELP.html';

% Read matlab path into a cell array
P = strread(matlabpath,'%s','delimiter',pathsep);

% Get folder names
[~,folders] = cellfun(@fileparts,P,'Uniform',false);

% Find 'folder' on Matlab path (first instance)
i = find(strcmpi(folder,folders),1,'first');

% Determine pathname to HELP file
if ~isempty(i)      % if folder is on Matlab path
  pathname = fullfile(P{i},helpfile);
else                % if file specified
  error('Specified ''folder'' is not on the Matlab path.');
end

% Open file if found
if exist(pathname,'file')
  web(pathname,'-new','-notoolbar')
else
  % Report the error
  fprintf('File %s not found.\n',pathname);
end
