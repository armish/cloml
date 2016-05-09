open Oml.Statistics.Descriptive

let purity ?(precision=0.001) vafs = 
  let expected_vaf = 0.5 in
  let evaluate_center old_est new_est =
    let old_center, old_count = old_est and
        new_center, new_count = new_est in
    if new_count > old_count
      then new_center, new_count
      else old_center, old_count in
  let estimated_vaf = 
    Array.of_list vafs 
    |> histogram (`Width precision) 
    |> Array.fold_left evaluate_center (0., 0)
    |> (fun (center, count) -> center) 
    |> min expected_vaf in
  estimated_vaf /. expected_vaf
