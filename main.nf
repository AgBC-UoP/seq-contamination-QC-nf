#!/usr/bin/env nextflow

params.reads = "$baseDir/*{1,2}*.{fq,fastq}"
params.reference = "$baseDir/data/ggal/ggal_1_48850000_49020000.Ggal71.500bpflank.fa"
params.outdir = "results"
params.multiqc = "$baseDir/multiqc"

Channel
    .fromFilePairs(params.reads)
    .ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
    .into { read_pairs_ch; read_pairs2_ch } 

multiqc_file = file(params.multiqc)

// process index {
//     tag "$reference_file.simpleName"
    
//     input:
//     file reference from reference_file
     
//     output:
//     file 'index' into index_ch

//     script:       
//     """
//     bowtie2-build --threads $task.cpus $reference index
//     """
// }

process fastq_screen {

	// custom label
    tag "$sample_id"

	input:
        // file index from index_ch
        set sample_id, file(reads) from read_pairs_ch

	output:
        file("fastq_screen_${sample_id}_logs") into fastq_screen_ch

	
	shell:
		"""
        mkdir fastq_screen_${sample_id}_logs
		fastq_screen \
			--threads ${task.cpus} \
            --outdir fastq_screen_${sample_id}_logs \
			${reads[0]}
        fastq_screen \
			--threads ${task.cpus} \
            --outdir fastq_screen_${sample_id}_logs \
			${reads[1]}
		"""
}

process fastqc {
    tag "FASTQC on $sample_id"

    input:
    set sample_id, file(reads) from read_pairs2_ch

    output:
    file("fastqc_${sample_id}_logs") into fastqc_ch


    script:
    """
    mkdir fastqc_${sample_id}_logs
    fastqc -o fastqc_${sample_id}_logs -f fastq -q ${reads}
    """  
}

process multiqc {
    publishDir params.outdir, mode:'copy'
       
    input:
    file('*') from fastq_screen_ch.mix(fastqc_ch).collect().ifEmpty([])
    file(config) from multiqc_file
    
    output:
    file('multiqc_report.html')  
     
    script:
    """
    cp $config/* .
    echo "custom_logo: \$PWD/logo.png" >> multiqc_config.yaml
    multiqc . 
    """
}
 
workflow.onComplete { 
	println ( workflow.success ? "\nDone! Open the following report in your browser --> $params.outdir/multiqc_report.html\n" : "Oops .. something went wrong" )
}