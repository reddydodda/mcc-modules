# MCC Host OS Configuration Modules

This repository contains Host OS Configuration Modules for Mirantis Container Cloud (MCC). These modules allow you to customize the host OS configuration in your MCC clusters.

## Usage

### 1. Running update_modules.sh

The `update_modules.sh` script creates tarballs for each module, generates SHA256 sums, and updates the `mcc-modules.yaml` file. To run the script:

1. Ensure you have execute permissions:
```shell
chmod +x update_modules.sh
```

2. Run the script with your GitHub repository URL:
```shell
./update_modules.sh https://github.com/yourusername/yourrepo
```
Alternatively, you can set the `GITHUB_REPO_URL` environment variable:

```shell
export GITHUB_REPO_URL="https://github.com/yourusername/yourrepo"
./update_modules.sh
```

This will generate the `mcc-modules.yaml` file and create tarballs in the `files/` directory.

### 2. Creating HostOSConfigurationModules in MCC Cluster

To create the HostOSConfigurationModules resource in your MCC cluster:

1. Ensure you have `kubectl` configured to access your MCC cluster.

2. Apply the `mcc-modules.yaml` file:
```shell
kubectl apply -f mcc-modules.yaml
```

This will create a HostOSConfigurationModules resource in your cluster, making the modules available for use.

### 3. Creating a HostOSConfiguration

To use a module in your cluster, create a HostOSConfiguration resource. An example is provided in the `examples/` directory.

1. Review and modify the example as needed:
```shell
vi examples/host-multipath-configuration.yaml
```

2. Apply the HostOSConfiguration:
```shell
kubectl apply -f examples/host-os-configuration.yaml
```

This will create a HostOSConfiguration resource in your cluster, which will apply the specified module configuration to the selected machines.

## Example HostOSConfiguration

Here's an example of how to use the multipath module in a HostOSConfiguration:

```yaml
apiVersion: kaas.mirantis.com/v1alpha1
kind: HostOSConfiguration
metadata:
name: multipath-config
namespace: default
spec:
configs:
- module: multipath
 moduleVersion: 1.0.0
 values:
   install_multipath: true
   multipath_conf:
     defaults:
       user_friendly_names: "yes"
       find_multipaths: "yes"
     devices:
       - vendor: "DellEMC"
         product: "PowerStore"
         path_selector: "queue-length 0"
         path_grouping_policy: "group_by_prio"
         # ... other device-specific settings ...
machineSelector:
 matchLabels:
   mcc-node: "true"
```

Modify the values according to your specific multipath configuration requirements.

## Updating Modules

This repository uses a git pre-commit hook to automatically update modules when changes are made. Here's the process for updating modules:

1. Update the module files in the appropriate directory under `modules/`.
2. Increment the version number in the module's `metadata.yaml` file.

When you commit your changes, the pre-commit hook will automatically:

3. Run the `update_modules.sh` script to generate new tarballs and update the `mcc-modules.yaml` file.
4. Add the updated `mcc-modules.yaml` and new tarball files to your commit.

After the commit:

5. Push your changes to the GitHub repository.
6. Apply the updated `mcc-modules.yaml` to your MCC cluster:
```shell
kubectl apply -f mcc-modules.yaml
```

### Setting up the pre-commit hook

If you haven't set up the pre-commit hook yet, follow these steps:

1. Create a file named `pre-commit` in the `.git/hooks/` directory of your repository.
2. Add the following content to the file:

```bash
#!/bin/bash
./update_modules.sh
git add mcc-modules.yaml files/*.tar.gz
```
3. Make the hook executable:
```shell
chmod +x .git/hooks/pre-commit
```

   

