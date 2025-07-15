function Density = DensityEstimate(Population,W)
    Zmax       = max(Population.objs,[],1);
    Zmin       = min(Population.objs,[],1);
    SPopObj    = (Population.objs-repmat(Zmin,size(Population.objs,1),1))./(repmat(Zmax,size(Population.objs,1),1)-repmat(Zmin,size(Population.objs,1),1));
    [~,Region] = max(1-pdist2(SPopObj,W,'cosine'),[],2);
    [value,~]  = sort(Region,'ascend');
    flag       = max(value);
    counter    = histc(value,1:flag);
    Density    = counter(Region);
end
