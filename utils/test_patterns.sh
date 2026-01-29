#!/bin/bash
export ADVANCED_CHOICE_OVERRIDE=0
export PATTERN_CHOICE_OVERRIDE=0
ADVANCED_MAX=2
PATTERN_MAX=12
OUTER_ELAPSED_TIME=0
OUTER_ELAPSED_HOURS=0
OUTER_ELAPSED_MINUTES=0
OUTER_ELAPSED_SECONDS=0
OUTER_PRETTY_LOG_ELAPSED=""
PADDING="°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°"

while [ "$ADVANCED_CHOICE_OVERRIDE" -lt "$ADVANCED_MAX" ]; do 
    export PATTERN_CHOICE_OVERRIDE=0
    while [ "$PATTERN_CHOICE_OVERRIDE" -lt "$PATTERN_MAX" ]; do
        if [ "$ADVANCED_CHOICE_OVERRIDE" -ge 1 ] && [ "$PATTERN_CHOICE_OVERRIDE" -gt 0 ]; then
            let "PATTERN_CHOICE_OVERRIDE=$PATTERN_MAX"
            export PATTERN_CHOICE_OVERRIDE
            continue
        fi
        printf "Running test for ADVANCED_CHOICE_OVERRIDE=%d and PATTERN_CHOICE_OVERRIDE=%d: " "$ADVANCED_CHOICE_OVERRIDE" "$PATTERN_CHOICE_OVERRIDE"
        FILE_PATH="./pattern_testing_aco_${ADVANCED_CHOICE_OVERRIDE}_pco_${PATTERN_CHOICE_OVERRIDE}.log"
        echo "Testing builtin patterns for find for the script" > "$FILE_PATH"
        OUTER_RUN_START_TIME=$(date +%s)
        echo "$PADDING" >> "$FILE_PATH"
        echo "ADVANCED_CHOICE_OVERRIDE = $ADVANCED_CHOICE_OVERRIDE" >> "$FILE_PATH"
        echo "PATTERN_CHOICE_OVERRIDE = $PATTERN_CHOICE_OVERRIDE" >> "$FILE_PATH"
        echo "$PADDING" >> "$FILE_PATH"
        ./builder.sh >> "$FILE_PATH" 2>&1
        STATUS=$?
        echo "$PADDING" >> "$FILE_PATH"
        echo "End of run" >> "$FILE_PATH"
        OUTER_NOW=$(date +%s)
        OUTER_ELAPSED_TIME=$((OUTER_NOW - OUTER_RUN_START_TIME))
        OUTER_ELAPSED_HOURS=$((OUTER_ELAPSED_TIME / 3600))
        OUTER_ELAPSED_MINUTES=$(((OUTER_ELAPSED_TIME % 3600) / 60))
        OUTER_ELAPSED_SECONDS=$((OUTER_ELAPSED_TIME % 60))
        printf "total run time: [%02d:%02d:%02d]\n" "$OUTER_ELAPSED_HOURS" "$OUTER_ELAPSED_MINUTES" "$OUTER_ELAPSED_SECONDS" >> "$FILE_PATH"
        echo "$PADDING" >> "$FILE_PATH"
        if [ $STATUS -ne 0 ]; then
            printf "[%02d:%02d:%02d] KO\n" "$OUTER_ELAPSED_HOURS" "$OUTER_ELAPSED_MINUTES" "$OUTER_ELAPSED_SECONDS"
        else
            printf "[%02d:%02d:%02d] OK\n" "$OUTER_ELAPSED_HOURS" "$OUTER_ELAPSED_MINUTES" "$OUTER_ELAPSED_SECONDS"
        fi
        let "PATTERN_CHOICE_OVERRIDE=$PATTERN_CHOICE_OVERRIDE+1"
        export PATTERN_CHOICE_OVERRIDE
    done
    let "ADVANCED_CHOICE_OVERRIDE=$ADVANCED_CHOICE_OVERRIDE+1"
    export ADVANCED_CHOICE_OVERRIDE
done
