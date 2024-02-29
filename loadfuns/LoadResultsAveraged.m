function s = LoadResultsAveraged(pathname)

% LOADRESULTSAVERAGED - Modified "load" function, employing dataset averaging.
% s = LoadResultsAveraged(pathname)
%
% This function is called by functions "CollectDataFromResults", 
% "ConcatDataFromResults", "CollectSignalsFromResults", and 
% "ConcatSignalsFromResults" in place of the standard Matlab 
% "load" function. 
%
% This version modifies each VTool dataset found in the input 
% file using a time-averaging operation.  The operation results 
% in datasets with data length 1 (i.e., all signals represented 
% by their average value), with the time vectors retaining only 
% their initial value. 
%
% P.G. Bonanni
% 5/27/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Load data from file
s = load(pathname);

% Apply time averaging to datasets
fields = fieldnames(s);
for k = 1:length(fields)
  field = fields{k};
  if IsDataset(s.(field))
    t0 = s.(field).Time.Values(1);  % get initial time value
    s.(field) = ApplyFunction(s.(field),@(x)mean(x,1,'omitnan'));
    s.(field).Time.Values(1) = t0;  % restore initial time value
  end
end
