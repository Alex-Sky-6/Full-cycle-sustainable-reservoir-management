function HVLoss = CalHVLoss(PopObj,FrontNo)
    %% Calculate the WHV loss of each solution front by front
    HVLoss  = zeros(1,size(PopObj,1));
    RefPoint = max(PopObj,[],1) + 0.1;
    for f = setdiff(unique(FrontNo),inf)
        current  = find(FrontNo==f);
        totalWHV = CalHV(PopObj(current,:),RefPoint);
        for i = 1 : length(current)
            drawnow('limitrate');
            currenti = current([1:i-1,i+1:end]);
            HVLoss(current(i))= totalWHV - CalHV(PopObj(currenti,:),RefPoint);
        end
    end
end