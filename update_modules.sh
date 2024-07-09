#!/bin/bash

# Set the base directory
BASE_DIR=$(pwd)
MODULES_DIR="${BASE_DIR}/modules"
FILES_DIR="${BASE_DIR}/files"
OUTPUT_YAML="${BASE_DIR}/mcc-modules.yaml"
GITHUB_REPO_URL="https://github.com/reddydodda/mcc-modules"

# GitHub repository URL
# You can set this as an environment variable or pass it as an argument
if [ -z "$1" ]; then
    if [ -z "$GITHUB_REPO_URL" ]; then
        echo "Error: GitHub repository URL not provided. Please set GITHUB_REPO_URL environment variable or provide it as an argument."
        exit 1
    else
        GITHUB_REPO_URL="$GITHUB_REPO_URL"
    fi
else
    GITHUB_REPO_URL="$1"
fi

# Ensure the files directory exists
mkdir -p "${FILES_DIR}"

# Initialize the YAML file
cat > "${OUTPUT_YAML}" << EOF
apiVersion: kaas.mirantis.com/v1alpha1
kind: HostOSConfigurationModules
metadata:
  name: mcc-modules
spec:
  modules:
EOF

# Function to process each module
process_module() {
    local module_dir="$1"
    local module_name=$(basename "${module_dir}")
    
    # Extract version from metadata.yaml
    local version=$(awk '/version:/ {print $2}' "${module_dir}/metadata.yaml" | tr -d '"')
    
    if [ -z "${version}" ]; then
        echo "Error: Could not extract version for ${module_name}"
        return 1
    fi
    
    # Create tarball
    local tarball_name="${module_name}-${version}.tar.gz"
    local temp_dir=$(mktemp -d)
    local module_version_dir="${module_name}-${version}"

    # Copy files to a directory with the desired name
    cp -a "${module_dir}" "${temp_dir}/${module_version_dir}"

    # Create tarball from the temp directory
    tar -czf "${FILES_DIR}/${tarball_name}" -C "${temp_dir}" "${module_version_dir}"

    # Clean up
    rm -rf "${temp_dir}"

    # Generate SHA256 sum
    local sha256sum=$(shasum -a 256 "${FILES_DIR}/${tarball_name}" | awk '{print $1}')

    # Construct GitHub URL for the tarball
    local github_url="${GITHUB_REPO_URL}/raw/main/files/${tarball_name}"

    # Append to YAML file
    cat >> "${OUTPUT_YAML}" << EOF
    - name: ${module_name}
      version: ${version}
      sha256sum: ${sha256sum}
      url: ${github_url}
EOF
    
    echo "Processed ${module_name} version ${version}"
}

# Process each module
for module_dir in "${MODULES_DIR}"/*; do
    if [ -d "${module_dir}" ]; then
        process_module "${module_dir}"
    fi
done

echo "HostOSConfigurationModules YAML created at ${OUTPUT_YAML}"
