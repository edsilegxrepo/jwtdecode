#!/bin/bash
# Version: 0.0.9 (20250826)

# --- Configuration ---
VERSION_FILE="version.txt"
OUTPUT_DIR="." # Output to current directory
APP_NAME="" # Application name (now mandatory)
CUSTOM_LDFLAGS="" # Custom ldflags to append
CLEAN_BUILD=false # Flag for clean build
VERBOSE=true # Default to verbose output
QUIET=false # Default to not quiet

# --- Helper function for conditional echo ---
log_message() {
    if [ "$QUIET" = true ]; then
        return
    fi
    if [ "$VERBOSE" = true ]; then
        echo "$@"
    fi
}

# --- Function to print help message ---
print_help() {
    echo "Usage: $0 [options] --app-name <name>"
    echo "Builds the Go application, runs validation, and manages versioning."
    echo ""
    echo "Options:"
    echo "  --os <target_os>      Specify target OS (e.g., windows, linux). Default: builds for both."
    echo "  --arch <target_arch>  Specify target architecture (e.g., amd64, arm64). Default: amd64."
    echo "  --app-name <name>     (Mandatory) Specify the application executable name."
    echo "  --ldflags <flags>     Custom ldflags to append to the build command."
    echo "  --version-file <file> Specify the version file name. Default: version.txt."
    echo "  --output-dir <dir>    Specify the output directory for executables. Default: current directory."
    echo "  --clean               Remove output directory contents before building."
    echo "  --verbose             Enable verbose output (default)."
    echo "  --quiet               Suppress all output except errors."
    echo "  -h, --help            Display this help message."
    echo ""
    echo "Examples:"
    echo "  $0 --app-name myapp"                                     # Build for Windows and Linux (amd64)
    echo "  $0 --app-name myapp --os linux --arch arm64"             # Build for Linux ARM64
    echo "  $0 --app-name myapp --output-dir bin"   # Build with custom name and output directory
    echo "  $0 --app-name myapp --ldflags \"-X main.build=123\""     # Build with custom ldflags
    echo "  $0 --app-name myapp --clean"                             # Clean build
    echo "  $0 --app-name myapp --quiet"                             # Run quietly
    exit 0
}

# --- Function to increment version ---
increment_version() {
    local version=$1
    IFS='.' read -r -a parts <<< "$version"
    local major=${parts[0]}
    local minor=${parts[1]}
    local patch=${parts[2]}

    # Increment patch version
    patch=$((patch + 1))

    # Handle rollovers
    if (( patch > 9 )); then
        patch=0
        minor=$((minor + 1))
        if (( minor > 9 )); then
            minor=0
            major=$((major + 1))
        fi
    fi
    echo "$major.$minor.$patch"
}

# --- Function to to run validation tools ---
run_validation() {
    log_message "Running go fmt..."
    go fmt ./... || { echo "go fmt failed! Command: go fmt ./..."; exit 1; }

    log_message "Running go vet..."
    go vet ./... || { echo "go vet failed! Command: go vet ./..."; exit 1; }

    log_message "Running golangci-lint..."
    golangci-lint run ./... || { echo "golangci-lint failed! Command: golangci-lint run ./..."; exit 1; }

    log_message "Running govulncheck..."
    govulncheck ./... || { echo "govulncheck failed! Command: govulncheck ./..."; exit 1; }
}

# --- Build Function ---
build_target() {
    local os_target=$1
    local arch_target=$2
    local output_name="${APP_NAME}"

    if [ "$os_target" == "windows" ]; then
        output_name="${output_name}.exe"
    fi

    local ldflags="-s -w -X main.version=${NEW_VERSION}-${DATE_STAMP}"
    if [ -n "${CUSTOM_LDFLAGS}" ]; then
        ldflags="${ldflags} ${CUSTOM_LDFLAGS}"
    fi

    local build_cmd="go build -ldflags \"${ldflags}\" -buildvcs=false -o \"${OUTPUT_DIR}/${output_name}\""

    log_message "Building ${output_name} (Version: ${NEW_VERSION}-${DATE_STAMP}) for ${os_target}/${arch_target}"
    log_message "Executing build command: CGO_ENABLED=0 GOOS=${os_target} GOARCH=${arch_target} bash -c \"${build_cmd}\""
    # Execute the build command using bash -c to handle quoting consistently
    CGO_ENABLED=0 GOOS=${os_target} GOARCH=${arch_target} bash -c "${build_cmd}"

    if [ $? -ne 0 ]; then
        echo "Build failed for ${os_target}/${arch_target}! Command: ${build_cmd}"
        exit 1
    fi
    log_message "Build successful for ${os_target}/${arch_target}!"
}

# --- Function to check for required commands ---
check_dependencies() {
    local missing_deps=()
    for cmd in go golangci-lint govulncheck; do
        if ! command -v "$cmd" &> /dev/null;
        then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "Error: Missing required commands: ${missing_deps[*]}"
        echo "Please install them and ensure they are in your PATH."
        exit 1
    fi
}

# --- Main Logic ---
# Check dependencies first
check_dependencies

# Parse Arguments
GOOS_TARGET=""
GOARCH_TARGET=""

while (( "$#" )); do
    case "$1" in
        --os)
            GOOS_TARGET="$2"
            shift 2
            ;; 
        --arch)
            GOARCH_TARGET="$2"
            shift 2
            ;; 
        --app-name)
            APP_NAME="$2"
            shift 2
            ;; 
        --ldflags)
            CUSTOM_LDFLAGS="$2"
            shift 2
            ;; 
        --version-file)
            VERSION_FILE="$2"
            shift 2
            ;; 
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;; 
        --clean)
            CLEAN_BUILD=true
            shift 1
            ;; 
        --verbose)
            VERBOSE=true
            QUIET=false
            shift 1
            ;; 
        --quiet)
            QUIET=true
            VERBOSE=false
            shift 1
            ;; 
        -h|--help)
            print_help
            ;; 
        *)
            echo "Error: Unknown argument: $1"
            print_help
            exit 1
            ;; 
    esac
done

# Validate mandatory arguments
if [ -z "$APP_NAME" ]; then
    echo "Error: --app-name is mandatory."
    print_help
    exit 1
fi

# Handle clean build option
if [ "$CLEAN_BUILD" = true ]; then
    log_message "Cleaning output directory: ${OUTPUT_DIR}"
    rm -rf "${OUTPUT_DIR:?}"/* || { echo "Error: Failed to clean output directory!"; exit 1; } # SC2115: Use "${var:?}" to ensure this never expands to /* . 
    mkdir -p "${OUTPUT_DIR}" || { echo "Error: Failed to recreate output directory!"; exit 1; }
fi

# Get Current Version
if [ ! -f "$VERSION_FILE" ]; then
    echo "0.0.1" > "$VERSION_FILE"
fi
CURRENT_VERSION=$(cat "$VERSION_FILE")

# Increment Version
NEW_VERSION=$(increment_version "$CURRENT_VERSION")

# Generate Date Stamp (YYYYMMDD)
DATE_STAMP=$(TZ='US/Central' date +%Y%m%d)

# Run validation before any build
run_validation

# Build based on arguments or default to both
if [ -z "$GOOS_TARGET" ] && [ -z "$GOARCH_TARGET" ]; then
    log_message "No specific OS/ARCH provided. Building for both Windows and Linux."
    build_target "windows" "amd64"
    build_target "linux" "amd64"
else
    build_target "$GOOS_TARGET" "$GOARCH_TARGET"
fi

# Update Version File
echo "${NEW_VERSION}" > "${VERSION_FILE}"

log_message "Version updated to ${NEW_VERSION} in ${VERSION_FILE}"
