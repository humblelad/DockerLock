#!/bin/bash

#SCRIPT_DIR="$(dirname "$(realpath "$0")")"

SCRIPT_DIR="$HOME/.docker-protect"
# echo $SCRIPT_DIR
PROTECTED_CONFIG="$SCRIPT_DIR/protect.json"
# Docker command and arguments
DOCKER_CMD=$(which docker)
COMMAND="$1"        # ('rm', 'rmi', 'volume', 'network', 'lock', 'unlock')
SUBCOMMAND="$2"     # (container/image/volume/network ID or subcommand like 'rm' for volumes/networks)
RESOURCE="$3"       # Resource ID (container/image/volume/network name)

# Function to check if a resource is protected
is_protected() {
    local resource_name="$1"
    local protected_list=($(jq -r ".protected_resources.$2[]" "$PROTECTED_CONFIG" 2>/dev/null))

    for item in "${protected_list[@]}"; do
        if [[ "$item" == "$resource_name" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to handle removal of multiple resources
remove_resources() {
    local type="$1"
    local success_list=()   # Non-protected resources
    local fail_list=()      # Protected resources

    # Loop through each resource to be removed
    shift 2  # Skip command and subcommand
    for resource in "$@"; do
        # Skip if the resource is empty or matches the command (like "rm")
        if [[ -z "$resource" || "$resource" == "$COMMAND" ]]; then
            continue
        fi

        if is_protected "$resource" "$type"; then
            fail_list+=("$resource")
        else
            success_list+=("$resource")
        fi
    done

    # If there are any protected resources, print an error message
    if [[ ${#fail_list[@]} -gt 0 ]]; then
        echo -e "\033[31mError: The following $type(s) are protected and cannot be removed: ${fail_list[*]}\033[0m"
    fi

    # If there are non-protected resources, proceed with removal
    if [[ ${#success_list[@]} -gt 0 ]]; then
        "$DOCKER_CMD" "$COMMAND" "${success_list[@]}"
    fi
}

# Lock (protect) multiple resources
lock_resource() {
    local type="$1"
    shift # Shift to get all resource IDs
    local resource_names=("$@")

    for name in "${resource_names[@]}"; do
        if is_protected "$name" "$type"; then
            echo "Error: $type '$name' is already locked."
        else
            # Append the resource to the JSON file
            jq --arg name "$name" ".protected_resources.$type += [\$name]" "$PROTECTED_CONFIG" > tmp.$$.json && mv tmp.$$.json "$PROTECTED_CONFIG"
            echo "$type '$name' is now locked."
        fi
    done
    exit 0
}

# Unlock (unprotect) multiple resources
unlock_resource() {
    local type="$1"
    shift # Shift to get all resource IDs
    local resource_names=("$@")

    for name in "${resource_names[@]}"; do
        if ! is_protected "$name" "$type"; then
            echo "Error: $type '$name' is not locked."
        else
            # Remove the resource from the JSON file
            jq --arg name "$name" ".protected_resources.$type |= map(select(. != \$name))" "$PROTECTED_CONFIG" > tmp.$$.json && mv tmp.$$.json "$PROTECTED_CONFIG"
            echo "$type '$name' is now unlocked."
        fi
    done
    exit 0
}

# Check for system prune command
if [[ "$COMMAND" == "system" && "$SUBCOMMAND" == "prune" ]]; then
    read -p "Warning: This will delete all stopped containers, networks not used by at least one container, all dangling images, and all build cache. Do you want to proceed? (y/n): " confirmation
    if [[ "$confirmation" == [yY] ]]; then
        # Proceed with the prune command
        "$DOCKER_CMD" "$COMMAND" "$SUBCOMMAND"
    else
        echo "Aborted: Docker system prune was not executed."
    fi
    exit 0
fi

# Handle lock (protect) commands
if [[ "$COMMAND" == "lock" ]]; then
    case "$SUBCOMMAND" in
        container)
            lock_resource "containers" "${@:3}"  # Pass all resource IDs starting from $3
            ;;
        image)
            lock_resource "images" "${@:3}"
            ;;
        volume)
            lock_resource "volumes" "${@:3}"
            ;;
        network)
            lock_resource "networks" "${@:3}"
            ;;
        *)
            echo "Usage: docker lock <container|image|volume|network> <name(s)>"
            exit 1
            ;;
    esac
elif [[ "$COMMAND" == "unlock" ]]; then
    case "$SUBCOMMAND" in
        container)
            unlock_resource "containers" "${@:3}"  # Pass all resource IDs starting from $3
            ;;
        image)
            unlock_resource "images" "${@:3}"
            ;;
        volume)
            unlock_resource "volumes" "${@:3}"
            ;;
        network)
            unlock_resource "networks" "${@:3}"
            ;;
        *)
            echo "Usage: docker unlock <container|image|volume|network> <name(s)>"
            exit 1
            ;;
    esac
fi

# Handle container removal
if [[ "$COMMAND" == "rm" ]]; then
    remove_resources "containers" "$@"
    exit 0
fi

# Handle image removal
if [[ "$COMMAND" == "rmi" ]]; then
    remove_resources "images" "$@"
    exit 0
fi

# Handle volume removal
if [[ "$COMMAND" == "volume" && "$SUBCOMMAND" == "rm" ]]; then
    remove_resources "volumes" "$@"
    exit 0
fi

# Handle network removal
if [[ "$COMMAND" == "network" && "$SUBCOMMAND" == "rm" ]]; then
    remove_resources "networks" "$@"
    exit 0
fi

# Handle system prune with a confirmation prompt
if [[ "$COMMAND" == "system" && "$SUBCOMMAND" == "prune" ]]; then
    echo -e "\033[33mWarning: This will remove all unused containers, images, volumes, and networks.\033[0m"
    read -p "Do you want to proceed? (y/n): " confirmation

    if [[ "$confirmation" == "y" || "$confirmation" == "Y" ]]; then
        echo "Proceeding with system prune..."
        "$DOCKER_CMD" "$COMMAND" "$SUBCOMMAND"
    else
        echo "System prune aborted."
        exit 0
    fi
fi

# Pass through non-protected commands like 'docker ps', 'docker logs', etc.
"$DOCKER_CMD" "$@"
