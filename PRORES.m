classdef PRORES < handle & matlab.mixin.Heterogeneous

    properties
        N          = 100;      	% Population size
        maxFE      = 50000;     % Maximum number of function evaluations
        FE         = 0;        	% Number of consumed function evaluations
    end
    properties(SetAccess = protected)
        M=3;                    	% Number of objectives
        D=72;                     	% Number of decision variables
        ResNum = 6;             
        ResMonthNum = 12;      
        M_d;                  
        year;                  
        maxRuntime = inf;      	% maximum runtime (in second)
        encoding   = 1;        	% Encoding scheme of each decision variable (1.real 2.integer 3.label 4.binary 5.permutation)
        lower      = 0;     	% Lower bound of each decision variable
        upper      = 1;        	% Upper bound of each decision variable
        optimum;              	% Optimal values of the problem
        PF;                   	% Image of Pareto front
        parameter  = {};        % Other parameters of the problem
        InitialLevel;          
        Input;                
        SanxiaLevel;           
        Min_Capcity;            
        Max_Capcity;           
        Low_Discharge;          
        High_Discharge;        
    end
    methods(Access = protected)
        function obj = PRORES(varargin)
   

            isStr = find(cellfun(@ischar,varargin(1:end-1))&~cellfun(@isempty,varargin(2:end)));
            for i = isStr(ismember(varargin(isStr),{'N','M','D','year','maxFE','maxRuntime','parameter'}))
                obj.(varargin{i}) = varargin{i+1};
            end
            obj.Setting();
        end
    end
    methods
        function Setting(obj)
        %Setting - Default settings of the problem.    
        %   This function is expected to be implemented in each subclass of
        %   PROBLEM, which is usually called by the constructor.
        end

        function Population = Initialization(obj,N)

        
            if nargin < 2
            	N = obj.N;
            end
            PopDec = zeros(N,obj.D);
            Type   = arrayfun(@(i)find(obj.encoding==i),1:5,'UniformOutput',false);
            if ~isempty(Type{1})        % Real variables
                PopDec(:,Type{1}) = unifrnd(repmat(obj.lower(Type{1}),N,1),repmat(obj.upper(Type{1}),N,1));
            end
            if ~isempty(Type{2})        % Integer variables
                PopDec(:,Type{2}) = round(unifrnd(repmat(obj.lower(Type{2}),N,1),repmat(obj.upper(Type{2}),N,1)));
            end
            if ~isempty(Type{3})        % Label variables
                PopDec(:,Type{3}) = round(unifrnd(repmat(obj.lower(Type{3}),N,1),repmat(obj.upper(Type{3}),N,1)));
            end
            if ~isempty(Type{4})        % Binary variables
                PopDec(:,Type{4}) = logical(randi([0,1],N,length(Type{4})));
            end
            if ~isempty(Type{5})        % Permutation variables
                [~,PopDec(:,Type{5})] = sort(rand(N,length(Type{5})),2);
            end
            Population = obj.Evaluation(PopDec);
        end

        function Population = Initialization_for_NSGA2(obj,N)
    
            if nargin < 2
            	N = obj.N;
            end
            PopDec = zeros(N,obj.D);
            Type   = arrayfun(@(i)find(obj.encoding==i),1:5,'UniformOutput',false);
            if ~isempty(Type{1})        % Real variables
                p = zeros(N,obj.D);
                prime_number_min = obj.D*2 +3;
                while 1
                    if isprime(prime_number_min)==1
                        break;
                    else
                        prime_number_min = prime_number_min + 1;
                    end
                end
            
                for i = 1:N
                    for j = 1:obj.D
                        if(mod((j-1),obj.D/4)==0)
                            sequence = (j-1)/(obj.D/4)+1;
                            p(i,j)=obj.InitialLevel(1,sequence);
                        else
                            r = mod(2*cos(2*pi*j/prime_number_min)*i,1);
                            p(i,j) = obj.lower(1,j)+r*(obj.upper(1,j)-obj.lower(1,j));
                        end
                    end
                end
            PopDec = p;
            end
            Population = obj.Evaluation(PopDec);
        end
        
        function Population = Evaluation(obj,varargin)

            PopDec = obj.CalDec(varargin{1});
            PopS_c = obj.CalCapcity(PopDec); 
            PopOutput = obj.CalOutput(PopS_c);

            [PopObj,PowerEnergy] = obj.CalObj(PopDec,PopOutput);
            PopObj(:, 1) = -PopObj(:, 1);
            PopObj(:, 2) = -PopObj(:, 2);
            PopObj(:, 3) = -PopObj(:, 3);
            
            PopCon = obj.CalCon(PopDec,PopOutput,PowerEnergy);
            punish = repmat(PopCon,1,obj.M);
            PopObj = PopObj+punish*10e30;
            Population = SOLUTION(PopDec,PopObj,PopCon,PopOutput,varargin{2:end});
            obj.FE     = obj.FE + length(Population);
        end
        function PopS_c = CalCapcity(obj,PopDec)
            PopS_c = zeros(size(PopDec,1),obj.D);
        end
        function PopOutput = CalOutput(obj,PopDec)
            PopOutput = zeros(size(PopDec,1),obj.D);
        end
        function PopDec = CalDec(obj,PopDec)
   

            Type  = arrayfun(@(i)find(obj.encoding==i),1:5,'UniformOutput',false);
            index = [Type{1:3}];
            if ~isempty(index)
                PopDec(:,index) = max(min(PopDec(:,index),repmat(obj.upper(index),size(PopDec,1),1)),repmat(obj.lower(index),size(PopDec,1),1));
            end
            index = [Type{2:5}];
            if ~isempty(index)
                PopDec(:,index) = round(PopDec(:,index));
            end
        end
        function PopObj = CalObj(obj,PopDec)
  

            PopObj = zeros(size(PopDec,1),1);
        end
        function PopCon = CalCon(obj,PopDec)
       
        
            PopCon = zeros(size(PopDec,1),1);
        end
         function PopOutput = Caloutput(obj,PopDec)
       
        
            PopOutput = zeros(size(PopDec,1),1);
        end
        function ObjGrad = CalObjGrad(obj,Dec)
    

            Dec(Dec==0) = 1e-12;
            X           = repmat(Dec,length(Dec),1).*(1+eye(length(Dec))*1e-6);
            ObjGrad     = (obj.CalObj(X)-repmat(obj.CalObj(Dec),size(X,1),1))'./Dec./1e-6;
        end
        function ConGrad = CalConGrad(obj,Dec)
     
        
            Dec(Dec==0) = 1e-12;
            X           = repmat(Dec,length(Dec),1).*(1+eye(length(Dec))*1e-6);
            ConGrad     = (obj.CalCon(X)-repmat(obj.CalCon(Dec),size(X,1),1))'./Dec./1e-6;
        end
        function R = GetOptimum(obj,N)
    
        
            if obj.M > 1
                R = ones(1,obj.M);
            else
                R = 0;
            end
        end
        function R = GetPF(obj)
    
            R = [];
        end
        function score = CalMetric(obj,metName,Population)
      
        
            score = feval(metName,Population,obj.optimum);
        end
        function DrawDec(obj,Population)
     
        
            if all(obj.encoding==4)
                Draw(logical(Population.decs));
            else
                Draw(Population.decs,{'\it x\rm_1','\it x\rm_2','\it x\rm_3'});
            end
        end
        function DrawObj(obj,Population)
       

            ax = Draw(Population.objs,{'\it f\rm_1','\it f\rm_2','\it f\rm_3'});
            if ~isempty(obj.PF)
                if ~iscell(obj.PF)
                    if obj.M == 2
                        plot(ax,obj.PF(:,1),obj.PF(:,2),'-k','LineWidth',1);
                    elseif obj.M == 3
                        plot3(ax,obj.PF(:,1),obj.PF(:,2),obj.PF(:,3),'-k','LineWidth',1);
                    end
                else
                    if obj.M == 2
                        surf(ax,obj.PF{1},obj.PF{2},obj.PF{3},'EdgeColor','none','FaceColor',[.85 .85 .85]);
                    elseif obj.M == 3
                        surf(ax,obj.PF{1},obj.PF{2},obj.PF{3},'EdgeColor',[.8 .8 .8],'FaceColor','none');
                    end
                    set(ax,'Children',ax.Children(flip(1:end)));
                end
            elseif size(obj.optimum,1) > 1 && obj.M < 4
                if obj.M == 2
                    plot(ax,obj.optimum(:,1),obj.optimum(:,2),'.k');
                elseif obj.M == 3
                    plot3(ax,obj.optimum(:,1),obj.optimum(:,2),obj.optimum(:,3),'.k');
                end
            end
        end
    end
	methods(Access = protected, Sealed)
        function varargout = ParameterSet(obj,varargin)   
            varargout = varargin;
            specified = ~cellfun(@isempty,obj.parameter);
            varargout(specified) = obj.parameter(specified);
        end
    end
end