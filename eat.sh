#!/bin/bash

# Symbols
GREEN_TICK="\033[0;32m✔\033[0m"
RED_CROSS="\033[0;31m✖\033[0m"

# Output function
function print_result {
    if [ $1 -eq 0 ]; then
        echo -e "$2 $GREEN_TICK"
    else
        echo -e "$2 $RED_CROSS"
    fi
}

echo "=============================="
echo "   EKS Access Debugging Script   "
echo "=============================="

# 1. Check if kubectl is installed
echo "Checking if kubectl is installed..."
if command -v kubectl >/dev/null 2>&1; then
    print_result 0 "kubectl is installed"
else
    print_result 1 "kubectl is not installed"
    echo "Please install kubectl to proceed."
    exit 1
fi

# 2. Check if kubeconfig file exists
echo "Checking if kubeconfig file exists..."
KUBECONFIG=${KUBECONFIG:-$HOME/.kube/config}

if [ -f "$KUBECONFIG" ]; then
    print_result 0 "kubeconfig file found at $KUBECONFIG"
    # 3. Check if kubectl has config for Kubernetes clusters
    echo "Checking if kubectl has config for Kubernetes clusters..."
    CLUSTERS=$(kubectl config get-clusters --kubeconfig="$KUBECONFIG" 2>/dev/null | tail -n +2)
    if [ -n "$CLUSTERS" ]; then
        print_result 0 "kubectl config has clusters configured"
        # 4. List all the clusters kubectl has access to
        echo "Listing clusters in kubectl config..."
        echo "$CLUSTERS"
    else
        print_result 1 "No clusters found in kubectl config"
    fi
else
    print_result 1 "kubeconfig file not found at $KUBECONFIG"
    echo "Please ensure kubeconfig is set up correctly."
    # Optionally, you can exit here if kubeconfig is essential
    # exit 1
fi

# 5. Check if AWS CLI is installed
echo "Checking if AWS CLI is installed..."
if command -v aws >/dev/null 2>&1; then
    print_result 0 "AWS CLI is installed"
else
    print_result 1 "AWS CLI is not installed"
    echo "Please install AWS CLI to proceed."
    exit 1
fi

# 6. Check which AWS identity is being used
echo "Checking AWS identity..."
IDENTITY=$(aws sts get-caller-identity --output text 2>/dev/null)
if [ $? -eq 0 ]; then
    print_result 0 "AWS identity retrieved"
    echo "AWS Identity:"
    echo "$IDENTITY"
else
    print_result 1 "Failed to retrieve AWS identity"
    echo "Please configure your AWS credentials."
    exit 1
fi

# 7. Validate AWS credentials
echo "Validating AWS credentials..."
if aws sts get-caller-identity >/dev/null 2>&1; then
    print_result 0 "AWS credentials are valid"
else
    print_result 1 "AWS credentials are invalid or expired"
    echo "Please refresh or configure your AWS credentials."
    exit 1
fi

# 8. Determine AWS Region to use
echo "Determining AWS Region to use..."

# Function to extract regions from kubeconfig
function get_regions_from_kubeconfig {
    REGIONS=()
    CLUSTER_SERVERS=$(kubectl config view -o jsonpath='{.clusters[*].cluster.server}')
    for SERVER in $CLUSTER_SERVERS; do
        if [[ "$SERVER" =~ https://.*\.([a-z0-9-]+)\.eks\.amazonaws\.com ]]; then
            REGION="${BASH_REMATCH[1]}"
            REGIONS+=("$REGION")
        fi
    done
    # Remove duplicates
    REGIONS=($(echo "${REGIONS[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
}

# Get regions from kubeconfig if available
if [ -f "$KUBECONFIG" ]; then
    get_regions_from_kubeconfig
fi

if [ ${#REGIONS[@]} -gt 0 ]; then
    echo "Found the following AWS regions from kubeconfig:"
    for i in "${!REGIONS[@]}"; do
        printf "%d) %s\n" $((i+1)) "${REGIONS[$i]}"
    done
    read -p "Please select a region by number: " REGION_SELECTION
    SELECTED_REGION="${REGIONS[$((REGION_SELECTION-1))]}"
else
    echo "No AWS regions found in kubeconfig."
    echo "Please select an AWS region from the list:"
    # Hardcoded list of regions
    AVAILABLE_REGIONS=(us-east-1 us-east-2 us-west-1 us-west-2 \
eu-west-1 eu-west-2 eu-west-3 eu-central-1 \
ap-southeast-1 ap-southeast-2 ap-northeast-1 \
ap-northeast-2 ap-south-1 sa-east-1 ca-central-1)
    for i in "${!AVAILABLE_REGIONS[@]}"; do
        printf "%d) %s\n" $((i+1)) "${AVAILABLE_REGIONS[$i]}"
    done
    read -p "Please select a region by number: " REGION_SELECTION
    SELECTED_REGION="${AVAILABLE_REGIONS[$((REGION_SELECTION-1))]}"
fi

if [ -n "$SELECTED_REGION" ]; then
    print_result 0 "Using AWS region: $SELECTED_REGION"
    export AWS_REGION="$SELECTED_REGION"
else
    print_result 1 "No region selected."
    exit 1
fi

# 9. Attempt to list EKS clusters in the selected region
echo "Attempting to list EKS clusters in region $AWS_REGION..."
EKS_CLUSTERS=$(aws eks list-clusters --region "$AWS_REGION" --output text 2>/dev/null)
if [ $? -eq 0 ]; then
    print_result 0 "EKS clusters retrieved"
    if [ -n "$EKS_CLUSTERS" ]; then
        echo "EKS Clusters in $AWS_REGION:"
        echo "$EKS_CLUSTERS"
    else
        echo "No EKS clusters found in $AWS_REGION."
    fi
else
    print_result 1 "Failed to retrieve EKS clusters"
    echo "Please check your AWS permissions for EKS."
fi

# 10. Check kubectl context and connectivity if kubeconfig is available
if [ -f "$KUBECONFIG" ]; then
    echo "Checking current kubectl context..."
    CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$CURRENT_CONTEXT" ]; then
        print_result 0 "Current context is $CURRENT_CONTEXT"

        # Check connectivity to current cluster
        echo "Checking connectivity to current cluster..."
        kubectl cluster-info >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            print_result 0 "Connected to cluster $CURRENT_CONTEXT"
        else
            print_result 1 "Cannot connect to cluster $CURRENT_CONTEXT"
            echo "Please ensure network connectivity and proper permissions."
        fi
    else
        print_result 1 "No current context set in kubectl"
    fi

    # Optionally, prompt user to switch context if multiple contexts are available
    CONTEXTS=$(kubectl config get-contexts -o name 2>/dev/null)
    CONTEXT_COUNT=$(echo "$CONTEXTS" | wc -l)

    if [ $CONTEXT_COUNT -gt 1 ]; then
        echo "Multiple kubectl contexts detected:"
        echo "$CONTEXTS"
        read -p "Would you like to switch context? (y/n): " SWITCH_CONTEXT
        if [ "$SWITCH_CONTEXT" == "y" ]; then
            echo "Enter the name of the context to switch to:"
            read CONTEXT_NAME
            kubectl config use-context "$CONTEXT_NAME"
            if [ $? -eq 0 ]; then
                print_result 0 "Switched to context $CONTEXT_NAME"
            else
                print_result 1 "Failed to switch context"
            fi
        fi
    fi
else
    echo "Skipping kubectl context checks because kubeconfig file is not available."
fi

echo "=============================="
echo "  EKS Access Debugging Complete  "
echo "=============================="
