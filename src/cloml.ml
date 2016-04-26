open Cmdliner
open Core
open Printf

let in_verbatim input_file output_file =
	let ivcf = In_channel.create input_file in
	let ovcf = Out_channel.create output_file in
	let lines = In_channel.input_lines ivcf in
	let output line = fprintf ovcf "%s\n" line in
	List.iter output lines;
	Out_channel.close ovcf;
	In_channel.close ivcf

let input_file =
	let doc ="The input VCF file to be annotated." in
	Arg.(required & pos 0 (some string) None & info [] ~docv:"INPUT_VCF" ~doc)

let output_file =
	let doc="The annotated VCF file to be written." in
	Arg.(required & pos 1 (some string) None & info [] ~docv:"OUTPUT_VCF" ~doc)

let cmd =
	let doc = "annotate a VCF file with clonality information" in
	let version = "0.0.0" in
	let fmt = `Plain in
	let man = [
		`S "Description";
		`P "$(tname) annotates a given VCF file with clonality information.";
		`P "To annotate a VCF file";
		`P "$(tname) input.vcf output.vcf"
	] in
	Term.(const in_verbatim $ input_file $ output_file),
	Term.(info "cloml" ~version ~doc ~man ~fmt)

let () = 
	match Cmdliner.Term.eval cmd with 
	| `Error _ -> exit 1
	| _ -> exit 0