version 1.0

struct LaneSubset {
  String name
  String sampleName
  String libraryName
  String description

  String sequencingCenter
  String runDate

  Array[File] fastqs
}

struct OutputAlignment {
  String laneSubsetName
  String libraryName

  File bam
  File bai

  Int alignedFragments
  Int totalReads

  Int duplicateFragments
  Float percentDuplicateFragments

  Int estimatedLibrarySize
}

# Aligns FASTQ files for a set of sequencing Lane Subsets

workflow Alignment {
  input {
    # Information about the lane subsets
    Array[LaneSubset] laneSubsets

    # Reference genome name
    String genomeName = 'hg19'

    # Base URI for reference genome files (= file URI without the extension)
    String referenceUri

    # Docker image URI
    String dockerImage
  }

  Boolean paired = length(laneSubsets[0].fastqs) == 2

  # Indexed reference fasta file (FM index is required for this file)
  File referenceFasta = referenceUri + '.fasta'

  # The FM-index list of files
  File referenceAmb = referenceUri + '.fasta.amb'
  File referenceAnn = referenceUri + '.fasta.ann'
  File referenceBwt = referenceUri + '.fasta.bwt'
  File referencePac = referenceUri + '.fasta.pac'
  File referenceSA = referenceUri + '.fasta.sa'

  scatter (laneSubset in laneSubsets) {
    scatter (fastq in laneSubset.fastqs) {
      call Align {
        input:
          fastq = fastq,
          fasta = referenceFasta,
          amb = referenceAmb,
          ann = referenceAnn,
          bwt = referenceBwt,
          pac = referencePac,
          sa = referenceSA,
          dockerImage = dockerImage,
      }
    }

    call AlignSam {
      input:
        laneSubset = laneSubset,
        assemblyName = genomeName,
        fasta = referenceFasta,
        amb = referenceAmb,
        ann = referenceAnn,
        bwt = referenceBwt,
        pac = referencePac,
        sa = referenceSA,
        sais = Align.sai,
        dockerImage = dockerImage,
    }

    call SamToBam {
      input:
        sam = AlignSam.sam,
        dockerImage = dockerImage,
    }

    call SortBam {
      input:
        bam = SamToBam.bam,
        dockerImage = dockerImage,
    }

    call MarkDuplicates {
      input:
        bam = SortBam.outBam,
        paired = paired,
        dockerImage = dockerImage,
    }

    call IndexBam {
      input:
        bam = MarkDuplicates.outBam,
        dockerImage = dockerImage,
    }

    call CollectMetrics {
      input:
        bam = MarkDuplicates.outBam,
        fasta = referenceFasta,
        paired = paired,
        dockerImage = dockerImage,
    }

    OutputAlignment alignment = object {
      laneSubsetName: laneSubset.name,
      libraryName: laneSubset.libraryName,

      bam: MarkDuplicates.outBam,
      bai: IndexBam.bai,

      alignedFragments: CollectMetrics.alignedFragments,
      totalReads: CollectMetrics.totalReads,

      duplicateFragments: MarkDuplicates.duplicates,
      percentDuplicateFragments: MarkDuplicates.percentDuplication * 100,
      estimatedLibrarySize: MarkDuplicates.librarySize,
    }
  }

  output {
    Array[OutputAlignment] alignments = alignment
  }
}

# Generates alignments in the SAM format,
# given paired-end reads using BWA 'samse' command.
#
# Requires an indexed reference fasta,
# preliminary calculated suffix array indexes,
# and FASTQ files with reads.
#
# Outputs a SAM file.

task Align {
  input {
    File fastq

    File fasta
    File amb
    File ann
    File bwt
    File pac
    File sa

    String dockerImage
  }

  Int cpu = 64
  Int memory = ceil(1.25 * size([
    fastq,
    fasta,
    bwt,
    pac,
    sa,
  ], 'G'))

  String saiName = 'out.sai'

  command <<<
    bwa aln -t ~{cpu} '~{fasta}' '~{fastq}' > '~{saiName}'
  >>>

  runtime {
    docker: dockerImage
    cpu: cpu
    memory: memory + 'G'
    disks: 'local-disk 375 LOCAL'
  }

  output {
    File sai = saiName
  }
}

task AlignSam {
  input {
    LaneSubset laneSubset

    String assemblyName
    File fasta
    File amb
    File ann
    File bwt
    File pac
    File sa

    Array[File] sais

    String dockerImage
  }

  Array[String] header = [
    '@RG',
    'ID:' + laneSubset.name,
    'SM:' + laneSubset.sampleName,
    'LB:' + laneSubset.libraryName,
    'DS:' + laneSubset.description,
    'PL:' + 'ILLUMINA',
    'CN:' + laneSubset.sequencingCenter,
    'DT:' + laneSubset.runDate,
    'UR:' + sub(fasta, 'gs:', ''),
    'AS:' + assemblyName,
    'PG:' + 'bwa',
  ]

  Boolean paired = length(laneSubset.fastqs) == 2
  String command = if paired then 'sampe -P' else 'samse'

  Int memory = ceil(1.25 * size(flatten([
    laneSubset.fastqs,
    [fasta, bwt, pac, sa],
    sais,
  ]), 'G'))

  String samName = 'out.sam'

  command <<<
    set -e

    echo -n '~{sep="\t" header}\tPU:' > 'header.txt'

    # extract Platform Unit from the 1st FASTQ
    gunzip -c '~{laneSubset.fastqs[0]}' | head -1 |
      awk -F: '{print $3,$4,$10}' OFS=. \
      >> 'header.txt'

    bwa ~{command} \
      -r "$(< header.txt)" \
      '~{fasta}' \
      '~{sep="' '" sais}' \
      '~{sep="' '" laneSubset.fastqs}' \
      > '~{samName}'
  >>>

  runtime {
    docker: dockerImage
    memory: memory + 'G'
    disks: 'local-disk 375 LOCAL'
  }

  output {
    File sam = samName
  }
}

# Converts an input SAM file into BAM file
# using 'samtools view' command with the following flags:
#   -b Output in the BAM format.
#   -h Include the header in the output.
#   -S Ignored for compatibility with previous samtools versions
#      (indicates input SAM format)

task SamToBam {
  input {
    File sam
    String dockerImage
  }

  Int diskSize = ceil(1.25 * size(sam, 'G') + 1)
  String bamName = 'out.bam'

  command <<<
    samtools view -bhS -o '~{bamName}' '~{sam}'
  >>>

  runtime {
    docker: dockerImage
    disks: 'local-disk ~{diskSize} HDD'
  }

  output {
    File bam = bamName
  }
}

# Sorts an input BAM file

task SortBam {
  input {
    File bam
    String dockerImage
  }

  String outBamName = 'out.bam'

  command <<<
    samtools sort -o '~{outBamName}' -T 'sorted_temp' '~{bam}'
  >>>

  runtime {
    docker: dockerImage
  }

  output {
    File outBam = outBamName
  }
}

# Runs MarkDuplicates tool from Picard Tools.
# This task processes an input file BAM file
# and creates a new file, where SAM flag set for reads,
# detected as duplicates.
#
# Also outputs a metrics file
# containing BAM file duplicates statistics

task MarkDuplicates {
  input {
    File bam
    Boolean paired

    String dockerImage
  }

  String outBamName = 'out.bam'

  command <<<
    java -Xmx3g -jar /opt/picard.jar \
      MarkDuplicates \
        INPUT='~{bam}' \
        OUTPUT='~{outBamName}' \
        METRICS_FILE=metrics.txt \
        VALIDATION_STRINGENCY=LENIENT

    sed -r '/^(#.*|)$/d' metrics.txt | # remove comments and empty lines
      sed 's/\t$/\t0/' # add 0 as library size, if missing
  >>>

  runtime {
      docker: dockerImage
      memory: '4G'
  }

  output {
    File outBam = outBamName

    Object metrics = read_object(stdout())

    Int duplicates = if paired
      then metrics['READ_PAIR_DUPLICATES']
      else metrics['UNPAIRED_READ_DUPLICATES']

    Float percentDuplication = metrics['PERCENT_DUPLICATION']
    Int librarySize = metrics['ESTIMATED_LIBRARY_SIZE']
  }
}

# Builds 'bai' index for an input BAM file

task IndexBam {
  input {
    File bam
    String dockerImage
  }

  String baiName = 'out.bai'

  command <<<
    samtools index '~{bam}' '~{baiName}'
  >>>

  runtime {
    docker: dockerImage
  }

  output {
    File bai = baiName
  }
}

# Runs CollectAlignmentSummaryMetrics from Picard Tools.
# This tool produces metrics detailing the quality of the read alignments
# as well as the proportion of the reads that passed machine signal-to-noise
# threshold quality filters.
# Metric outputs result in a text format, containing input file statistics.

task CollectMetrics {
  input {
    File bam
    File fasta
    Boolean paired

    String dockerImage
  }

  String category = if paired then 'FIRST_OF_PAIR' else 'UNPAIRED'

  Int memory = 4
  Int javaMemory = ceil((memory - 0.5) * 1000)

  command <<<
    java -Xmx~{javaMemory}m -jar /opt/picard.jar \
      CollectAlignmentSummaryMetrics \
        INPUT='~{bam}' \
        METRIC_ACCUMULATION_LEVEL=LIBRARY \
        METRIC_ACCUMULATION_LEVEL=READ_GROUP \
        OUTPUT=metrics.txt \
        VALIDATION_STRINGENCY=LENIENT \
        REFERENCE_SEQUENCE='~{fasta}'

    grep -E 'CATEGORY|~{category}' metrics.txt |
      head -2 | cut -f 1-24
  >>>

  runtime {
    docker: dockerImage
    memory: memory + 'G'
  }

  output {
    Object metrics = read_object(stdout())

    Int totalReads = metrics['TOTAL_READS']

    Int alignedFragments = if paired
      then metrics['READS_ALIGNED_IN_PAIRS']
      else metrics['PF_READS_ALIGNED']
  }
}
