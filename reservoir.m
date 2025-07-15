classdef reservoir < PRORES
    methods
        function Setting(obj)
            % Set reservoir water level upper and lower limits
            obj.lower = [963.11, 952, 952, 952, 945, 945, 945, 945, 945, 945, 952, 952, ...
                         820.38, 790, 790, 790, 765, 765, 765, 765, 765, 765, 790, 790, ...
                         589.82, 560, 560, 560, 540, 540, 540, 540, 540, 540, 560, 560, ...
                         375.448, 374.5, 374.5, 374.5, 370, 370, 370, 370, 370, 370, 374.5, 374.5, ...
                         170, 150, 150, 150, 145, 145, 145, 145, 145, 145, 150, 150, ...
                         63.5, 63, 63, 63, 62, 62, 62, 62, 62, 62, 63, 63];
            
            obj.upper = [963.11, 975, 975, 975, 975, 975, 952, 952, 975, 975, 975, 975, ...
                         820.38, 825, 825, 825, 825, 825, 790.5, 790.5, 825, 825, 825, 825, ...
                         589.82, 600, 600, 600, 600, 600, 560, 560, 600, 600, 600, 600, ...
                         375.448, 380, 380, 380, 380, 380, 374.5, 374.5, 380, 380, 380, 380, ...
                         170, 175, 175, 175, 175, 175, 150, 150, 175, 175, 175, 175, ...
                         63.5, 64, 64, 64, 64, 64, 63, 63, 64, 64, 64, 64];
            
            obj.encoding = ones(1, obj.D);
            
            % Initial water level
            obj.InitialLevel = [963.11, 820.38, 589.82, 375.448, 170, 63.5];
            
            % Three Gorges water level
            obj.SanxiaLevel = [40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40];
            
            % Minimum power output
            obj.Min_Capcity = [0, 0, 0, 0, 0, 0];
            
            % Maximum power output
            obj.Max_Capcity = [10200, 16000, 12600, 6000, 22500, 2735];
            
            % Minimum discharge flow
            obj.Low_Discharge = [900, 1260, 1200, 1200, 5500, 5000];
            
            % Maximum discharge flow
            obj.High_Discharge = [35800, 38800, 40888, 41200, 98800, 86000];
            
            % Read Wudongde runoff data
            wdddata = readtable('Runoff-Wudongde-Monthly-Standardized.xlsx');
            year_col = wdddata.Var1;
            row = find(year_col == 2016);
            if ~isempty(row)
                obj.Input = table2array(wdddata(row, 2:13));
            else
                error('Data not found');
            end
            
            % Days per month
            obj.M_d = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        end
        
        %% Calculate objective function values
        function [PopObj, PowerEnergy] = CalObj(obj, PopDec, PopOutput)
            % Read Xiangjiaba-Three Gorges interval flow data
            xjb_sxdata = readtable('Xiangjiaba-ThreeGorges-Interval-Monthly-Flow-Standardized.xlsx');
            year_col = xjb_sxdata.Var1;
            row = find(year_col == 2016);
            if ~isempty(row)
                Flow_XJBSGX_12months = table2array(xjb_sxdata(row, 2:13));
            else
                error('Interval flow data not found');
            end
            
            % Upstream reservoir capacity
            Vup = [58.63, 58.63, 58.63, 58.63, 58.63, 58.63, 34.535, 34.535, 58.63, 58.63, 58.63, 58.63, ...  % 1st reservoir (12 months)
                   190.06, 190.06, 190.06, 190.06, 190.06, 190.06, 123.403, 123.403, 190.06, 190.06, 190.06, 190.06, ...  % 2nd reservoir
                   115.7, 115.7, 115.7, 115.7, 115.7, 115.7, 70.3752, 70.3752, 115.7, 115.7, 115.7, 115.7, ...  % 3rd reservoir
                   49.77, 49.77, 49.77, 49.77, 49.77, 49.77, 44.8035, 44.8035, 49.77, 49.77, 49.77, 49.77, ...
                   393, 393, 393, 393, 393, 393, 177.6525, 177.6525, 393, 393, 393, 393, ...
                   15.8, 15.8, 15.8, 15.8, 15.8, 15.8, 9.48, 9.48, 15.8, 15.8, 15.8, 15.8];
            
            % Downstream reservoir capacity
            Vdown = [34.535, 34.535, 34.535, 34.535, 28, 28, 28, 28, 28, 28, 34.535, 34.535, ...
                     123.403, 123.403, 123.403, 123.403, 85, 85, 85, 85, 85, 85, 123.403, 123.403, ...
                     70.3752, 70.3752, 70.3752, 70.3752, 51, 51, 51, 51, 51, 51, 70.3752, 70.3752, ...
                     44.8035, 44.8035, 44.8035, 44.8035, 40, 40, 40, 40, 40, 40, 44.8035, 44.8035, ...
                     177.6525, 177.6525, 177.6525, 177.6525, 171.5, 171.5, 171.5, 171.5, 171.5, 171.5, 177.6525, 177.6525, ...
                     9.48, 9.48, 9.48, 9.48, 7, 7, 7, 7, 7, 7, 9.48, 9.48];
            
            % Calculate water level difference
            Two_dif = zeros(size(PopDec));
            for i = 1:size(PopDec, 1)
                for j = 1:(obj.ResNum-1)*obj.ResMonthNum
                    if mod(j, obj.ResMonthNum) == 0
                        Two_dif(i, j) = (PopDec(i, j) + PopDec(i, j-obj.ResMonthNum+1)) / 2 - PopDec(i, j+obj.ResMonthNum);
                    else
                        Two_dif(i, j) = (PopDec(i, j) + PopDec(i, j+1)) / 2 - PopDec(i, j+obj.ResMonthNum);
                    end
                end
                
                for j = 1:obj.ResMonthNum
                    extra = obj.ResMonthNum * 5 + j;
                    if mod(j, obj.ResMonthNum) == 0
                        Two_dif(i, extra) = (PopDec(i, extra) + PopDec(i, extra-obj.ResMonthNum+1)) / 2 - obj.SanxiaLevel(1, j);
                    else
                        Two_dif(i, extra) = (PopDec(i, extra) + PopDec(i, extra+1)) / 2 - obj.SanxiaLevel(1, j);
                    end
                end
            end
            
            % Calculate power generation
            C = 5.5;
            PopObj = zeros(obj.N, obj.M);
            for i = 1:size(PopDec, 1)
                for j = 1:obj.D
                    PowerEnergy(i, j) = C * Two_dif(i, j) * PopOutput(i, j) / 1000;
                    if PowerEnergy(i, j) >= obj.Max_Capcity(1, floor((j-1)/12)+1)
                        PowerEnergy(i, j) = obj.Max_Capcity(1, floor((j-1)/12)+1);
                    end
                    New_M_d = repmat(obj.M_d, 1, obj.ResNum);
                    PopObj(i, 1) = PopObj(i, 1) + PowerEnergy(i, j) * 1000 * New_M_d(1, j) * 24 / (10^8);
                end
            end
            
            % Calculate second objective function
            S_c = obj.CalCapcity(PopDec);
            flood_indices = [5, 6, 9, 10, 17, 18, 21, 22, 29, 30, 33, 34, 41, 42, 45, 46, 53, 54, 57, 58, 65, 66, 69, 70];
            for i = 1:size(PopDec, 1)
                normalized_sum = 0;
                for j = flood_indices
                    current_S_c = S_c(i, j);
                    Vmin = Vdown(j);
                    Vmax = Vup(j);
                    normalized_value = (Vmax - current_S_c) / (Vmax - Vmin);
                    normalized_sum = normalized_sum + normalized_value;
                end
                
                supply_indices = [1, 2, 3, 4, 11, 12, 13, 14, 15, 16, 23, 24, 25, 26, 27, 28, 35, 36, 37, 38, 39, 40, 47, 48, 49, 50, 51, 52, 59, 60, 61, 62, 63, 64, 71, 72];
                supply_normalized_sum = 0;
                for j = supply_indices
                    supply_current_S_c = S_c(i, j);
                    Vmin2 = Vdown(j);
                    Vmax2 = Vup(j);
                    supply_normalized_value = (supply_current_S_c - Vmin2) / (Vmax2 - Vmin2);
                    supply_normalized_sum = supply_normalized_sum + supply_normalized_value;
                end
                
                PopObj(i, 2) = ((normalized_sum / 24) + (supply_normalized_sum / 36) + ...
                               ((1 - max(PopOutput(i, 7:8)) / 35800) + ...
                                (1 - max(PopOutput(i, 19:20)) / 38800) + ...
                                (1 - max(PopOutput(i, 31:32)) / 40888) + ...
                                (1 - max(PopOutput(i, 43:44)) / 41200) + ...
                                (1 - max(PopOutput(i, 55:56)) / 98800) + ...
                                (1 - max(PopOutput(i, 67:68)) / 86000)) / 6) / 3;
            end
            
            % Calculate third objective function
            for i = 1:size(PopDec, 1)
                Drop_area_i = obj.CalFluctuationZoneArea(PopDec(i, :));
                selected_cols = [5, 6, 9, 10, 17, 18, 21, 22, 29, 30, 33, 34, 41, 42, 45, 46, 53, 54, 57, 58, 65, 66, 69, 70];
                Total_drop_area_sum = sum(Drop_area_i(:, selected_cols), 2);
                
                CO2_C = Total_drop_area_sum * 1821 * 30 * 3.6644;
                
                sed1 = (((PopOutput(i, 43) + PopOutput(i, 44)) / 2 * 0.03088 * 62 * 24 * 3600) / ...
                        ((obj.Input(1, 7) + obj.Input(1, 8)) / 2 * 0.30175 * 62 * 24 * 3600));
                
                sed2 = ((((PopOutput(i, 67) + PopOutput(i, 68)) / 2 * 0.12125 * 62 * 24 * 3600)) / ...
                        (((PopOutput(i, 43) + PopOutput(i, 44)) / 2 * 0.03088 * 62 * 24 * 3600) + ...
                         (Flow_XJBSGX_12months(7) + Flow_XJBSGX_12months(8)) / 2 * 62 * 24 * 3600 * 0.59725));
                
                PopObj(i, 3) = ((1 - ((CO2_C / 10000000000000) / (298591885049880 / 10000000000000))) + ...
                               ((sed1 + sed2) / 2) + ...
                               (((1 - 900 / min(PopOutput(i, [1:4, 11:12]))) + ...
                                 (1 - 1260 / min(PopOutput(i, [13:16, 23:24]))) + ...
                                 (1 - 1200 / min(PopOutput(i, [25:28, 35:36]))) + ...
                                 (1 - 1200 / min(PopOutput(i, [37:40, 47:48]))) + ...
                                 (1 - 5500 / min(PopOutput(i, [49:52, 59:60]))) + ...
                                 (1 - 5000 / min(PopOutput(i, [61:64, 71:72])))) / 6)) / 3;
            end
        end
        
        %% Calculate fluctuation zone area
        function Drop_area = CalFluctuationZoneArea(obj, PopDec)
            [N, ~] = size(PopDec);
            Drop_area = zeros(size(PopDec));
            
            % Reservoir data
            reservoir_data = {
                {[955, 975], [56290000, 0]};   % Reservoir 1
                {[765, 825], [96620000, 0]};   % Reservoir 2
                {[540, 600], [65600000, 0]};   % Reservoir 3
                {[370, 380], [12510000, 0]};   % Reservoir 4
                {[145, 175], [150000000, 0]};  % Reservoir 5
                {[62, 64], [3072500, 0]}       % Reservoir 6
            };
            
            for reservoir_idx = 1:6
                start_col = (reservoir_idx - 1) * 12 + 1;
                end_col = reservoir_idx * 12;
                water_levels = PopDec(:, start_col:end_col);
                
                levels = reservoir_data{reservoir_idx}{1};
                area_range = reservoir_data{reservoir_idx}{2};
                
                Drop_area(:, start_col:end_col) = ...
                    interp1(levels, area_range, water_levels, 'linear', 'extrap');
            end
            
            Drop_area = max(Drop_area, 0);
            for reservoir_idx = 1:6
                max_area = reservoir_data{reservoir_idx}{2}(1);
                start_col = (reservoir_idx - 1) * 12 + 1;
                end_col = reservoir_idx * 12;
                Drop_area(:, start_col:end_col) = ...
                    min(Drop_area(:, start_col:end_col), max_area);
            end
        end
        
        %% Calculate reservoir capacity
        function S_c = CalCapcity(obj, PopDec)
            S_c = zeros(size(PopDec));
            for i = 1:size(PopDec, 1)
                % Wudongde water level-capacity conversion
                for j = 1:obj.ResMonthNum
                    if (945 <= PopDec(i, j)) && (PopDec(i, j) <= 950)
                        S_c(i, j) = 28.43 + (PopDec(i, j) - 945) * 0.8488;
                    elseif (950 <= PopDec(i, j)) && (PopDec(i, j) <= 960)
                        S_c(i, j) = 28.43 + 5 * 0.8488 + (PopDec(i, j) - 950) * 0.9305;
                    elseif (960 <= PopDec(i, j)) && (PopDec(i, j) <= 975)
                        S_c(i, j) = 28.43 + 5 * 0.8488 + 10 * 0.9305 + (PopDec(i, j) - 960) * 1.1101;
                    end
                end
                
                % Baihetan water level-capacity conversion
                for j = obj.ResMonthNum+1:2*obj.ResMonthNum
                    if (765 <= PopDec(i, j)) && (PopDec(i, j) <= 775)
                        S_c(i, j) = 85.7 + (PopDec(i, j) - 765) * 1.4655;
                    elseif (775 <= PopDec(i, j)) && (PopDec(i, j) <= 785)
                        S_c(i, j) = 85.7 + 10 * 1.4655 + (PopDec(i, j) - 775) * 1.5103;
                    elseif (785 <= PopDec(i, j)) && (PopDec(i, j) <= 795)
                        S_c(i, j) = 85.7 + 10 * 1.4655 + 10 * 1.5103 + (PopDec(i, j) - 785) * 1.589;
                    elseif (795 <= PopDec(i, j)) && (PopDec(i, j) <= 805)
                        S_c(i, j) = 85.7 + 10 * 1.4655 + 10 * 1.5103 + 10 * 1.589 + (PopDec(i, j) - 795) * 1.7016;
                    elseif (805 <= PopDec(i, j)) && (PopDec(i, j) <= 815)
                        S_c(i, j) = 85.7 + 10 * 1.4655 + 10 * 1.5103 + 10 * 1.589 + 10 * 1.7016 + (PopDec(i, j) - 805) * 1.9481;
                    elseif (815 <= PopDec(i, j)) && (PopDec(i, j) <= 825)
                        S_c(i, j) = 85.7 + 10 * 1.4655 + 10 * 1.5103 + 10 * 1.589 + 10 * 1.7016 + 10 * 1.9481 + (PopDec(i, j) - 815) * 2.2216;
                    end
                end
                
                % Xiluodu water level-capacity conversion
                for j = 2*obj.ResMonthNum+1:3*obj.ResMonthNum
                    if (540 <= PopDec(i, j)) && (PopDec(i, j) <= 551)
                        S_c(i, j) = 51.1 + (PopDec(i, j) - 540) * 0.8932;
                    elseif (551 <= PopDec(i, j)) && (PopDec(i, j) <= 564)
                        S_c(i, j) = 51.1 + 11 * 0.8932 + (PopDec(i, j) - 551) * 1.05;
                    elseif (564 <= PopDec(i, j)) && (PopDec(i, j) <= 580)
                        S_c(i, j) = 51.1 + 11 * 0.8932 + 13 * 1.05 + (PopDec(i, j) - 564) * 1.12;
                    elseif (580 <= PopDec(i, j)) && (PopDec(i, j) <= 600)
                        S_c(i, j) = 51.1 + 11 * 0.8932 + 13 * 1.05 + 16 * 1.12 + (PopDec(i, j) - 580) * 1.16;
                    end
                end
                
                % Xiangjiaba water level-capacity conversion
                for j = 3*obj.ResMonthNum+1:4*obj.ResMonthNum
                    if (370 <= PopDec(i, j)) && (PopDec(i, j) <= 380)
                        S_c(i, j) = 40.74 + (PopDec(i, j) - 370) * 0.903;
                    end
                end
                
                % Three Gorges water level-capacity conversion
                for j = 4*obj.ResMonthNum+1:5*obj.ResMonthNum
                    if (145 <= PopDec(i, j)) && (PopDec(i, j) <= 175)
                        S_c(i, j) = 0.2461 * (PopDec(i, j) - 145)^2 + 171.5;
                    end
                end
                
                % Gezhouba water level-capacity conversion
                for j = 5*obj.ResMonthNum+1:6*obj.ResMonthNum
                    if (62 <= PopDec(i, j)) && (PopDec(i, j) <= 64)
                        S_c(i, j) = 1.92 * PopDec(i, j) * PopDec(i, j) - 237.52 * PopDec(i, j) + 7352.76;
                    end
                end
            end
        end
        
        %% Calculate outflow of each reservoir
        function Output = CalOutput(obj, S_c)
            Output = zeros(obj.N, obj.D);
            
            % Read Xiangjiaba-Three Gorges interval flow data
            xjb_sxdata = readtable('Xiangjiaba-ThreeGorges-Interval-Monthly-Flow-Standardized.xlsx');
            year_col = xjb_sxdata.Var1;
            row = find(year_col == 2016);
            if ~isempty(row)
                Flow_XJBSGX_12months = table2array(xjb_sxdata(row, 2:13));
            else
                error('Interval flow data not found');
            end
            
            for i = 1:size(S_c, 1)
                % Wudongde outflow (considering Wudongde reservoir area)
                Flow_WDD_12months = [1131.870076, 947.417175, 838.4222788, 855.1907243, 1425.317874, 4141.806057, ...
                                     8002.740651, 7663.179628, 7558.376843, 5265.291911, 2565.572173, 1530.120659];
                for j = 1:obj.ResMonthNum-1
                    Output(i, j) = Flow_WDD_12months(j) + obj.Input(1, j) - ...
                                   (S_c(i, j + 1) - S_c(i, j)) * (10^8) / (obj.M_d(1, j) * 24 * 3600);
                end
                Output(i, obj.ResMonthNum) = Flow_WDD_12months(obj.ResMonthNum) + obj.Input(1, obj.ResMonthNum) - ...
                                             (S_c(i, 1) - S_c(i, 12)) * (10^8) / (obj.M_d(1, obj.ResMonthNum) * 24 * 3600);
                
                % Baihetan outflow (considering interval flow between Wudongde and Baihetan)
                Flow_WDD_BHT_12months = [71.71395454, 60.02723602, 53.12144781, 54.18387676, 90.30646127, 262.4199522, ...
                                         507.0442193, 485.5300329, 478.889852, 333.6026922, 162.5516303, 96.94664225];
                
                for j = obj.ResMonthNum+1:2*obj.ResMonthNum-1
                    Output(i, j) = Flow_WDD_BHT_12months(j - obj.ResMonthNum) + Output(i, j - obj.ResMonthNum) - ...
                                   (S_c(i, j + 1) - S_c(i, j)) * (10^8) / (obj.M_d(1, j - obj.ResMonthNum) * 24 * 3600);
                end
                Output(i, 2*obj.ResMonthNum) = Flow_WDD_BHT_12months(obj.ResMonthNum) + Output(i, obj.ResMonthNum) - ...
                                               (S_c(i, obj.ResMonthNum+1) - S_c(i, obj.ResMonthNum+12)) * (10^8) / (obj.M_d(1, obj.ResMonthNum) * 24 * 3600);
                
                % Xiluodu outflow (considering interval flow between Baihetan and Xiluodu)
                Flow_BHT_XLD_12months = [44.69780896, 37.41372157, 33.10948812, 33.77167788, 56.2861298, 163.5608713, ...
                                         316.0300641, 302.6207214, 298.4820354, 207.9275854, 101.3150336, 60.42481582];
                for j = 2*obj.ResMonthNum+1:3*obj.ResMonthNum-1
                    Output(i, j) = Flow_BHT_XLD_12months(j - 2*obj.ResMonthNum) + Output(i, j - obj.ResMonthNum) - ...
                                   (S_c(i, j + 1) - S_c(i, j)) * (10^8) / (obj.M_d(1, j - 2*obj.ResMonthNum) * 24 * 3600);
                end
                Output(i, 3*obj.ResMonthNum) = Flow_BHT_XLD_12months(obj.ResMonthNum) + Output(i, 2*obj.ResMonthNum) - ...
                                               (S_c(i, 2*obj.ResMonthNum+1) - S_c(i, 2*obj.ResMonthNum+12)) * (10^8) / (obj.M_d(1, obj.ResMonthNum) * 24 * 3600);
                
                % Xiangjiaba outflow (considering interval flow between Xiluodu and Xiangjiaba)
                Flow_XLD_XJB_12months = [20.29736993, 16.98965039, 15.03508884, 15.33579062, 25.55965103, 74.27333886, ...
                                         143.509923, 137.420712, 135.5413259, 94.42035791, 46.00737185, 27.43903713];
                for j = 3*obj.ResMonthNum+1:4*obj.ResMonthNum-1
                    Output(i, j) = Flow_XLD_XJB_12months(j - 3*obj.ResMonthNum) + Output(i, j - obj.ResMonthNum) - ...
                                   (S_c(i, j + 1) - S_c(i, j)) * (10^8) / (obj.M_d(1, j - 3*obj.ResMonthNum) * 24 * 3600);
                end
                Output(i, 4*obj.ResMonthNum) = Flow_XLD_XJB_12months(obj.ResMonthNum) + Output(i, 3*obj.ResMonthNum) - ...
                                               (S_c(i, 3*obj.ResMonthNum+1) - S_c(i, 3*obj.ResMonthNum+12)) * (10^8) / (obj.M_d(1, obj.ResMonthNum) * 24 * 3600);
                
                % Three Gorges outflow
                for j = 4*obj.ResMonthNum+1:5*obj.ResMonthNum-1
                    Output(i, j) = Flow_XJBSGX_12months(j - 4*obj.ResMonthNum) + Output(i, j - obj.ResMonthNum) - ...
                                   (S_c(i, j + 1) - S_c(i, j)) * (10^8) / (obj.M_d(1, j - 4*obj.ResMonthNum) * 24 * 3600);
                end
                Output(i, 5*obj.ResMonthNum) = Flow_XJBSGX_12months(obj.ResMonthNum) + Output(i, 4*obj.ResMonthNum) - ...
                                               (S_c(i, 4*obj.ResMonthNum+1) - S_c(i, 4*obj.ResMonthNum+12)) * (10^8) / (obj.M_d(1, obj.ResMonthNum) * 24 * 3600);
                
                % Gezhouba outflow
                for j = 5*obj.ResMonthNum+1:6*obj.ResMonthNum-1
                    Output(i, j) = Output(i, j - obj.ResMonthNum) - ...
                                   (S_c(i, j + 1) - S_c(i, j)) * (10^8) / (obj.M_d(1, j - 5*obj.ResMonthNum) * 24 * 3600);
                end
                Output(i, 6*obj.ResMonthNum) = Output(i, 5*obj.ResMonthNum) - ...
                                               (S_c(i, 5*obj.ResMonthNum+1) - S_c(i, 5*obj.ResMonthNum+12)) * (10^8) / (obj.M_d(1, obj.ResMonthNum) * 24 * 3600);
            end
        end
        
        %% Calculate constraint violations
        function PopCon = CalCon(obj, PopDec, PopOutput, PowerEnergy)
            PopCon = zeros(obj.N, 1);
            
            % Reservoir water level constraints
            wl = zeros(obj.N, 1);
            for i = 1:size(PopDec, 1)
                for j = 1:obj.D
                    wl(i, 1) = wl(i, 1) + max(0, obj.lower(1, j) - PopDec(i, j)) + max(0, PopDec(i, j) - obj.upper(1, j));
                end
            end
            
            % Reservoir discharge flow constraints
            rdf = zeros(obj.N, 1);
            for i = 1:size(PopDec, 1)
                for j = 1:obj.ResNum
                    for k = 1:obj.ResMonthNum
                        rdf(i, 1) = rdf(i, 1) + max(0, obj.Low_Discharge(1, j) - PopOutput(i, k+(j-1)*obj.ResMonthNum)) + ...
                                    max(0, PopOutput(i, k+(j-1)*obj.ResMonthNum) - obj.High_Discharge(1, j));
                    end
                end
            end
            
            % Power station output constraints
            pso = zeros(obj.N, 1);
            for i = 1:size(PopDec, 1)
                for j = 1:obj.ResNum
                    for k = 1:obj.ResMonthNum
                        pso(i, 1) = pso(i, 1) + max(0, obj.Min_Capcity(1, j) - PowerEnergy(i, k+(j-1)*obj.ResMonthNum)) + ...
                                    max(0, PowerEnergy(i, k+(j-1)*obj.ResMonthNum) - obj.Max_Capcity(1, j));
                    end
                end
            end
            
            % Total constraint violations
            PopCon = wl + rdf + pso;
        end
    end
end