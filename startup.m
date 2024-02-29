
% STARTUP - VTool startup script.
%
% To use this package from any location, drag this file into the Matlab 
% command window, or type "run <pathname>\startup", where <pathname> is 
% the pathname to the folder containing this startup file.  For example, 
%
%  run C:\...\GITHUB\VTool-Lite\startup
%
% P.G. Bonanni
% 3/1/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Bypass if in deployed application
if isdeployed, return, end

% Source Directory
SRC = fileparts(which('startup'));

% Add utility folders
addpath(fullfile(SRC,'utils','exportToPPTX'))
addpath(fullfile(SRC,'utils','rainflow'))
addpath(fullfile(SRC,'utils','getGitInfo'))
addpath(fullfile(SRC,'utils'))
addpath(fullfile(SRC,'loadfuns'))
addpath(fullfile(SRC,'templates'))
addpath(fullfile(SRC,'generic','utils'))
addpath(fullfile(SRC,'generic'))

% Add VTool folder
addpath(SRC)

% Print to screen
fprintf('VTool-Lite\n')
fprintf('Copyright (c) 2024  Pierino G. Bonanni')
fprintf('\n');
fprintf('Type "<a href="matlab:help VTool">help VTool</a>", see HELP.html or type "<a href="matlab:HELP vtool">HELP vtool</a>"\n');


clear SRC *_Folder
