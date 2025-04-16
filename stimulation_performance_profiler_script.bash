#!/usr/bin/bash

# Formatting and Color codes
COLOR_RESET="\e[0m"
COLOR_HEADING="\e[1;4;38;5;196;48;5;190m"     # Bold, Underlined, Red on bg 190
COLOR_MENU="\e[1;4;38;5;159m"                 # Bold, Underlined, Blue-ish (159)
COLOR_PROMPT="\e[1;38;5;232m"                 # Bold, Black (dark gray-like)
COLOR_SUBHEADING="\e[1;4;38;5;87m"            # Bold, Underlined, Cyan-ish

# Main Heading
echo -e "\n\n                                                  ${COLOR_HEADING}STIMULATION PERFORMANCE PROFILER${COLOR_RESET}\n"

# Directories and files
RTL_DIR="/home/himanshi-khanduja/PROJECT/Design"
TB_DIR="/home/himanshi-khanduja/PROJECT/Testbench"
LOG_DIR="/home/himanshi-khanduja/PROJECT/logs"
INSTANCE_FILE="$LOG_DIR/instances_report.txt"
SIGNALS_REPORT="$LOG_DIR/signals_report.txt"

> "$INSTANCE_FILE"
> "$SIGNALS_REPORT"

mkdir -p "$LOG_DIR"

# Initialize variables to track the most complex file
MAX_LOC=0
MAX_INPUT_COUNT=0
MAX_OUTPUT_COUNT=0
MAX_INOUT_COUNT=0
MAX_TOTAL_SIGNALS=0
MAX_INSTANCE_COUNT=0
MAX_STIMULUS_TIME=0
MAX_COMPLEX_FILE=""
MAX_FILE_METRICS=()

# Infinite loop for menu selection
while true; do
    echo -e "\n${COLOR_MENU}Select an option:${COLOR_RESET}"
    echo "1) Complexity of the code (LOC, Input and Output Signals)"
    echo "2) Stimulation Time"
    echo "3) Both Complexity and Stimulation Time"
    echo "4) Show Most Complex File"
    echo "q) Quit"
    read -p "$(echo -e "${COLOR_PROMPT}Enter your choice (1/2/3/4/q): ${COLOR_RESET}")" user_choice

    if [[ "$user_choice" == "q" ]]; then
        echo "Exiting the script."
        break
    fi

    # Loop through RTL files
    for rtl_file in "$RTL_DIR"/*.sv ; do
        rtl_name=$(basename "$rtl_file" .sv)
        tb_file="$TB_DIR/${rtl_name}_tb.sv"

        if [[ -f "$tb_file" ]] ; then
            START_TIME=$(date +%s%3N)

            RTL_LOC=$(egrep -ve '^\s*$' "$rtl_file" | wc -l)
            TB_LOC=$(egrep -ve '^\s*$' "$tb_file" | wc -l)

            awk -f /home/himanshi-khanduja/PROJECT/awk1.awk "$rtl_file" > "$SIGNALS_REPORT"

            INPUT_COUNT=$(awk -F: '/Inputs/ {gsub(/ /, "", $2); print $2}' "$SIGNALS_REPORT")
            OUTPUT_COUNT=$(awk -F: '/Outputs/ {gsub(/ /, "", $2); print $2}' "$SIGNALS_REPORT")
            INOUT_COUNT=$(awk -F: '/Inouts/ {gsub(/ /, "", $2); print $2}' "$SIGNALS_REPORT")
            TOTAL_SIGNALS=$(awk -F: '/Total/ {gsub(/ /, "", $2); print $2}' "$SIGNALS_REPORT")

            awk -f /home/himanshi-khanduja/PROJECT/awk2.awk "$rtl_file" > "$INSTANCE_FILE"
            INSTANCE_COUNT=$(awk -F: '/Total valid module instances/ {gsub(/ /, "", $2); print $2}' "$INSTANCE_FILE")
            if [[ -z "$INSTANCE_COUNT" ]]; then
                INSTANCE_COUNT=0
            fi

            iverilog -o "$LOG_DIR/${rtl_name}_sim.out" "$rtl_file" "$tb_file"

            if [[ $? -eq 0 ]] ; then
                vvp "$LOG_DIR/${rtl_name}_sim.out" > "$LOG_DIR/${rtl_name}_sim.log"
                END_TIME=$(date +%s%3N)
                STIMULUS_TIME=$((END_TIME - START_TIME))

                # Update if this file is the most complex
                if [[ $RTL_LOC -gt $MAX_LOC ]] || [[ $INPUT_COUNT -gt $MAX_INPUT_COUNT ]] || [[ $OUTPUT_COUNT -gt $MAX_OUTPUT_COUNT ]] || [[ $INOUT_COUNT -gt $MAX_INOUT_COUNT ]] || [[ $TOTAL_SIGNALS -gt $MAX_TOTAL_SIGNALS ]] || [[ $INSTANCE_COUNT -gt $MAX_INSTANCE_COUNT ]] || [[ $STIMULUS_TIME -gt $MAX_STIMULUS_TIME ]]; then
                    MAX_LOC=$RTL_LOC
                    MAX_INPUT_COUNT=$INPUT_COUNT
                    MAX_OUTPUT_COUNT=$OUTPUT_COUNT
                    MAX_INOUT_COUNT=$INOUT_COUNT
                    MAX_TOTAL_SIGNALS=$TOTAL_SIGNALS
                    MAX_INSTANCE_COUNT=$INSTANCE_COUNT
                    MAX_STIMULUS_TIME=$STIMULUS_TIME
                    MAX_COMPLEX_FILE=$rtl_name
                    MAX_FILE_METRICS=("$RTL_LOC" "$TB_LOC" "$INPUT_COUNT" "$OUTPUT_COUNT" "$INOUT_COUNT" "$TOTAL_SIGNALS" "$INSTANCE_COUNT" "$STIMULUS_TIME")
                fi

                case $user_choice in
                    1)
                        echo -e "\n\n                                                  ${COLOR_SUBHEADING}COMPLEXITY REPORT FOR $rtl_name${COLOR_RESET}\n"
                        echo " RTL LOC             : $RTL_LOC"
                        echo " TB LOC              : $TB_LOC"
                        echo " Input signals       : $INPUT_COUNT"
                        echo " Output signals      : $OUTPUT_COUNT"
                        echo " Inout signals       : $INOUT_COUNT"
                        echo " Total Signals       : $TOTAL_SIGNALS"
                        echo " Module Instances    : $INSTANCE_COUNT"
                        ;;
                    2)
                        echo -e "\n\n                                                  ${COLOR_SUBHEADING}STIMULATION REPORT FOR $rtl_name${COLOR_RESET}\n"
                        echo " Stimulation Time for $rtl_name is $STIMULUS_TIME ms"
                        ;;
                    3)
                        echo -e "\n\n                                                  ${COLOR_SUBHEADING}REPORT FOR $rtl_name${COLOR_RESET}\n"
                        echo " RTL LOC             : $RTL_LOC"
                        echo " TB LOC              : $TB_LOC"
                        echo " Input signals       : $INPUT_COUNT"
                        echo " Output signals      : $OUTPUT_COUNT"
                        echo " Inout signals       : $INOUT_COUNT"
                        echo " Total Signals       : $TOTAL_SIGNALS"
                        echo " Module Instances    : $INSTANCE_COUNT"
                        echo " Stimulation Time    : $STIMULUS_TIME ms"
                        ;;
                    4)
                        ;;
                    *)
                        echo "Invalid choice. Please enter 1, 2, 3, 4, or q to quit."
                        ;;
                esac
            else
                echo "Compilation failed for $rtl_name"
            fi
        else
            echo "No matching testbench found for $rtl_name"
        fi
    done

    if [[ "$user_choice" == "4" ]]; then
        echo -e "\n\n                                                  ${COLOR_SUBHEADING}MOST COMPLEX FILE: $MAX_COMPLEX_FILE${COLOR_RESET}\n"
        echo " RTL LOC             : ${MAX_FILE_METRICS[0]}"
        echo " TB LOC              : ${MAX_FILE_METRICS[1]}"
        echo " Input signals       : ${MAX_FILE_METRICS[2]}"
        echo " Output signals      : ${MAX_FILE_METRICS[3]}"
        echo " Inout signals       : ${MAX_FILE_METRICS[4]}"
        echo " Total Signals       : ${MAX_FILE_METRICS[5]}"
        echo " Module Instances    : ${MAX_FILE_METRICS[6]}"
        echo " Stimulation Time    : ${MAX_FILE_METRICS[7]} ms"

        echo -e "\n\n                                                  ${COLOR_SUBHEADING}EXPLANATION${COLOR_RESET}\n"
        echo "This file is considered the most complex because it has:"

        EXPLANATION_SHOWN=false

        if [[ ${MAX_FILE_METRICS[0]} -gt 20 ]]; then
            echo " - The highest Lines of Code (LOC) of ${MAX_FILE_METRICS[0]}."
            EXPLANATION_SHOWN=true
        fi
        if [[ ${MAX_FILE_METRICS[2]} -gt 5 ]]; then
            echo " - A high number of input signals (${MAX_FILE_METRICS[2]})."
            EXPLANATION_SHOWN=true
        fi
        if [[ ${MAX_FILE_METRICS[3]} -gt 3 ]]; then
            echo " - A high number of output signals (${MAX_FILE_METRICS[3]})."
            EXPLANATION_SHOWN=true
        fi
        if [[ ${MAX_FILE_METRICS[6]} -gt 2 ]]; then
            echo " - A high number of module instances (${MAX_FILE_METRICS[6]})."
            EXPLANATION_SHOWN=true
        fi
        if [[ ${MAX_FILE_METRICS[7]} -gt 100 ]]; then
            echo " - A long stimulation time of ${MAX_FILE_METRICS[7]} ms."
            EXPLANATION_SHOWN=true
        fi

        if [ "$EXPLANATION_SHOWN" = false ]; then
            echo " - Relatively higher metrics compared to other files even though all values are below the preset thresholds."
        fi
    fi
done
