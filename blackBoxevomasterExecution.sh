#!/bin/bash

# Set repository URL and branch
#REPO_URL="git@github.com:naveensabavath/EvomasterTestExecution.git"
#BRANCH="main"

# Set destination directory
DEST_DIR="evomasterGeneratedTestCases"
mkdir -p "$DEST_DIR"

# Login API details
LOGIN_URL="https://ig.aidtaas.com/mobius-iam-service/v1.0/login"
USERNAME="aidtaas@gaiansolutions.com"
PASSWORD="Gaian@123"
PRODUCT_ID="c2255be4-ddf6-449e-a1e0-b4f7f9a2b636"

# Define output file
OUTPUT_FILE="urls_debug.txt"

# Fetch access token
echo "Fetching access token..."
AUTH_RESPONSE=$(curl --silent --location "$LOGIN_URL" \
    --header 'Content-Type: application/json' \
    --data-raw "{
        \"userName\": \"$USERNAME\",
        \"password\": \"$PASSWORD\",
        \"productId\": \"$PRODUCT_ID\",
        \"requestType\": \"TENANT\"
    }")

ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | grep -oP '(?<="accessToken":")[^"]+')

# Validate if token was extracted
if [[ -z "$ACCESS_TOKEN" ]]; then
    echo "Error: Failed to retrieve access token."
    exit 1
fi

echo "Access token retrieved successfully."


FAULTS_URL=$faults_tests_url
SUCCESS_URL=$successes_tests_url
OTHERS_URL=$others_tests_url


# Write the variable values to the file
echo "Faults URL: $FAULTS_URL" > "$OUTPUT_FILE"
echo "Success URL: $SUCCESS_URL" >> "$OUTPUT_FILE"
echo "Others URL: $OTHERS_URL" >> "$OUTPUT_FILE"


# Print values for debugging
echo "faultsUrl: $FAULTS_URL"
echo "successUrl: $SUCCESS_URL"
echo "othersUrl: $OTHERS_URL"

# List of relative file URLs (without base URL)
URLS=("$FAULTS_URL" "$SUCCESS_URL" "$OTHERS_URL")  # Adding all three
NAMES=("Evomaster_faults_Test.java" "Evomaster_success_Test.java" "Evomaster_others_Test.java")

# Change to the destination directory
cd "$DEST_DIR" || exit

# Loop through URLs
for i in "${!URLS[@]}"; do
    URL="${URLS[i]}"
    FILE_NAME="${NAMES[i]}"

    if [[ -n "$URL" ]]; then
        echo "Downloading: $FILE_NAME from $URL"

        curl --silent --location "$URL" \
            --header "Authorization: Bearer $ACCESS_TOKEN" \
            --output "$FILE_NAME"

        # Validate if file was downloaded
        if [[ -s "$FILE_NAME" ]]; then
            echo "Downloaded: $FILE_NAME"
        else
            echo "Failed to download: $FILE_NAME"
            rm -f "$FILE_NAME"  # Remove empty file
        fi
    else
        echo "Skipping: No URL provided for $FILE_NAME"
    fi
done

echo "Download process completed."


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

