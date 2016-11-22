open Oml.Statistics.Descriptive

let purity vafs = 
  let expected_vaf = 0.5 in
  let median_vaf = median (Array.of_list vafs) in
  median_vaf /. expected_vaf

let number_of_clones vafs = "."