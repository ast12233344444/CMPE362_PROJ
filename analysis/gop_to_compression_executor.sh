#!/bin/bash

start_range=1
end_range=30
splits=10

ranges=()
step=$(( (end_range - start_range + 1) / splits ))
for ((i=0; i<splits; i++)); do
    start=$(( start_range + i * step ))
    end=$(( start + step - 1 ))
    if [[ $i -eq $((splits - 1)) ]]; then
        end=$end_range
    fi
    ranges+=("$start $end")
done

# Loop through ranges and spawn MATLAB instances for parallel execution
for range in "${ranges[@]}"; do
    start=$(echo $range | cut -d' ' -f1)
    end=$(echo $range | cut -d' ' -f2)

    matlab -nodisplay -r "compress($start, $end); exit;" &
done
