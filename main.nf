#!/usr/bin/env nextflow

/*
 *
 * Author: Shyaman Jayasundara
 * jmshyaman@eng.pdn.ac.lk
 * 
 */

params.reads = "$launchDir/*{1,2}*.{fq,fastq}"
params.outdir = "$launchDir/results"
params.fastqs_conf = "$projectDir/fastq_screen/fastq_screen.conf"
params.fastqs_subset = 0

Channel
    .fromFilePairs(params.reads)
    .ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
    .into { read_pairs_ch; read_pairs2_ch } 

fastq_screen_file = file(params.fastqs_conf)
subset = params.fastqs_subset

process fastq_screen {
    maxForks 1
    
    publishDir "$params.outdir/fastq_screen", mode:'copy'
    tag "$sample_id"

	input:
        set sample_id, file(reads) from read_pairs_ch
        file fastq_screen_conf from fastq_screen_file

	output:
        file("fastq_screen_${sample_id}_logs") into fastq_screen_ch

	
	shell:
		"""
        mkdir fastq_screen_${sample_id}_logs
		fastq_screen \
			--subset ${subset} \
            --force \
			--conf ${fastq_screen_conf} \
			--aligner bowtie2 \
            --outdir fastq_screen_${sample_id}_logs \
			${reads[0]} ${reads[1]}
		"""
}

process fastqc {
    cpus 2
    publishDir "$params.outdir/fastqc", mode:'copy'
    tag "FASTQC on $sample_id"

    input:
    set sample_id, file(reads) from read_pairs2_ch

    output:
    file("fastqc_${sample_id}_logs") into fastqc_ch


    script:
    """
    mkdir fastqc_${sample_id}_logs
    fastqc -o fastqc_${sample_id}_logs --threads 2 -f fastq -q ${reads}
    """  
}

process multiqc {
    publishDir params.outdir, mode:'copy'
       
    input:
    file('*') from fastq_screen_ch.mix(fastqc_ch).collect().ifEmpty([])
    
    output:
    file('multiqc_report.html')  
     
    script:
    """
    multiqc . 
    """
}
 
workflow.onComplete { 
	log.info( workflow.success ? "\nDone! Open the following report in your browser --> $params.outdir/multiqc_report.html\n" : "Oops .. something went wrong" )
}
