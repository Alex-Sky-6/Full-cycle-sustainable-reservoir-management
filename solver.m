function varargout = solver(varargin)

    cd(fileparts(mfilename('fullpath')));
    addpath(genpath(cd));
    if isempty(varargin)
        if verLessThan('matlab','9.9')
            errordlg('Fail to create the GUI of PlatEMO since the version for MATLAB is lower than R2020b. You can use PlatEMO without GUI by calling platemo() with parameters.','Error','modal');
        else
            try
                GUI();
            catch err
                errordlg('Fail to create the GUI, please make sure all the folders of PlatEMO have been added to search path.','Error','modal');
                rethrow(err);
            end
        end
    else
        if verLessThan('matlab','9.4')
            error('Fail to use PlatEMO since the version for MATLAB is lower than R2018a. Please update your MATLAB software.');
        else
            [PRO,input] = getSetting(varargin);
            Problem     = PRO(input{:});
            [ALG,input] = getSetting(varargin,Problem);
            if nargout > 0
                Algorithm = ALG(input{:},'save',0);
            else
                Algorithm = ALG(input{:});
            end
            Algorithm.Solve(Problem);
            if nargout > 0
                P = Algorithm.result{end};
                varargout = {P.decs,P.objs,P.cons};           
                second_cell = varargout{2};
                second_cell(:, 1:3) = -second_cell(:, 1:3);
                varargout{2} = second_cell;
            end
        end
    end
end

function [name,Setting] = getSetting(Setting,Pro)
    isStr = find(cellfun(@ischar,Setting(1:end-1))&~cellfun(@isempty,Setting(2:end)));
    if nargin > 1
        index = isStr(find(strcmp(Setting(isStr),'algorithm'),1)) + 1;
        if isempty(index)
            names = {@BSPGA,@GA,@SACOSO,@GA;@PMMOEA,@NSGAIII,@KRVEA,@NSGAIII;@RVEA,@RVEA,@CSEA,@RVEA};
            name  = names{find([Pro.M<2,Pro.M<4,1],1),find([all(Pro.encoding==4),any(Pro.encoding>2),Pro.maxFE<=1000&Pro.D<=10,1],1)};
        elseif iscell(Setting{index})
            name    = Setting{index}{1};
            Setting = [Setting,{'parameter'},{Setting{index}(2:end)}];
        else
            name = Setting{index};
        end
    else
        index = isStr(find(strcmp(Setting(isStr),'problem'),1)) + 1;
        if isempty(index)
            name = @UserProblemRes;
        elseif iscell(Setting{index})
            name    = Setting{index}{1};
            Setting = [Setting,{'parameter'},{Setting{index}(2:end)}];
        else
            name = Setting{index};
        end
    end
end