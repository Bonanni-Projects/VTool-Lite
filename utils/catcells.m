function catcells(varargin)

% CATCELLS - Concatenate cell-array variables.
% catcells('var1','var2',...)
% catcells
%
% Replaces certain cell-array variables in the calling workspace 
% with the results obtained by concatenating their cell contents 
% vertically.  For example, cell array 'var1' is replaced by 
% the results of evaluating "cat(1,var1{:})".  All inputs 
% must be named cell-array variables in the calling workspace. 
% If called without input argments, all variables in the calling 
% environment are assumed. 
%
% Any cell arrays that do not qualify for concatenation due to 
% incompatibility of their cell contents are left unchanged.  
% Also, cell arrays of strings and cell arrays containing column 
% vector or other contents with dimension 1 greater than zero are 
% left unchanged. 
%
% This is a utility function used for post-processing results  
% of collection functions (e.g., "CollectDataFromResults", 
% "CollectSignalsFromResults", etc.), specifically the non-
% VTool variables collected as cell arrays. 
%
% P.G. Bonanni
% 3/28/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin == 0
  varargin = evalin('caller','who');
end

% Loop over inputs
for k = 1:length(varargin)
  var = varargin{k};

  % If input is a scalar string and a valid variable name ...
  if ischar(var) && size(var,1)==1 && strcmp(var,regexp(var,'[a-zA-Z][\w]*','match'))
    name = var;  % interpret as a variable name

    % If the variable exists in the calling environment ...
    if evalin('caller',sprintf('exist(''%s'',''var'');',name))
      var = evalin('caller',name);  % retrieve it

      % If a cell array
      if iscell(var)

        % Skip if cell array of strings or non-row cell contents
        if iscellstr(var) || any(cellfun(@(x)size(x,1),var) > 1)
          fprintf('Cell array ''%s'' left unchanged.\n',name);
          continue
        end

        % All others
        try
          var = cat(1,var{:});
          assignin('caller',name,var)
        catch
          fprintf('Cell array ''%s'' could not be concatenated.\n',name);
        end
      end
    end
  end
end
