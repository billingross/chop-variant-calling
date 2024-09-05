version 1.0

# WORKFLOW DEFINITION
workflow FastqToBam {
	input {
		File fastq_1
		File fastq_2
		ReferenceFasta reference_fasta
		
		String output_bam
	}

	call BwaMem {
		input: 
			fastq_1 = fastq_1,
			fastq_2 = fastq_2,
			reference_fasta = reference_fasta,
			output_bam = output_bam		
	}

	output {
		File bam = BwaMem.aligned_bam
		File bai = BwaMem.aligned_bai
	}
}

task BwaMem {
	input {
		File fastq_1
		File fastq_2

		# Reference fasta files
		ReferenceFasta reference_fasta
		
		String output_bam
	}

	command <<<
		/usr/gitc/bwa mem -t 2 -v 3 ~{reference_fasta.ref_fasta} ~{fastq_1} ~{fastq_2} | samtools sort -o ~{output_bam}
		samtools index ~{output_bam} ~{output_bam}.bai
		ls 
	>>>
	runtime {
		docker: "us.gcr.io/broad-gotc-prod/samtools-picard-bwa:1.0.2-0.7.15-2.26.10-1643840748"
		memory: "14 GiB"
    	cpu: "2"
    	disks: "local-disk 100 HDD"
	}
	output {
    	File aligned_bam = "~{output_bam}"
    	File aligned_bai = "~{output_bam}.bai"
  	}
}

task IndexBam {
	input {
		File aligned_bam
	}

	command <<<
		samtools index -b ~{aligned_bam} -o ~{aligned_bam}.bai
		ls
	>>>
	runtime {
		docker: "us.gcr.io/broad-gotc-prod/samtools-picard-bwa:1.0.2-0.7.15-2.26.10-1643840748"
		memory: "14 GiB"
    	cpu: "2"
    	disks: "local-disk 100 HDD"
	}
	output {
    	File aligned_bai = "~{aligned_bam}.bai"
  	}
}

struct ReferenceFasta {
  File? ref_dict
  File ref_fasta
  File? ref_fasta_index
  File? ref_alt
  File ref_sa
  File ref_amb
  File ref_bwt
  File ref_ann
  File ref_pac
  File? ref_str
}