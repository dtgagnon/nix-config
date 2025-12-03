# llama.cpp with llama-swap Migration Guide

## Overview

This configuration provides llama.cpp as a drop-in replacement for Ollama, with dynamic model swapping for memory-efficient LLM serving on your RTX 4090.

## Key Features

- **OpenAI-compatible API**: Same endpoint as Ollama (`http://100.100.2.1:11434/v1`)
- **CUDA acceleration**: Full GPU offload for maximum performance
- **Dynamic model swapping**: Load/unload models on-demand to optimize VRAM usage
- **GPU passthrough integration**: Automatically stops when GPU is passed to Windows VM
- **Persistent storage**: Models survive reboots (stored in `/var/lib/llama-cpp/models`)

## Model Acquisition

### Recommended Quantization Levels

For your RTX 4090 (24GB VRAM), recommended quantizations:

- **Q5_K_M**: Best balance of quality and size (recommended)
- **Q6_K**: Higher quality, slightly larger
- **Q4_K_M**: Smaller, faster, slightly lower quality
- **Q8_0**: Near-original quality, largest size

### Downloading Models

#### 1. Mistral/Devstral 24B Equivalent

The closest equivalent to Devstral is Mistral 22B or Mistral-Nemo:

```bash
# Mistral-Nemo 12B (most recent, good for coding)
cd /var/lib/llama-cpp/models
sudo wget https://huggingface.co/bartowski/Mistral-Nemo-Instruct-2407-GGUF/resolve/main/Mistral-Nemo-Instruct-2407-Q5_K_M.gguf

# Or Mistral 22B v0.3 (larger, more capable)
sudo wget https://huggingface.co/bartowski/Mistral-22B-v0.3-GGUF/resolve/main/Mistral-22B-v0.3-Q5_K_M.gguf
```

#### 2. Google Gemma 2 27B

```bash
cd /var/lib/llama-cpp/models
sudo wget https://huggingface.co/bartowski/gemma-2-27b-it-GGUF/resolve/main/gemma-2-27b-it-Q5_K_M.gguf
```

#### 3. GPT-OSS 20B Equivalent

The closest open-source equivalent would be Qwen or DeepSeek:

```bash
# DeepSeek Coder 33B (best for coding)
cd /var/lib/llama-cpp/models
sudo wget https://huggingface.co/TheBloke/deepseek-coder-33B-instruct-GGUF/resolve/main/deepseek-coder-33b-instruct.Q5_K_M.gguf

# Or Qwen 2.5 32B Instruct (general purpose)
sudo wget https://huggingface.co/Qwen/Qwen2.5-32B-Instruct-GGUF/resolve/main/qwen2.5-32b-instruct-q5_k_m.gguf
```

#### 4. Qwen 2.5 14B (Extended Context)

```bash
cd /var/lib/llama-cpp/models
sudo wget https://huggingface.co/Qwen/Qwen2.5-14B-Instruct-GGUF/resolve/main/qwen2.5-14b-instruct-q5_k_m.gguf
```

### Alternative: Using HuggingFace Hub CLI

For easier browsing and downloading:

```bash
# Install huggingface-hub (temporary)
nix shell nixpkgs#python3Packages.huggingface-hub

# Download models
huggingface-cli download bartowski/gemma-2-27b-it-GGUF gemma-2-27b-it-Q5_K_M.gguf \
  --local-dir /var/lib/llama-cpp/models --local-dir-use-symlinks False
```

## Configuration

### Model Names in llama-cpp

Unlike Ollama's `model:tag` format, llama.cpp uses the actual GGUF filename. Update your applications:

**OpenCode CLI** (`~/.config/opencode/opencode.json`):
```json
{
  "models": {
    "gemma-2-27b-it-Q5_K_M.gguf": {
      "name": "gemma-2-27b-it-Q5_K_M.gguf",
      "tools": true,
      "reasoning": true
    }
  }
}
```

**Open WebUI**:
- Models are auto-detected from the `/var/lib/llama-cpp/models` directory
- Select them from the dropdown in the UI

### Context Size Configuration

The default context size is 4096 tokens. To increase for specific models:

```nix
# In DG-PC/default.nix
spirenix.services.llama-cpp = {
  enable = true;
  contextSize = 32768; # For extended context models
};
```

## Testing the Migration

### 1. Check Service Status

```bash
systemctl status llama-cpp.service
systemctl status llama-swap.service  # If enabled
```

### 2. Test API Endpoint

```bash
# List loaded models
curl http://100.100.2.1:11434/v1/models

# Test generation
curl http://100.100.2.1:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma-2-27b-it-Q5_K_M.gguf",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### 3. Test with Open WebUI

Navigate to `http://100.100.2.1:11435` and verify:
- Models appear in the dropdown
- Chat completion works
- Model switching works (if multiple models are downloaded)

### 4. Test GPU Passthrough Integration

```bash
# Start your Windows VM
# Check that llama-cpp service stops
systemctl status llama-cpp.service

# Stop the VM
# Check that llama-cpp service restarts
systemctl status llama-cpp.service
```

## Performance Tuning

### Optimize for Speed

```nix
spirenix.services.llama-cpp = {
  threads = 16;  # Match your CPU thread count
  contextSize = 4096;  # Lower context = faster
};
```

### Optimize for Quality

```nix
spirenix.services.llama-cpp = {
  contextSize = 32768;  # Extended context
  # Use Q6_K or Q8_0 quantized models
};
```

### Memory Management

The llama-swap service monitors VRAM usage and unloads models when threshold is reached:

```nix
spirenix.services.llama-cpp = {
  swapEnabled = true;
  swapThreshold = 0.8;  # Swap when 80% VRAM used
};
```

## Troubleshooting

### Models Not Loading

```bash
# Check file permissions
ls -la /var/lib/llama-cpp/models/

# Ensure files are readable
sudo chmod 644 /var/lib/llama-cpp/models/*.gguf
```

### CUDA Errors

```bash
# Verify NVIDIA drivers
nvidia-smi

# Check CUDA is available to the service
journalctl -u llama-cpp.service -f
```

### API Connection Issues

```bash
# Check firewall
sudo firewall-cmd --list-all

# Verify Tailscale interface
ip addr show tailscale0
```

## Reverting to Ollama

If you need to switch back:

1. Edit `systems/x86_64-linux/DG-PC/default.nix`:
   ```nix
   services = {
     ollama = enabled;
     # llama-cpp = enabled;
   };
   ```

2. Rebuild:
   ```bash
   nixos-rebuild switch --use-remote-sudo --flake .#DG-PC
   ```

All dependent services will automatically use Ollama again.

## Additional Resources

- [llama.cpp GitHub](https://github.com/ggerganov/llama.cpp)
- [GGUF Model Hub](https://huggingface.co/models?library=gguf)
- [Quantization Comparison](https://github.com/ggerganov/llama.cpp/discussions/2094)
- [bartowski's Quantized Models](https://huggingface.co/bartowski) - High-quality quantizations
