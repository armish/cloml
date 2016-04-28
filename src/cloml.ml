open Cmdliner

let input_file =
	let doc ="The input VCF file to be annotated." in
	Arg.(required & pos 0 (some string) None & info [] ~docv:"INPUT_VCF" ~doc)

let output_file =
	let doc="The annotated VCF file to be written." in
	Arg.(required & pos 1 (some string) None & info [] ~docv:"OUTPUT_VCF" ~doc)

let cmd =
	let doc = "annotate a VCF file with clonality information" in
	let version = "0.0.0" in
	let man = [
		`S "Description";
		`P "$(tname) annotates a given VCF file with clonality information.";
		`P "To annotate a VCF file";
		`P "$(tname) input.vcf output.vcf"
	] in
	Term.(const Vcf.process $ input_file $ output_file),
	Term.(info "cloml" ~version ~doc ~man)

let () = 
	match Cmdliner.Term.eval cmd with 
	| `Error _ -> exit 1
	| _ -> exit 0