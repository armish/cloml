open Core
open Core_kernel
open Printf
module String = Sosa.Native_string

let starts_with needle haystack =
  match String.sub haystack 0 (String.length needle) with
  | None -> false
  | Some text -> text = needle

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

let add_clonality_header ?(purity=".") ?(num_of_clones=".") lines =
  let hline = "##Clonality=<Purity=" ^ purity ^ "," ^
        "NumberOfClones=" ^ num_of_clones ^ ">" in
  add_header hline "##INFO" lines


let extract_vafs lines sample_name filter_pass =
  let tab_split = String.split ~on:(`Character '\t') in
  let rec find ?(count=0) sample columns =
    match columns with
    | [] -> -1
    | head :: tail -> 
      if head = sample 
        then count 
        else find sample tail ~count:(count + 1) in
  let (sample_idx, info_idx) = 
    let columns 
      = List.filter (fun line -> starts_with "#CHROM" line) lines
      |> List.hd
      |> tab_split in
    find sample_name columns, find "FORMAT" columns in
  let extract_vaf line =
    let columns = tab_split line in
    let (sample, info) = 
      List.nth columns sample_idx, List.nth columns info_idx in
    let ad_idx = 
      let ifields = String.split info (`Character ':') in
      find "AD" ifields in
    let ads =
      List.nth (String.split sample (`Character ':')) ad_idx in
    let ad_normal, ad_tumor =
      let adlist = String.split ads (`Character ',') in
      float_of_string (List.nth adlist 0), 
      float_of_string (List.nth adlist 1) in
    ad_tumor /. (ad_tumor +. ad_normal) in
  let filter_variants line =
    if filter_pass
    then ((List.nth (tab_split line) 6) = "PASS")
    else true
  in
  List.filter (fun line -> not (starts_with "#" line)) lines
  |> List.filter filter_variants
  |> List.map extract_vaf

let process sample_name filter_pass input_file output_file =
  let ivcf = In_channel.create input_file in
  let ovcf = Out_channel.create output_file in
  let lines = In_channel.input_lines ivcf in
  let output line = fprintf ovcf "%s\n" line in
  let purity =
    extract_vafs lines sample_name filter_pass
    |> Estimate.purity 
  in
  let purity_str = string_of_float (purity) in
  add_clonality_header ~purity:purity_str lines
    |> add_clonality_format
    |> List.iter output;
  Out_channel.close ovcf;
  In_channel.close ivcf
