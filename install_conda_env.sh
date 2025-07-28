#!/bin/bash

conda env create -f conda-env.yml

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate bpnet

mkdir -p $CONDA_PREFIX/etc/conda/activate.d


cat <<EOF > $CONDA_PREFIX/etc/conda/activate.d/env_vars.sh
#!/bin/bash
export NUMEXPR_MAX_THREADS=256
export PYTHONWARNINGS="ignore::DeprecationWarning,ignore::FutureWarning"
EOF

chmod +x $CONDA_PREFIX/etc/conda/activate.d/env_vars.sh
