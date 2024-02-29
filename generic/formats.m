
% VTool file formats.
% 
% The following file formats are supported: 
%
% - VTool format (.vtl)
%   Native format for VTool. See function "MakeVtlFile". This format 
%   loads very fast is is space efficient. 
%
% - S-array format (S_*.mat)
%   Format supporting signals with differing sample rates.  See function 
%   "MakeSarrayFile" for an example source.  Contains single structure 
%   array 'S', with these fields: 'name' field containing signal names, 
%   'data' containing signal data vectors, 'dt' specifying sample times, 
%   'unitsT' giving time units, 'units' giving signal units, 'description' 
%   providing signal descriptions, and 'trigger', which is set to [] or to 
%   a value specifying a non-zero start time.  (In the latter case, 'trigger' 
%   can be provided as a numerical scalar, or in any absolute-time format 
%   recognized by Matlab function "datenum". Only S(1).trigger is read.)  
%   Because original data and individual sampling rates are preserved, this 
%   format enables clean-up/filtering operations prior to re-sampling onto 
%   a common time grid. 
%
% - Spreadsheet (*.xlsx, *.xls, *.csv)
%   Data in "named columns" from an Excel spreadsheet or .csv file.  
%   All entries in the "header row" must be valid variable names.  The 
%   first column must be named 'Time' and contain Excel date numbers or 
%   date-time strings.  Remaining columns must be of matching length. 
%
% See also "IsFileType". 
%
% P.G. Bonanni
% 9/8/18, updated 2/6/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.
