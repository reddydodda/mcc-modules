#!/bin/bash

# Set the base directory
BASE_DIR=$(pwd)
MODULES_DIR="${BASE_DIR}/modules"
FILES_DIR="${BASE_DIR}/files"
OUTPUT_YAML="${BASE_DIR}/mcc-modules.yaml"

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
    tar -czf "${FILES_DIR}/${tarball_name}" -C "${MODULES_DIR}" "${module_name}"
    
    # Generate SHA256 sum
    local sha256sum=$(shasum -a 256 "${FILES_DIR}/${tarball_name}" | awk '{print $1}')
    
    # Append to YAML file
    cat >> "${OUTPUT_YAML}" << EOF
    - name: ${module_name}
      version: ${version}
      sha256sum: ${sha256sum}
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
