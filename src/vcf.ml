open Core
open Core_kernel
open Printf
module String = Sosa.Native_string

let starts_with needle haystack =
  match String.sub haystack 0 (String.length needle) with
  | None -> false
  | Some text -> text = needle

let tab_split = String.split ~on:(`Character '\t')

let rec find ?(count=0) needle haystack =
  match haystack with
  | [] -> -1
  | head :: tail -> 
    if head = needle 
      then count 
      else find needle tail ~count:(count + 1)

let add_header new_line format_str lines =
  let is_format_def line = starts_with format_str line in
  let correct_location line1 line2 = 
    (not (is_format_def line1)) && (is_format_def line2) in
  let insert line acc =
    match acc with
    | [] -> line :: acc
    | next_line :: tail -> 
      if correct_location line next_line
        then line :: new_line :: acc
        else line :: acc in
  List.fold_right insert lines []

let add_clonality_format lines =
  let cl_id = "CL" in
  let cl_desc = "\"Clonality annotations: clonal/subclonal, probability\"" in
  let cl_line = "##FORMAT=<ID=" ^ 
          cl_id ^ 
          ",Number=1,Type=String," ^
          "Description=" ^ cl_desc ^ ">" in
  add_header cl_line "##FORMAT" lines

let add_clonality_header ~purities ~num_of_clones ~samples lines =
  let combine = String.concat ~sep:"," in
  let hline =
    sprintf "##Clonality=<Purity=[%s],NumberOfClones=[%s],Samples=[%s]>"
      (combine purities) (combine num_of_clones) (combine samples)
  in
  add_header hline "##INFO" lines

let extract_vafs sample_idx format_idx lines use_all_variants =
  let extract_vaf line =
    let columns = tab_split line in
    let (sample, format) = 
      List.nth columns sample_idx, List.nth columns format_idx
    in
    let af_idx = 
      let ffields = String.split format (`Character ':') in
      let fidx = max (find "AF" ffields) (find "FA" ffields) in
      if fidx < 0 
        then failwith "Couldn't find the VAF information in the VCF."
        else fidx
    in
    let af =
      List.nth (String.split sample (`Character ':')) af_idx
    in
    float_of_string af
  in
  let filter_variants line =
    if use_all_variants
    then true
    else ((List.nth (tab_split line) 6) = "PASS")
  in
  List.filter (fun line -> not (starts_with "#" line)) lines
  |> List.filter filter_variants
  |> List.map extract_vaf

let process
    input_file
    output_file
    use_all_variants
    print_stats
  =
  let ivcf = In_channel.create 
    (match input_file with None -> "/dev/stdin" | Some i -> i)
  in
  let ovcf = Out_channel.create
    (match output_file with None -> "/dev/stdout" | Some o -> o)
  in
  let lines = In_channel.input_lines ivcf in
  let column_names =
    List.filter (fun line -> starts_with "#CHROM" line) lines
    |> List.hd
    |> tab_split
  in
  let format_idx = find "FORMAT" column_names in
  let purities, num_of_clones, samples =
    let p_all = ref [] in
    let noc_all = ref [] in
    let samples_all = ref [] in
    for idx=9 to ((List.length column_names) - 1) do
      let vafs = extract_vafs idx format_idx lines use_all_variants in
      let purity = Estimate.purity vafs in
      let purity_str = sprintf "%1.3f" purity in
      let noc = Estimate.number_of_clones vafs in
      let sample = List.nth column_names idx in
      p_all := purity_str :: !p_all;
      noc_all := noc :: !noc_all;
      samples_all := sample :: !samples_all
    done;
    !p_all, !noc_all, !samples_all
  in
  add_clonality_header ~purities ~num_of_clones ~samples lines
    |> add_clonality_format
    |> List.iter (fun line -> fprintf ovcf "%s\n" line);
  Out_channel.close ovcf;
  In_channel.close ivcf
