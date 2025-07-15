function Level = LevelSort(Population,n)

    Zmax     = max(Population.objs,[],1);
    Zmin     = min(Population.objs,[],1);
    interval = (Zmax-Zmin)./n;
    Level    = zeros(length(Population),1);
    objs     = Population.objs;
    for i = 1 : length(Population)
        t = 0;
        leveled = 0;
        obj = objs(i,:);
        while leveled == 0
            t = t+1;
            leveled = 1;
            for j = 1 : size(objs,2)
                if obj(1,j)>Zmin(j)+(t+1)*interval(1,j)
                    leveled = 0;
                    break;
                end
            end
        end
        Level(i) = t;
    end 
end