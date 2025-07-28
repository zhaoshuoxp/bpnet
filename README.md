# BPNet
This is a modified verison of original BPnet developed by **Kundaje lab [bpnet](https://circleci.com/gh/kundajelab/bpnet)**.

BPNet is a python package with a CLI to train and interpret base-resolution deep neural networks trained on functional genomics data such as ChIP-nexus or ChIP-seq.

 Cite：*Deep learning at base-resolution reveals motif syntax of the cis-regulatory code* (http://dx.doi.org/10.1101/737981.)

## Getting started

BPNet GPU version uses tensorflow v1, cuDNN v7 and CUDA v8, which is not supported by NVIDIA L4 with drivers 5XX+.  **Use CPU version only**.

To install, first have conda setup (*skip if you already have*): 

```shell
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm ~/miniconda3/miniconda.sh
```

Use `install_conda_env.sh` to create conda env:

```shell
git clone https://github.com/zhaoshuoxp/bpnet.git
cd bpnet
chmod 755 install_conda_env.sh
./install_conda_env.sh
conda activate bpnet
```



## Main commands

1. You will need to create `dataspec.yml` and stranded bigwig files for ChIPseq:

 ```shell
 # Use split_bw.sh in the repo to create the pos/+ and neg/- stranded bigwig files from BAM:
 ./split_bw.sh -g hg38 -o TCF21 TCF21.bam
 ```

​	Then make the dataspec.yml like below:

```yaml
fasta_file: ./hg38.fa # reference genome fasta file

task_specs:  # specifies multiple tasks 
  TCF21:
    tracks:
      - ./TCF21_pos.bw
      - ./TCF21_neg.bw
    peaks: ./tcf21.peaks.bed # from macs2 output, primary chr only
  
bias_specs:  # specifies multiple bias tracks
  input:  # first bias track
    tracks:  # can specify multiple tracks
      - ./Input_pos.bw
      - ./Input_neg.bw
    tasks:  # applies to the task
      - TCF21
  # NOTE: bias_specs don't specify peaks since they are only used
  # to correct for biasesInputC.bw

```



2. Compute data statistics to inform hyper-parameter selection such as choosing to trade off profile vs total count loss (`lambda` hyper-parameter):

```bash
bpnet dataspec-stats dataspec.yml
```

3. Train a model on BigWig tracks specified in [dataspec.yml](examples/chip-nexus/dataspec.yml) using an existing architecture [bpnet9](bpnet/premade/bpnet9-pyspec.gin) on 200 bp sequences with 6 dilated convolutional layers:

```bash
bpnet train --premade=bpnet9 dataspec.yml --override='seq_width=200;n_dil_layers=6;lamda=X.XX' . # replace lamda with dataspec-stats result
```

4. `bpnet train` creates a random folder with UUID like `45b5eb18-d835-4897-9815-a6c9aec06791`, go in to this folder and compute contribution scores for regions specified in the `dataspec.yml` file and store them into `contrib.scores.h5`

```bash
cd 45b5eb18-d835-4897-9815-a6c9aec06791 # replace to you actual folder
bpnet contrib . --method=deeplift contrib.scores.h5
```

5. Export BigWig tracks containing model predictions and contribution scores

```bash
bpnet export-bw . --regions=intervals.bed --scale-contribution bigwigs/ #replace intervals.bed to the peaks or the genomic regions 
```

6. Discover motifs with TF-MoDISco using contribution scores stored in `contrib.scores.h5`, premade configuration [modisco-50k](bpnet/premade/modisco-50k.gin) and restricting the number of seqlets per metacluster to 20k:

```bash
bpnet modisco-run contrib.scores.h5 --premade=modisco-50k --override='TfModiscoWorkflow.max_seqlets_per_metacluster=20000' modisco/
```

7. Determine motif instances with CWM scanning and store them to `motif-instances.tsv.gz`

```bash
bpnet cwm-scan modisco/ --contrib-file=contrib.scores.h5 modisco/motif-instances.tsv.gz
```

8. Generate additional reports suitable for ChIP-nexus or ChIP-seq data:

```bash
bpnet chip-nexus-analysis modisco/
```

Note: these commands are also accessible as python functions:
- `bpnet.cli.train.bpnet_train`
- `bpnet.cli.train.dataspec_stats`
- `bpnet.cli.contrib.bpnet_contrib`
- `bpnet.cli.export_bw.bpnet_export_bw`
- `bpnet.cli.modisco.bpnet_modisco_run`
- `bpnet.cli.modisco.cwm_scan`
- `bpnet.cli.modisco.chip_nexus_analysis`
