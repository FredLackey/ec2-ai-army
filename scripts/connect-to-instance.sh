#!/bin/bash

# Script to connect to an EC2 instance from the AI Army deployment
# Usage: ./connect-to-instance.sh -i <instance_number> [-p <path_to_iac_directory>]

set -e

# Default values
INSTANCE_NUMBER=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
IAC_DIR="$REPO_ROOT/iac-instances"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_usage() {
    echo "Usage: $0 -i <instance_number> [-p <path_to_iac_directory>]"
    echo ""
    echo "Options:"
    echo "  -i, --instance <number>    Instance number to connect to (1, 2, 3, etc.)"
    echo "  -p, --path <path>          Path to iac-instances directory (default: iac-instances)"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -i 1                    Connect to ai-army-1"
    echo "  $0 -i 2 -p ../iac-instances   Connect to ai-army-2 using custom path"
}

print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_info() {
    echo -e "${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--instance)
                INSTANCE_NUMBER="$2"
                shift 2
                ;;
            -p|--path)
                IAC_DIR="$2"
                shift 2
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$INSTANCE_NUMBER" ]]; then
        print_error "Instance number is required"
        print_usage
        exit 1
    fi

    # Validate instance number is numeric
    if ! [[ "$INSTANCE_NUMBER" =~ ^[0-9]+$ ]]; then
        print_error "Instance number must be a positive integer"
        exit 1
    fi
}

get_instance_ip() {
    local outputs_file="$IAC_DIR/outputs.json"
    local instance_name="ai-army-$INSTANCE_NUMBER"

    # Check if outputs.json exists
    if [[ ! -f "$outputs_file" ]]; then
        print_error "outputs.json file not found at: $outputs_file"
        print_info "Make sure you have run 'terraform apply' in the iac-instances directory"
        exit 1
    fi

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        print_error "jq is required but not installed. Please install jq first."
        exit 1
    fi

    # Get the public IP from outputs.json
    local public_ip
    public_ip=$(jq -r ".instances[\"$instance_name\"].public_ip" "$outputs_file" 2>/dev/null)

    if [[ "$public_ip" == "null" || -z "$public_ip" ]]; then
        print_error "Instance '$instance_name' not found in deployment"
        print_info "Available instances:"
        jq -r '.instances | keys[]' "$outputs_file" 2>/dev/null || echo "  No instances found"
        exit 1
    fi

    echo "$public_ip"
}

connect_to_instance() {
    local public_ip="$1"
    local instance_name="ai-army-$INSTANCE_NUMBER"
    local private_key_file="$IAC_DIR/ai-army-shared.pem"

    # Check if private key file exists
    if [[ ! -f "$private_key_file" ]]; then
        print_error "Private key file not found: $private_key_file"
        exit 1
    fi

    print_info "Connecting to $instance_name ($public_ip)..."

    # Set correct permissions on private key
    chmod 600 "$private_key_file" 2>/dev/null || true

    # Connect to instance
    ssh -i "$private_key_file" -o StrictHostKeyChecking=no ubuntu@"$public_ip"
}

main() {
    parse_arguments "$@"

    local public_ip
    public_ip=$(get_instance_ip)

    connect_to_instance "$public_ip"
}

main "$@"