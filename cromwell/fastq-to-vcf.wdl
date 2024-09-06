version 1.0

# WORKFLOW DEFINITION
workflow FastqToVcf {
    input {
        File fastq_1
        File fastq_2
        File roi_bed

        ReferenceFasta reference_fasta
        
        String sample_name

        File annotation_file
        File annotation_file_index
        File annotation_header
        String annotation_columns
        String filter_string
    }

    # Align the reads to the hg19 genome
    call BwaMem {
        input: 
            fastq_1 = fastq_1,
            fastq_2 = fastq_2,
            reference_fasta = reference_fasta,
            sample_name = sample_name    
    }

    # Generate quality statistics
    call SamtoolsFlagstat {
        input:
            input_bam = BwaMem.aligned_bam,
            input_bai = BwaMem.aligned_bai
    }

    # Call variants for the region in the bed
    call GatkHaplotypeCaller {
        input:
          input_bam = BwaMem.aligned_bam,
          input_bai = BwaMem.aligned_bai,
          roi_bed = roi_bed,
          reference_fasta = reference_fasta,
          sample_name = sample_name
    }

    # Annotate the variants with gene symbol
    call BcftoolsAnnotate {
        input:
            input_vcf = GatkHaplotypeCaller.vcf,
            annotation_file = annotation_file,
            annotation_file_index = annotation_file_index,
            annotation_header = annotation_header,
            annotation_columns = annotation_columns
    }

    # Apply some filtrations
    call BcftoolsFilter {
        input:
            input_vcf = BcftoolsAnnotate.annotated_vcf,
            filter_string = filter_string
    }

    output {
        File bam = BwaMem.aligned_bam
        File bai = BwaMem.aligned_bai
        File vcf = GatkHaplotypeCaller.vcf
        File annotated_vcf = BcftoolsAnnotate.annotated_vcf
        File filtered_vcf = BcftoolsFilter.filtered_vcf
    }
}

task BwaMem {
    input {
        File fastq_1
        File fastq_2

        # Reference fasta files
        ReferenceFasta reference_fasta
        
        String sample_name
    }

    String output_bam = "~{sample_name}.sorted.bam"

    command <<<
        /usr/gitc/bwa mem -R '@RG\tID:foo\tSM:bar' -t 2 -v 3 ~{reference_fasta.ref_fasta} ~{fastq_1} ~{fastq_2} | samtools sort -o ~{output_bam}
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

task SamtoolsFlagstat {
    input {
        File input_bam
        File input_bai
    }

    command <<<
        samtools flagstat ~{input_bam} > ~{input_bam}.flagstat.data.tsv
        ls 
    >>>
    runtime {
        docker: "us.gcr.io/broad-gotc-prod/samtools-picard-bwa:1.0.2-0.7.15-2.26.10-1643840748"
        memory: "14 GiB"
        cpu: "2"
        disks: "local-disk 100 HDD"
    }
    output {
        File data_tsv = "~{input_bam}.flagstat.data.tsv"
    }
}

task GatkHaplotypeCaller {
  input {
    File input_bam
    File input_bai
    File roi_bed
    ReferenceFasta reference_fasta
    String sample_name
  }

  command <<<
    java -Xmx4g -jar /usr/gitc/GATK35.jar \
        -T HaplotypeCaller  \
        -R ~{reference_fasta.ref_fasta} \
        -I ~{input_bam} \
        -L ~{roi_bed} \
        -o ~{sample_name}.vcf.gz
  >>>
  runtime {
    docker: "us.gcr.io/broad-gotc-prod/gatk:1.3.0-4.2.6.1-1649964384"
    memory: "10 GiB"
    cpu: "1"
    disks: "local-disk 100 HDD"
  }
  output {
    File vcf = "~{sample_name}.vcf.gz"
  }
}

task BcftoolsAnnotate {
    input {
        File input_vcf
        File annotation_file
        File annotation_file_index
        File annotation_header
        String annotation_columns
        String sample_name
    }

    String annotated_vcf_name = "annotated_~{sample_name}.vcf"

    command <<<
        ls -lh annotated_/mnt/disks/cromwell_root/trellis-v2-cromwell/FastqToVcf/*/call-GatkHaplotypeCaller

        bcftools annotate \
        -a ~{annotation_file} \
        -h ~{annotation_header} \
        -c ~{annotation_columns} \
        ~{input_vcf} > ~{annotated_vcf_name}
        
        ls
    >>>
    runtime {
        docker: "biocontainers/bcftools:v1.9-1-deb_cv1"
        memory: "3 GiB"
        disks: "local-disk 100 HDD"
    }
    output {
        File annotated_vcf = "~{annotated_vcf_name}
    }
}

task BcftoolsFilter {
    input {
        File input_vcf
        String filter_string
        String sample_name
    }

    String filtered_vcf_name = "filtered_~{sample_name}.vcf"

    command <<<
        bcftools view -e '~{filter_string}' -o ~{filtered_vcf_name} ~{input_vcf}
        ls
    >>>
    runtime {
        docker: "biocontainers/bcftools:v1.9-1-deb_cv1"
        memory: "3 GiB"
        disks: "local-disk 100 HDD"
    }
    output {
        File filtered_vcf = "~{filtered_vcf_name}"
    }
}

struct ReferenceFasta {
  File ref_dict
  File ref_fasta
  File ref_fai
  File? ref_alt
  File ref_sa
  File ref_amb
  File ref_bwt
  File ref_ann
  File ref_pac
}