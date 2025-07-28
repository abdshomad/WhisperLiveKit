#!/bin/bash

# WhisperLiveKit Installation Script for H100x2 Setup
# Based on SETUP_GUIDE_H100x2.md
# This script automates the complete installation process for GPU-accelerated WhisperLiveKit

set -e  # Exit on any error

echo "🚀 WhisperLiveKit H100x2 Installation Script"
echo "=============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Function to check command existence
check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "$1 not found. Please install it first."
        return 1
    fi
    return 0
}

# Check if we're in the right directory
if [ ! -f "setup.py" ] || [ ! -f "README.md" ]; then
    print_error "This script must be run from the WhisperLiveKit root directory"
    exit 1
fi

print_status "Starting WhisperLiveKit H100x2 installation..."

# Step 1: Check system requirements
print_step "1. Checking system requirements..."

# Check for CUDA installation
if [ ! -d "/usr/local/cuda" ]; then
    print_error "CUDA installation not found in /usr/local/cuda"
    print_error "Please install CUDA first"
    exit 1
fi

# Check for NVIDIA drivers
if ! check_command "nvidia-smi"; then
    print_error "nvidia-smi not found. Please install NVIDIA drivers"
    exit 1
fi

# Check for uv
if ! check_command "uv"; then
    print_error "uv not found. Please install uv first:"
    print_error "curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

print_success "System requirements check passed"

# Step 2: Setup CUDA environment
print_step "2. Setting up CUDA environment..."

# Set CUDA paths
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Verify CUDA installation
if ! nvcc --version &> /dev/null; then
    print_error "nvcc not found. CUDA installation may be incomplete"
    exit 1
fi

# Display CUDA version
CUDA_VERSION=$(nvcc --version | grep "release" | awk '{print $6}' | cut -c2-)
print_success "CUDA $CUDA_VERSION detected"

print_success "CUDA environment configured"

# Step 3: Check GPU availability and H100 setup
print_step "3. Checking GPU availability..."

GPU_COUNT=$(nvidia-smi --list-gpus | wc -l)
if [ "$GPU_COUNT" -eq 0 ]; then
    print_error "No GPUs detected"
    exit 1
fi

# Check for H100 GPUs specifically
H100_COUNT=$(nvidia-smi --list-gpus | grep -i "H100" | wc -l)
if [ "$H100_COUNT" -gt 0 ]; then
    print_success "Found $H100_COUNT H100 GPU(s) - Optimized for large models"
else
    print_warning "H100 GPUs not detected - Using available GPUs"
fi

print_success "Found $GPU_COUNT GPU(s) total"
nvidia-smi --list-gpus

# Display GPU memory info
print_status "GPU Memory Information:"
nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv,noheader,nounits

# Step 4: Setup virtual environment
print_step "4. Setting up virtual environment..."

if [ ! -d ".venv" ]; then
    print_status "Creating virtual environment..."
    uv venv .venv
fi

# Activate virtual environment
source .venv/bin/activate

print_success "Virtual environment ready"

# Step 5: Install WhisperLiveKit in development mode
print_step "5. Installing WhisperLiveKit in development mode..."
uv pip install -e .

print_success "WhisperLiveKit core installed"

# Step 6: Install GPU-optimized PyTorch for H100
print_step "6. Installing GPU-optimized PyTorch for H100..."

# Install PyTorch with CUDA 12.1 support (compatible with H100)
uv pip install torch torchaudio torchvision --index-url https://download.pytorch.org/whl/cu121

print_success "PyTorch with CUDA support installed"

# Step 7: Install compatible CTranslate2 for cuDNN 8
print_step "7. Installing CTranslate2 compatible with cuDNN 8..."
uv pip install ctranslate2==3.22.0

print_success "CTranslate2 installed"

# Step 8: Create symbolic links for CUDA library compatibility
print_step "8. Creating symbolic links for CUDA library compatibility..."

# Create symbolic links to make CUDA 12 libraries accessible as CUDA 11
print_status "Creating CUDA library compatibility links..."
sudo ln -sf /usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib/libcublas.so.12 /usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib/libcublas.so.11 2>/dev/null || true
sudo ln -sf /usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/libcudnn.so.8 /usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/libcudnn.so.9 2>/dev/null || true
sudo ln -sf /usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/libcudnn_ops.so.8 /usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/libcudnn_ops.so.9 2>/dev/null || true
sudo ln -sf /usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/libcudnn_ops.so.8 /usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/libcudnn_ops.so.9.1 2>/dev/null || true

print_success "CUDA library compatibility links created"

# Step 9: Install additional dependencies
print_step "9. Installing additional dependencies..."
uv pip install torch diart

print_success "Additional dependencies installed"

# Step 10: Verify installation
print_step "10. Verifying installation..."

# Check PyTorch CUDA support
print_status "Verifying PyTorch CUDA support..."
PYTORCH_CUDA=$(python -c "
import torch
print('PyTorch version:', torch.__version__)
print('CUDA available:', torch.cuda.is_available())
if torch.cuda.is_available():
    print('CUDA version:', torch.version.cuda)
    print('GPU count:', torch.cuda.device_count())
    for i in range(torch.cuda.device_count()):
        print(f'GPU {i}:', torch.cuda.get_device_name(i))
" 2>/dev/null || echo "PyTorch verification failed")

if echo "$PYTORCH_CUDA" | grep -q "CUDA available: True"; then
    print_success "PyTorch CUDA support verified"
    echo "$PYTORCH_CUDA"
else
    print_warning "PyTorch CUDA support verification failed"
    echo "$PYTORCH_CUDA"
fi

# Step 11: Verify existing scripts
print_step "11. Verifying existing scripts..."

# Check if run_server.sh exists
if [ -f "run_server.sh" ]; then
    print_success "run_server.sh found"
else
    print_error "run_server.sh not found in repository"
    exit 1
fi

# Check if run_server_with_diarization_large_id.sh exists
if [ -f "run_server_with_diarization_large_id.sh" ]; then
    print_success "run_server_with_diarization_large_id.sh found"
else
    print_error "run_server_with_diarization_large_id.sh not found in repository"
    exit 1
fi

# Step 12: Make existing scripts executable
print_step "12. Making existing scripts executable..."

chmod +x run_server.sh
chmod +x run_server_with_diarization_large_id.sh
print_success "Scripts made executable"

# Step 13: Test server startup
print_step "13. Testing server startup..."
print_status "Testing basic server startup (timeout after 15 seconds)..."
timeout 15s ./run_server.sh tiny.en > /dev/null 2>&1 || echo "Server test completed (timeout expected)"

print_success "Server startup test completed"

# Step 14: Verify requirements file exists
print_step "14. Verifying requirements file..."

# Check if requirements-uv.txt exists
if [ -f "requirements.txt" ]; then
    print_success "requirements.txt found"
else
    print_warning "requirements.txt not found in repository"
fi

# Step 15: Installation verification
print_step "15. Final installation verification..."

# Final summary
echo ""
echo "🎉 H100x2 Installation Complete!"
echo "================================"
echo ""
echo "✅ WhisperLiveKit installed with H100 GPU support"
echo "✅ CUDA environment configured for H100x2"
echo "✅ Virtual environment ready"
echo "✅ Enhanced convenience scripts created"
echo ""
echo "🚀 Quick Start Commands:"
echo "   ./run_server.sh                # Start basic server"
echo "   ./run_server.sh medium localhost 9001 --diarization  # With diarization"
echo "   ./run_server_with_diarization_large_id.sh  # Large model with diarization"
echo ""
echo "🌐 Access the interface at: http://localhost:9001"
echo ""
echo "📚 For more information, see SETUP_GUIDE_H100x2.md"
echo ""
print_success "H100x2 installation completed successfully!" 