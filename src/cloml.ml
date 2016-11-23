open Cmdliner

let input_file =
  let doc = "The input VCF file to be annotated." in
  Arg.(value & opt (some string) None & info ["i"; "input-vcf"] ~docv:"VCF_IN" ~doc)

let output_file =
  let doc = "The annotated VCF file to be written." in
  Arg.(value & opt (some string) None & info ["o"; "output-vcf"] ~docv:"VCF_OUT" ~doc)

let use_all_variants =
  let doc = "Use all variants regardless of their filter status (PASS/REJECT)." in
  Arg.(value & flag & info ["use-all-variants"] ~doc)

let fail_safe =
  let doc = 
    "Keep running even if VCF parsing fails. \
     Failures will result in empty annotations ('.') and \
     error messages will be written to stderr."
  in
  Arg.(value & flag & info ["fail-safe"] ~doc)

let print_stats =
  let doc = "Just print summary statistics and do not annotate." in
  Arg.(value & flag & info ["s"; "summary"] ~doc)

let cmd =
  let doc = "annotate a VCF file with clonality information" in
  let version = "0.0.0" in
  let man = [
    `S "Description";
    `P "$(tname) annotates a given VCF file with clonality information.";
    `P "To annotate a VCF file";
    `P "$(tname) --input-vcf input.vcf --output-vcf output.vcf";
    `P "Or:";
    `P "cat input.vcf |$(tname) > output.vcf"
  ] in
  Term.(const
    Vcf.process
    $ input_file
    $ output_file
    $ use_all_variants
    $ print_stats
    $ fail_safe
  ),
  Term.(info "cloml" ~version ~doc ~man)

let () = 
  match Cmdliner.Term.eval cmd with 
  | `Error _ -> exit 1
  | _ -> exit 0
