%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function roiList = filter_rois_by_overlap(roiList, samplePT, sampleIT, min_overlap)
    Xpt = local_build_union_finite_mask(samplePT);
    Xit = local_build_union_finite_mask(sampleIT);
    keep = false(numel(roiList), 1);
    for i = 1:numel(roiList)
        Vr = spm_vol(roiList{i});
        Xr = spm_read_vols(Vr);
        Xr = (Xr > 0) & isfinite(Xr);
        if isequal(size(Xr), size(Xpt)) && isequal(size(Xr), size(Xit))
            ovPT = nnz(Xr & Xpt);
            ovIT = nnz(Xr & Xit);
            keep(i) = (ovPT >= min_overlap) && (ovIT >= min_overlap);
        else
            keep(i) = false;
        end
    end
    roiList = roiList(keep);
end