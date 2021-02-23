# seq-contamination-QC-nf
Nextflow workflow - Fastq screen contamination check and FastQC report

### you can run this workflow using the following command

``` nextflow run AgBC-UoP/seq-contamination-QC-nf -r main --reads {readDir/READ_PATTERN}```

ex : ``` nextflow run AgBC-UoP/seq-contamination-QC-nf -r main --reads "*R{1,2}*.fastq"```

optioinal commands:

`--fastqs_conf` - path to fastqc_screen [config file](https://github.com/AgBC-UoP/seq-contamination-QC-nf/blob/main/fastq_screen/fastq_screen.conf)

`--fastqs_subset` - subset read count
