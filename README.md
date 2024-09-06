# chop-variant-calling

This workflow is designed to perform variant calling on paired-end fastqs using the Cromwell workflow engine running on Google Cloud Platform.

* Output VCF: `filtered_annotated_sample_pe.vcf`
* Workflow definition: `cromwell/fastq-to-vcf.wdl`
* Workflow inputs: `cromwell/fastq-to-vcf-inputs.json`

## Workflow steps and commands

### 1. BWA-MEM

Align the reads to the hg19 genome.

Command:
```
/usr/gitc/bwa mem -R '@RG\tID:foo\tSM:bar' -t 2 -v 3 ~{reference_fasta.ref_fasta} ~{fastq_1} ~{fastq_2} | samtools sort -o ~{output_bam}
samtools index ~{output_bam} ~{output_bam}.bai
```

### 2. Samtools flagstat

Generate quality statistics.

Command:
```
samtools flagstat ~{input_bam} > ~{input_bam}.flagstat.data.tsv
```

### 3. GATK HaplotypeCaller

Call variants for the region in the bed

Command:
```
java -Xmx4g -jar /usr/gitc/GATK35.jar \
    -T HaplotypeCaller  \
    -R ~{reference_fasta.ref_fasta} \
    -I ~{input_bam} \
    -L ~{roi_bed} \
    -o ~{sample_name}.vcf.gz
```

### 4. Bcftools annotate

Annotate the variants with gene symbol.

Command:
```
bcftools annotate \
	-a GCF_000001405.25_GRCh37.p13_feature_table_genes_coding_chr_trunc.txt.gz \
	-h ~{annotation_header} \
	-c CHROM,FROM,TO,INFO/gene \
	~{input_vcf} > annotated_~{input_vcf}
```

### 5. Bcftools view

Apply some filtrations. Filter based on read depth and genotype quality.

Command:
```
bcftools view -e 'INFO/DP < 3 || FORMAT/GQ < 7' -o filtered_~{input_vcf} ~{input_vcf}
```
