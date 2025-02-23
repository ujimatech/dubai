#!/bin/bash

# Name of the output file
output_file="combined.tf"

# Remove the output file if it exists
rm -f "$output_file"

# Add a header to the combined file
echo "# Combined Terraform Configuration - Generated $(date)" > "$output_file"
echo "" >> "$output_file"

# Find all .tf files and combine them
for file in $(find . -name "*.tf" ! -name "$output_file"); do
    echo "# Source: $file" >> "$output_file"
    echo "" >> "$output_file"
    cat "$file" >> "$output_file"
    echo "" >> "$output_file"
    echo "" >> "$output_file"
done

echo "All .tf files have been combined into $output_file"