Place all .m files in the following structure:

  /analysis_folder/
      PT_IT_decoding.m
      utility_functions/
          parse_tokens_from_betas.m
          check_class_balance.m
          map_labels.m
          resolve_rois.m
          reslice_rois_force_to_ref_and_return_rpaths.m
          verify_roi_grid_and_autofix.m
          dedup_by_basename_prefer_r_in_dir.m
          filter_rois_by_overlap.m
          local_build_union_finite_mask.m
          count_mask_voxels.m
          getbase.m
          cleanup_tempdir.m

Usage examples:
  PT_IT_decoding('P101')
  PT_IT_decoding('P101', {'/path_to_ROI_1.nii', '/path_to_ROI_2.nii'})
  PT_IT_decoding('P101', '/path_to_ROIs')