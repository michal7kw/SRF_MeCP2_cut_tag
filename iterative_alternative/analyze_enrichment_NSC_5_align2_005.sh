#!/bin/bash
#SBATCH --job-name=enrichment_NSC_5_align2_new_005
#SBATCH --account=kubacki.michal
#SBATCH --mem=32GB
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --mail-type=ALL
#SBATCH --exclusive
#SBATCH --mail-user=kubacki.michal@hsr.it
#SBATCH --error="logs/enrichment_NSC_5_align2_new_005.err"
#SBATCH --output="logs/enrichment_NSC_5_align2_new_005.out"

cd /beegfs/scratch/ric.broccoli/kubacki.michal/SRF_CUTandTAG/iterative_alternative

source /opt/common/tools/ric.cosr/miniconda3/bin/activate
conda activate snakemake

mkdir -p logs

WORKING_DIR="/beegfs/scratch/ric.broccoli/kubacki.michal/SRF_CUTandTAG/iterative_alternative"
DATA_DIR="/beegfs/scratch/ric.broccoli/kubacki.michal/SRF_CUTandTAG/iterative_alternative/results_1"
INPUT_DIR="/beegfs/scratch/ric.broccoli/kubacki.michal/SRF_CUTandTAG/iterative_alternative/results_2_align2_new_005"
RESULTS_DIR="/beegfs/scratch/ric.broccoli/kubacki.michal/SRF_CUTandTAG/iterative_alternative/results_5_align2_new_005"

echo "Copying and renaming peaks from results_2_align2_new_005 to ${RESULTS_DIR}..."
rm -rf "${RESULTS_DIR}/peaks"
mkdir -p "${RESULTS_DIR}/peaks"

# Copy and rename files
for sample in NSCv1 NSCv2 NSCv3 NSCM1 NSCM2 NSCM3; do
    if [ -f "${INPUT_DIR}/peaks/narrow/${sample}_narrow_peaks.narrowPeak" ]; then
        cp "${INPUT_DIR}/peaks/narrow/${sample}_narrow_peaks.narrowPeak" \
           "${RESULTS_DIR}/peaks/${sample}_peaks.narrowPeak"
    else
        echo "Warning: Source file not found for sample ${sample}"
    fi
done

python -u ../scripts/analyze_enrichment_NSC_5.py \
    --working-dir $WORKING_DIR \
    --data-dir $DATA_DIR \
    --results-dir $RESULTS_DIR \
    2>&1 | tee "logs/enrichment_NSC_5_align2_new_005.out"