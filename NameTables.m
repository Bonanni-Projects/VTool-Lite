function NameTables

% NAMETABLES - Open the active NameTables.xlsx file.
% NameTables
%
% Opens the "NameTables.xlsx" file currently active on the 
% Matlab path. 
%
% P.G. Bonanni
% 10/10/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Get pathname to file
pathname = which('NameTables.xlsx');

% Open Excel on file
cmd = sprintf('start excel "%s"',pathname);
[status,result] = system(cmd);
