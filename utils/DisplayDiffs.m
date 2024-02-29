function DisplayDiffs(names,y1,y2)

% DISPLAYDIFFS - Display differences in percent.
% DisplayDiffs(names,y1,y2)
%
% Displays the differences in a set of named quantities 
% in percent.  Input 'names' is a cell array of string 
% names.  Vectors 'y1' and 'y2', matching 'names' in 
% length, represent the "before" and "after" values, 
% respectively. 
%
% P.G. Bonanni
% 2/19/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% If single name provided
if ischar(names), names=cellstr(names); end

% Check inputs
if ~iscellstr(names) || ~isvector(names)
  error('Input ''names'' is invalid.')
elseif ~isnumeric(y1) || ~isvector(y1) || length(y1)~=length(names)
  error('Input ''y1'' is invalid.')
elseif ~isnumeric(y2) || ~isvector(y2) || length(y2)~=length(names)
  error('Input ''y2'' is invalid.')
end

% Make columns
names = names(:);
y1 = y1(:);
y2 = y2(:);

% Display differences in percent
Y = 100*(y2-y1)./y1;
fprintf('\n');
C = num2cell([y1,y2,Y]);
C = [names,C];
C = [{'NAME','BEFORE','AFTER','% CHANGE'}; C];
str = evalc('disp(C)');
str = regexprep(str,'[\''\[\]]',' ');
disp(str)
