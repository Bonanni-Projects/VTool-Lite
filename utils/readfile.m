function lines = readfile(pathname)

% READFILE - Read all lines from a text file.
% lines = readfile(pathname)
%
% Read lines from the text file specified by 'pathname' 
% and return the result as cell array 'lines'.
%
% P.G. Bonanni
% 7/13/11

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Read the specified file as a cell array of strings
lines = textread(pathname,'%s','delimiter','\n','whitespace','');
