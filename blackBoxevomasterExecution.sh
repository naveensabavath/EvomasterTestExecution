#!/bin/bash

# Set repository URL and branch
#REPO_URL="git@github.com:naveensabavath/EvomasterTestExecution.git"
#BRANCH="main"

# Set the base CDN URL
BASE_URL="https://cdn.aidtaas.com"

# Set destination directory
DEST_DIR="evomasterGeneratedTestCases"
mkdir -p "$DEST_DIR"  # Ensure the directory exists

# Define output file
OUTPUT_FILE="urls_debug.txt"


faultsUrl="$faults_tests_cdnUrl"
successUrl="$successes_tests_cdnUrl"
othersUrl="$others_tests_cdnUrl"


# Write the variable values to the file
echo "Faults URL: $faultsUrl" > "$OUTPUT_FILE"
echo "Success URL: $successUrl" >> "$OUTPUT_FILE"
echo "Others URL: $othersUrl" >> "$OUTPUT_FILE"


# Print values for debugging
echo "faultsUrl: $faultsUrl"
echo "successUrl: $successUrl"
echo "othersUrl: $othersUrl"

# List of relative file URLs (without base URL)
URLS=("$faultsUrl" "$successUrl" "$othersUrl")  # Adding all three

# Change to the destination directory
cd "$DEST_DIR" || exit

# Loop to download each file dynamically
for RELATIVE_URL in "${URLS[@]}"; do
    if [[ -n "$RELATIVE_URL" ]]; then  # Ensure URL is not empty
        FULL_URL="${BASE_URL}${RELATIVE_URL}"  # Prepend base URL
        FILE_NAME=$(basename "$RELATIVE_URL")  # Extract filename
        wget -O "$FILE_NAME" "$FULL_URL"  # Download file

        # Check if file exists and is not empty
        if [[ -s "$FILE_NAME" ]]; then
            echo "Downloaded: $FILE_NAME"
        else
            echo "Failed to download: $FILE_NAME"
        fi
    fi
done

cd ..

echo "All files processed."


sleep 120

FILES_DEST_DIR="src/test/java"


# Build the project with Maven (without tests)
echo "Building the project with Maven..."
mvn clean install -DskipTests || echo "Maven build failed but continuing..."

# Copy all generated test files to the Git repo's test directory
echo "Copying test files..."
mkdir -p "$FILES_DEST_DIR"
cp -r "$DEST_DIR"/* "$FILES_DEST_DIR"



sleep 120

# Run tests and capture output
echo "Running tests..."
mvn clean test | tee test_output.log || true  

# Step 1: Extract required lines (Running & Test Summary)
#echo "================ Extracted Test Results ================"
#grep -E "^(Running|Tests run:)" test_output.log
#echo "=========================================================="

# Step 1: Extract required lines (Running & Test Summary)
echo "================ Extracted Test Results ================"
awk '
    /^Running/ {print "\nFile Name: " $2; inside_test=1}
    /^Tests run:/ {
        if (inside_test) {print "Stats: " $0; inside_test=0}
        else {print "\nTotal Summary:\n"$0}
    }
' test_output.log
echo "=========================================================="



# Remove test files after execution (NO GitHub Commit)
#echo "Deleting test files..."
#rm -rf "$DEST_DIR"/*

echo "Script execution completed!"

