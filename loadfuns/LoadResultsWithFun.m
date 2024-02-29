function s = LoadResultsWithFun(pathname,fun)

% LOADRESULTSWITHFUN - Modified "load" function, with definable function application.
% s = LoadResultsWithFun(pathname,fun)
%
% This function is called by functions "CollectDataFromResults", 
% "ConcatDataFromResults", "CollectSignalsFromResults", and 
% "ConcatSignalsFromResults" in place of the standard Matlab 
% "load" function. 
%
% This version allows specification of function handle 'fun', 
% which is applied to each VTool dataset found in the input 
% file. 
%
% P.G. Bonanni
% 5/27/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 3
  Selections = {};
end

% Load data from file
s = load(pathname);

% Apply specified function to datasets
fields = fieldnames(s);
for k = 1:length(fields)
  field = fields{k};
  if IsDataset(s.(field))
    s.(field) = fun(s.(field));
  end
end
