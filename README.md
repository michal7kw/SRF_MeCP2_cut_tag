Notebooks:
- CpG_enriched_genes.ipynb
- CpG_targeting_overlap.ipynb
- coverage.ipynb

Scripts:
- final_list.sh
- final_list_to_csv.ipynb


![alt text](pipeline.png)


# Genes list derivation

1. iterative_original
    1. uses aligned reads generated by the snakemake pipeline
2. iterative_alternative
    1. uses aligned reads generated by the iterative_alternative pipeline
3. snake_pipeline
    1. uses aligned reads generated by the snakemake pipeline

# Comparison of peak calling approaches

## iterative_original vs snake_pipeline

Key Differences:
1. **Peak Types**:
- `2a_call_peaks_array.sh`: Calls both narrow and broad peaks in separate MACS2 runs
- Snakemake rule: Only calls narrow peaks

2. **MACS2 Parameters**:
- `2a_call_peaks_array.sh`:
  - Uses `--nolambda`
  - Uses `--bdg` (generates bedGraph files)
  - Uses `--keep-dup auto`
- Snakemake rule:
  - Uses `--call-summits`
  - Uses `--keep-dup all`

## iterative_alternative: MACS2 (/results_alternative) and SEACR (/results_alternative) approaches

Key Differences:

1. **Peak Calling Algorithm**:
- MACS2: 
  - Traditional ChIP-seq peak caller
  - Uses a dynamic Poisson distribution model
  - Estimates local background
- SEACR (Sparse Enrichment Analysis for CUT&RUN):
  - Specifically designed for CUT&TAG/CUT&RUN
  - Uses empirical threshold approach
  - Better at handling sparse data typical of CUT&TAG

2. **Control Usage**:
- MACS2:
  - Uses IgM control directly in peak calling
  - Single pass with control
- SEACR:
  - Runs both with and without IgM control
  - Control-based and threshold-based (0.05) approaches

3. **Output Format**:
- MACS2:
  - Directly outputs narrowPeak/broadPeak formats
  - Generates additional statistics files
- SEACR:
  - Outputs BED format
  - Requires conversion to narrowPeak format
  - Generates AUC (Area Under Curve) files

4. **Data Processing**:
- MACS2:
  - Works directly with BAM files
  - Handles paired-end data natively
- SEACR:
  - Requires bedGraph conversion first
  - More preprocessing steps

Recommendations:

1. **Consider Using Both**:
   - SEACR for primary analysis (CUT&TAG-specific)
   - MACS2 for validation/comparison
   - Compare overlapping peaks for higher confidence

2. **Output Processing**:
   - Standardize output formats
   - Create unified peak sets
   - Consider intersection analysis

## Summary of: comparison of peak calling approaches

1. **MACS2 Parameters Comparison**:

Original MACS2 (`2a_call_peaks_array.sh`):
```shell
macs2 callpeak \
    -f BAMPE \
    -q 0.05 \
    --nomodel \
    --keep-dup auto \
    --nolambda \
    --bdg
```

Alternative MACS2 (`4_call_peaks_array.sh`):
```shell
macs2 callpeak \
    -f BAMPE \
    -q 0.05 \
    --keep-dup all \
    --broad-cutoff 0.1  # for broad peaks
```

Snakemake MACS2:
```shell
macs2 callpeak \
    -f BAMPE \
    -q 0.05 \
    --nomodel \
    --keep-dup all \
    --call-summits
```

Key Differences in MACS2 Approaches:
- `--nolambda`: Original version disables local lambda estimation, which might be better for CUT&TAG's low background
- `--keep-dup`: Varies between `auto` and `all`, with `all` being more appropriate for CUT&TAG
- `--call-summits`: Only in Snakemake version, useful for precise binding site identification
- `--bdg`: Only in original version, generates bedGraph files for visualization

2. **SEACR Implementation**:
```shell
SEACR_1.3.sh \
    "${SAMPLE}.bedgraph" \
    "IgM.bedgraph" \
    non \
    stringent
```

Unique SEACR Features:
- Runs both with and without control
- Uses empirical threshold approach
- Better suited for sparse CUT&TAG data
- More stringent peak calling

3. **Biological Validity Analysis**:

Best Practices for CUT&TAG:
1. **SEACR Approach**:
   - Most biologically valid for CUT&TAG
   - Specifically designed for sparse data
   - Better at handling the unique properties of CUT&TAG signal

2. **MACS2 with Optimized Parameters**:
   - `--keep-dup all`: Important for CUT&TAG as duplicates are often genuine signals
   - `--nomodel`: Appropriate as CUT&TAG doesn't follow ChIP-seq models
   - Broad and narrow peak calling for different binding patterns

Recommendations for Optimal Results:

1. **Primary Analysis**:
   - Use SEACR as the primary peak caller
   - Apply stringent threshold
   - Consider both with and without control analyses

2. **Secondary Validation**:
   - Use MACS2 with these parameters:
     ```shell
     macs2 callpeak \
         -f BAMPE \
         -q 0.05 \
         --nomodel \
         --keep-dup all \
         --nolambda \
         --call-summits
     ```

3. **Peak Set Generation**:
   - Generate consensus peaks between SEACR and MACS2
   - Use SEACR peaks as primary and MACS2 for validation
   - Consider broad peaks for factors with dispersed binding

4. **Control Usage**:
   - Always run both with and without IgG/IgM control
   - Compare results to identify most confident peaks

The most biologically valid approach would be to combine SEACR and MACS2:
1. Use SEACR for primary peak calling
2. Use MACS2 with optimized parameters for validation
3. Focus on peaks identified by both methods
4. Consider biological context (broad vs narrow binding patterns)
5. Use both control-based and control-free analyses


# Comparison of alignment and quality control approaches

Key differences in quality control and alignment between the array scripts and Snakefile implementation:

1. **FastQC Implementation**:

Array Script:
```shell
fastqc \
    ${INPUT_DIR}/${SAMPLE}_R1_001.fastq.gz \
    ${INPUT_DIR}/${SAMPLE}_R2_001.fastq.gz \
    --outdir=results/fastqc \
    --threads=4
```

Snakefile:
```python
rule fastqc:
    ...
    threads: 2
    shell:
        "fastqc {input.r1} {input.r2} -o $(dirname {output.html_r1}) -t {threads}"
```

Key Differences:
- Array uses more threads (4 vs 2)
- Snakefile tracks outputs more explicitly
- Otherwise functionally identical

2. **Trimming Implementation**:

Array Script:
```shell
trim_galore \
    --paired \
    --gzip \
    --fastqc \
    --cores 16 \
    --output_dir results/trimmed \
    ${INPUT_DIR}/${SAMPLE}_R1_001.fastq.gz \
    ${INPUT_DIR}/${SAMPLE}_R2_001.fastq.gz 
```

Snakefile:
```python
trim_galore --paired \
    --gzip \
    --fastqc \
    --cores {threads} \
    --nextera \
    --output_dir {params.output_dir} \
    {input.r1} {input.r2}
```

Key Differences:
- Snakefile includes `--nextera` adapter trimming (important for CUT&TAG)
- Otherwise similar parameters

3. **Alignment Implementation**:

Array Script:
```shell
# Alignment
bowtie2 \
    -p 32 \
    -x $GENOME_INDEX \
    --local --very-sensitive-local \
    --no-mixed --no-discordant \
    --maxins $MAX_FRAGMENT \
    --mm

# Post-processing
samtools view -@ "$THREADS" -b -h -q 20
samtools view -@ "$THREADS" -b -f 2 -F 1804
samtools markdup -@ $THREADS -r
```

Snakefile:
```python
bowtie2 \
    -p {threads} \
    -x {config[genome_index]} \
    --local --very-sensitive-local \
    --no-mixed --no-discordant \
    --maxins {params.max_fragment} \
    --mm \
    | samtools view -@ {threads} -bS -q 30 -
```

Major Differences in Alignment:

1. **Quality Control**:
- Array script has more extensive filtering:
  - Multiple filtering steps
  - Explicit PCR duplicate removal
  - Comprehensive QC metrics (flagstat, idxstats, stats)
  - Library complexity estimation (preseq)
  - Fragment size distribution

2. **Filtering Criteria**:
- Array script:
  - Initial MAPQ ≥ 20
  - Proper pairs (flag 2)
  - Removes specific flags (1804)
  - PCR duplicate removal
- Snakefile:
  - Only MAPQ ≥ 30
  - Less stringent filtering

3. **QC Metrics**:
- Array script generates:
  - Alignment rates
  - Library complexity metrics
  - Fragment size distributions
  - Duplication rates
  - Comprehensive flagstat metrics
- Snakefile:
  - Relies on MultiQC for metrics aggregation
  - Less detailed individual metrics

Recommendations for Improvement:

1. **Combine Best Practices**:
```python
rule align:
    ...
    shell:
        """
        # Initial alignment
        bowtie2 [existing_params] | \
        # Quality filtering
        samtools view -@ {threads} -b -h -q 20 | \
        # Proper pair filtering
        samtools view -@ {threads} -b -f 2 -F 1804 | \
        # Remove duplicates
        samtools markdup -@ {threads} -r - - | \
        # Final sort
        samtools sort -@ {threads} -m {params.sort_memory} > {output.bam}

        # Generate QC metrics
        samtools flagstat {output.bam} > {output.flagstat}
        samtools idxstats {output.bam} > {output.idxstats}
        preseq lc_extrap -B {output.bam} -o {output.complexity}
        """
```

2. **Add QC Thresholds**:
```python
rule qc_check:
    input:
        flagstat = "{sample}.flagstat",
        complexity = "{sample}.complexity"
    run:
        # Check mapping rate
        mapping_rate = float(shell("grep 'mapped (' {input.flagstat} | cut -d'(' -f2 | cut -d'%' -f1"))
        if mapping_rate < 70:
            raise ValueError(f"Low mapping rate: {mapping_rate}%")
        
        # Check complexity
        complexity = float(shell("head -n 2 {input.complexity} | tail -n 1 | cut -f2"))
        if complexity < 0.7:
            raise ValueError(f"Low library complexity: {complexity}")
```

The array script implementation provides more comprehensive QC and filtering, which is particularly important for CUT&TAG data. The Snakefile could be enhanced by incorporating these additional QC steps while maintaining its workflow management advantages.

