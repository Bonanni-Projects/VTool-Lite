function s = LoadResults(pathname)

% LOADRESULTS - Customized "load" function for results.
% s = LoadResults(pathname)
%
% (SAMPLE)
%
% This function is called by functions "CollectDataFromResults", 
% "ConcatDataFromResults", "CollectSignalsFromResults", and 
% "ConcatSignalsFromResults" in place of the standard Matlab 
% "load" function.  Local copies of this function are modified 
% as needed to enable addtional default processing on file 
% contents. 
%
% P.G. Bonanni
% 1/31/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Load data from file
s = load(pathname);

% Additional processing
% ...
