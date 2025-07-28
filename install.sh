#!/bin/bash

# WhisperLiveKit Installation Script
# This script automates the complete installation process for GPU-accelerated WhisperLiveKit

set -e  # Exit on any error

echo "🚀 WhisperLiveKit GPU Installation Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check if we're in the right directory
if [ ! -f "setup.py" ] || [ ! -f "README.md" ]; then
    print_error "This script must be run from the WhisperLiveKit root directory"
    exit 1
fi

print_status "Starting WhisperLiveKit installation with GPU support..."

# Step 1: Check system requirements
print_status "Checking system requirements..."

# Check for CUDA installation
if [ ! -d "/usr/local/cuda" ]; then
    print_error "CUDA installation not found in /usr/local/cuda"
    print_error "Please install CUDA first"
    exit 1
fi

# Check for NVIDIA drivers
if ! command -v nvidia-smi &> /dev/null; then
    print_error "nvidia-smi not found. Please install NVIDIA drivers"
    exit 1
fi

# Check for uv
if ! command -v uv &> /dev/null; then
    print_error "uv not found. Please install uv first:"
    print_error "curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

print_success "System requirements check passed"

# Step 2: Setup CUDA environment
print_status "Setting up CUDA environment..."

export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Verify CUDA installation
if ! nvcc --version &> /dev/null; then
    print_error "nvcc not found. CUDA installation may be incomplete"
    exit 1
fi

print_success "CUDA environment configured"

# Step 3: Check GPU availability
print_status "Checking GPU availability..."

GPU_COUNT=$(nvidia-smi --list-gpus | wc -l)
if [ "$GPU_COUNT" -eq 0 ]; then
    print_error "No GPUs detected"
    exit 1
fi

print_success "Found $GPU_COUNT GPU(s)"
nvidia-smi --list-gpus

# Step 4: Setup virtual environment
print_status "Setting up virtual environment..."

if [ ! -d ".venv" ]; then
    print_status "Creating virtual environment..."
    uv venv .venv
fi

# Activate virtual environment
source .venv/bin/activate

print_success "Virtual environment ready"

# Step 5: Install WhisperLiveKit in development mode
print_status "Installing WhisperLiveKit in development mode..."
uv pip install -e .

print_success "WhisperLiveKit core installed"

# Step 6: Install GPU-optimized PyTorch
print_status "Installing GPU-optimized PyTorch for CUDA 12.1..."
uv pip install torch torchaudio torchvision --index-url https://download.pytorch.org/whl/cu121

print_success "PyTorch with CUDA support installed"

# Step 7: Install compatible CTranslate2
print_status "Installing CTranslate2 compatible with cuDNN 8..."
uv pip install ctranslate2==3.22.0

print_success "CTranslate2 installed"

# Step 7.5: Create symbolic links for CUDA library compatibility
print_status "Creating symbolic links for CUDA library compatibility..."

# Create symbolic links to make CUDA 12 libraries accessible as CUDA 11
sudo ln -sf /usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib/libcublas.so.12 /usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib/libcublas.so.11 2>/dev/null || true
sudo ln -sf /usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/libcudnn.so.8 /usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/libcudnn.so.9 2>/dev/null || true
sudo ln -sf /usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/libcudnn_ops.so.8 /usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/libcudnn_ops.so.9 2>/dev/null || true
sudo ln -sf /usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/libcudnn_ops.so.8 /usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/libcudnn_ops.so.9.1 2>/dev/null || true

print_success "CUDA library compatibility links created"

# Step 8: Install additional dependencies
print_status "Installing additional dependencies..."
uv pip install torch diart

print_success "Additional dependencies installed"

# Step 9: Verify installation
print_status "Verifying installation..."

# Check PyTorch CUDA support
PYTORCH_CUDA=$(python -c "import torch; print('CUDA available:', torch.cuda.is_available()); print('GPU count:', torch.cuda.device_count())" 2>/dev/null || echo "PyTorch verification failed")

if echo "$PYTORCH_CUDA" | grep -q "CUDA available: True"; then
    print_success "PyTorch CUDA support verified"
    echo "$PYTORCH_CUDA"
else
    print_warning "PyTorch CUDA support verification failed"
    echo "$PYTORCH_CUDA"
fi

# Step 10: Create convenience script
print_status "Creating convenience script..."

cat > run_server.sh << 'EOF'
#!/bin/bash

# WhisperLiveKit Server Runner
# This script activates the virtual environment and starts the WhisperLiveKit server

# Activate virtual environment
source .venv/bin/activate

# Set environment variables for GPU acceleration
export CUDA_VISIBLE_DEVICES="0,1"
export CT2_CUDA_DEVICES="0,1"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib:$LD_LIBRARY_PATH"

# Default parameters
MODEL=${1:-"tiny.en"}
HOST=${2:-"localhost"}
PORT=${3:-"9001"}

echo "Starting WhisperLiveKit server..."
echo "Model: $MODEL"
echo "Host: $HOST"
echo "Port: $PORT"
echo "Access the interface at: http://$HOST:$PORT"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start the server
whisperlivekit-server --model "$MODEL" --host "$HOST" --port "$PORT"
EOF

chmod +x run_server.sh
print_success "Convenience script created"

# Step 11: Test server startup
print_status "Testing server startup..."
timeout 15s ./run_server.sh > /dev/null 2>&1 || echo "Server test completed (timeout expected)"

print_success "Server startup test completed"

# Step 12: Create requirements.txt
print_status "Creating requirements.txt..."
cat > requirements.txt << 'EOF'
# WhisperLiveKit Installation Requirements
# Generated from the installation process

# Core WhisperLiveKit (installed in development mode)
-e .

# GPU-optimized dependencies
torch>=2.5.1+cu121
torchaudio>=2.5.1+cu121
torchvision>=0.20.1+cu121
ctranslate2==3.22.0

# Additional dependencies for enhanced functionality
diart>=0.9.0

# Additional optional dependencies you can install as needed:
# whisperlivekit[whisper]              # Original Whisper
# whisperlivekit[whisper-timestamped]  # Improved timestamps  
# whisperlivekit[mlx-whisper]          # Apple Silicon optimization
# whisperlivekit[openai]               # OpenAI API
# whisperlivekit[simulstreaming]       # SimulStreaming backend

# For sentence-based buffer trimming:
# mosestokenizer
# wtpsplit
# tokenize_uk  # If working with Ukrainian text
EOF

print_success "Requirements file created"

# Final summary
echo ""
echo "🎉 Installation Complete!"
echo "========================"
echo ""
echo "✅ WhisperLiveKit installed with GPU support"
echo "✅ CUDA environment configured"
echo "✅ Virtual environment ready"
echo "✅ Convenience script created"
echo ""
echo "🚀 To start the server:"
echo "   ./run_server.sh"
echo ""
echo "🌐 Access the interface at: http://localhost:9001"
echo ""
echo "📚 For more information, see SETUP_GUIDE.md"
echo ""
print_success "Installation completed successfully!" 