# On-Device LLM Research Report for Atlas Tracker

> Compiled February 5, 2026 | 5 parallel research agents | Models, Performance, Fine-Tuning, Integration, Licensing

---

## Executive Summary

**WINNER: Ministral 3B (December 2025)** -- Apache 2.0 license, MMLU 70.7, 256K context, ~2.0 GB at Q4_K_M. Highest benchmark scores among true 3B models with zero licensing restrictions.

**RUNNER-UP: Phi-4 Mini 3.8B** -- MIT license, MMLU 67.3, 128K context, ~2.2 GB at Q4_K_M. Most permissive license possible (MIT). Slightly larger at 3.8B but exceptional quality.

**BEST LIGHTWEIGHT: Qwen 3 1.7B** -- Apache 2.0, ~60 MMLU, 32K context, ~1.5 GB at Q4_K_M. Best quality-per-GB ratio for universal iPhone 12+ compatibility.

**Integration: llama.cpp** via Swift wrapper (LLM.swift or llama-cpp-swift SPM package). Download-on-demand model delivery. Tiered model selection based on device RAM at runtime.

---

## Table of Contents

1. [Requirements](#requirements)
2. [Model Comparison](#model-comparison)
3. [Winner Analysis](#winner-analysis)
4. [iOS Performance Data](#ios-performance-data)
5. [Device Compatibility Matrix](#device-compatibility-matrix)
6. [Integration Architecture](#integration-architecture)
7. [Fine-Tuning Pipeline](#fine-tuning-pipeline)
8. [Licensing Analysis](#licensing-analysis)
9. [Deployment Strategy](#deployment-strategy)
10. [Sources](#sources)

---

## Requirements

| Requirement | Constraint |
|-------------|-----------|
| Open source | Yes, with commercial license |
| Cost | 100% free -- zero royalties, fees, or revenue sharing |
| Target devices | iPhone 12+ (A14 chip, 4 GB RAM minimum) |
| Censorship | Uncensored / no guardrails (abliterated variants available) |
| Fine-tunable | LoRA/QLoRA support for domain specialization |
| Model size | Quantizable to ~1.5-2 GB (Q4_K_M GGUF) |
| Framework | llama.cpp or equivalent, integrated via SwiftUI |

---

## Model Comparison

### Tier 1: Top Recommendations

| Rank | Model | Params | License | MMLU | Context | Q4_K_M Size | RAM Usage | Min iPhone |
|------|-------|--------|---------|------|---------|-------------|-----------|------------|
| **1** | **Ministral 3B** | 3.0B | Apache 2.0 | 70.7 | 256K | ~2.0 GB | ~2.5 GB | 13 Pro (6 GB) |
| **2** | **Phi-4 Mini** | 3.8B | MIT | 67.3 | 128K | ~2.2 GB | ~2.7 GB | 13 Pro (6 GB) |
| **3** | **Llama 3.2 3B** | 3.2B | Llama Community | 63.4 | 128K | ~2.0 GB | ~2.5 GB | 13 Pro (6 GB) |

### Tier 2: Strong Alternatives

| Rank | Model | Params | License | MMLU | Context | Q4_K_M Size | RAM Usage | Min iPhone |
|------|-------|--------|---------|------|---------|-------------|-----------|------------|
| 4 | Qwen 3 4B | 4.0B | Apache 2.0 | ~65 | 40K | ~2.5 GB | ~3.0 GB | 14 Pro (6 GB) |
| 5 | Gemma 3n E2B | 5B (2B active) | Gemma ToU | TBD | 32K | ~2.0 GB | ~2.5 GB | 13 Pro (6 GB) |
| 6 | Qwen 3 1.7B | 1.7B | Apache 2.0 | ~60 | 32K | ~1.5 GB | ~1.8 GB | 12 (4 GB) |

### Tier 3: Lightweight / Universal

| Rank | Model | Params | License | MMLU | Context | Q4_K_M Size | RAM Usage | Min iPhone |
|------|-------|--------|---------|------|---------|-------------|-----------|------------|
| 7 | Llama 3.2 1B | 1.2B | Llama Community | 49.3 | 128K | ~0.8 GB | ~1.2 GB | 12 (4 GB) |
| 8 | Qwen 3 0.6B | 0.6B | Apache 2.0 | 52.8 | 32K | <0.5 GB | <1 GB | 12 (4 GB) |
| 9 | Gemma 3 1B | 1.0B | Gemma ToU | ~42 | 32K | ~0.7 GB | ~1 GB | 12 (4 GB) |

### Not Recommended (Outclassed)

| Model | Reason |
|-------|--------|
| Gemma 2 2B | Superseded by Gemma 3n E2B. Only 8K context. |
| Phi-3 / Phi-3.5 Mini | Superseded by Phi-4 Mini on every metric. |
| Qwen 2.5 0.5B/1.5B | Superseded by Qwen 3 equivalents. |
| Qwen 2.5 3B | Non-commercial license. Blocked. |
| TinyLlama 1.1B | 2K context, ~25 MMLU. Completely outclassed. |
| StableLM 2 1.6B | No abliterated variant, 4K context, restrictive license. |
| SmolLM2 1.7B | Only 8K context. Outclassed by Qwen 3 1.7B. |

---

## Winner Analysis

### Winner: Ministral 3B (December 2025)

**Why it wins:**
- **Highest MMLU (70.7)** among all true 3B models -- a significant margin over Llama 3.2 3B (63.4) and Phi-4 Mini (67.3 at 3.8B)
- **256K context window** -- largest in this class, double Llama/Phi at 128K
- **Apache 2.0 license** -- zero restrictions, zero attribution requirements, zero thresholds
- **Abliterated variants available** from huihui-ai (both instruct and reasoning)
- **December 2025 release** -- latest architecture with state-of-the-art training

**Trade-offs:**
- Very new, less community testing than Llama 3.2
- Requires 6 GB+ RAM devices (iPhone 13 Pro and newer)

**Abliterated variant:** [huihui-ai/Huihui-Ministral-3-3B-Instruct-2512-abliterated](https://huggingface.co/huihui-ai/Huihui-Ministral-3-3B-Instruct-2512-abliterated)

### Runner-Up: Phi-4 Mini 3.8B

**Why it's runner-up:**
- **MIT license** -- the most permissive license in existence, even simpler than Apache 2.0
- **67.3 MMLU** -- second highest, with both instruct and reasoning abliterated variants
- **128K context** -- ample for any on-device use case
- **Microsoft backing** -- active development, well-documented

**Trade-offs:**
- 3.8B parameters (slightly above the 3B target)
- ~2.2 GB at Q4_K_M (marginally larger than true 3B models)

**Abliterated variants:**
- Instruct: [huihui-ai/Phi-4-mini-instruct-abliterated](https://huggingface.co/huihui-ai/Phi-4-mini-instruct-abliterated)
- Reasoning: [huihui-ai/Phi-4-mini-reasoning-abliterated](https://huggingface.co/huihui-ai/Phi-4-mini-reasoning-abliterated)

---

## iOS Performance Data

### Token Generation Speed (Q4_K_M)

| Chip | Device | 1B Model (tok/s) | 3B Model (tok/s) |
|------|--------|-------------------|-------------------|
| A14 | iPhone 12 | 35-39 | ~8.5 (not viable) |
| A15 | iPhone 13 | ~39 | ~15-17 |
| A15 | iPhone 13 Pro | ~39 | ~15-17 |
| A16 | iPhone 14 Pro | ~54 | ~23 |
| A17 Pro | iPhone 15 Pro | ~57 | ~25+ |

### User Experience Thresholds

| Speed | Experience |
|-------|-----------|
| < 3 t/s | Unusable |
| 3-8 t/s | Tolerable for non-conversational use |
| 8-15 t/s | Acceptable, like a slow typist |
| 15-25 t/s | Good, responsive and natural |
| 25-40 t/s | Very good, feels near-instant |
| 40+ t/s | Excellent |

### Key Performance Insights

1. **Q4 quantization nearly doubles speed** vs Q8/F16 on every chip
2. **Memory bandwidth is the bottleneck** for token generation (each token reads entire model weights)
3. **A14 is viable for 1B only** -- 3B models are too slow (~8 t/s) and risk jetsam termination on 4 GB devices
4. **Thermal throttling drops performance 30-50%** after 2-5 minutes of continuous inference
5. **Battery impact is negligible** for a health app -- a few seconds of inference per response, well under 1% battery per session

### App-Available RAM (After iOS System Overhead)

| Device Category | Total RAM | Default App Limit | With `increased-memory-limit` |
|-----------------|-----------|-------------------|-------------------------------|
| iPhone 12/13 (non-Pro) | 4 GB | ~2.0-2.1 GB | ~2.5-2.8 GB |
| iPhone 12-14 Pro, 15 | 6 GB | ~2.8-3.0 GB | ~3.5-4.0 GB |
| iPhone 15 Pro+ | 8 GB | ~3.5-4.0 GB | ~5.0-6.0 GB |

---

## Device Compatibility Matrix

| Device | RAM | Chip | Recommended Model | Gen Speed (Q4) | Context Limit |
|--------|-----|------|-------------------|----------------|---------------|
| iPhone 12 | 4 GB | A14 | 1B Q4_K_M | ~35-39 t/s | 2048 |
| iPhone 12 Pro | 6 GB | A14 | 1B Q4_K_M (3B possible but slow) | ~35-39 t/s | 2048-4096 |
| iPhone 13 | 4 GB | A15 | 1B Q4_K_M | ~39 t/s | 2048 |
| iPhone 13 Pro | 6 GB | A15 | 3B Q4_K_M | ~15-17 t/s | 2048-4096 |
| iPhone 14 | 6 GB | A15 | 3B Q4_K_M | ~15-17 t/s | 2048-4096 |
| iPhone 14 Pro | 6 GB | A16 | 3B Q4_K_M | ~23 t/s | 4096 |
| iPhone 15 | 6 GB | A16 | 3B Q4_K_M | ~23 t/s | 4096 |
| iPhone 15 Pro | 8 GB | A17 Pro | 3B Q5_K_M | ~25+ t/s | 4096-8192 |

### Runtime Model Selection

```swift
let totalRAM = ProcessInfo.processInfo.physicalMemory
let ramGB = Double(totalRAM) / (1024 * 1024 * 1024)

if ramGB >= 6.0 {
    // 6GB+: Load 3B model (Ministral 3B or Phi-4 Mini)
    loadModel("ministral-3b-instruct-q4_k_m.gguf")
    setContextLength(2048)  // 4096 on 8GB devices
} else {
    // 4GB: Load 1B model (Llama 3.2 1B or Qwen 3 0.6B)
    loadModel("llama-3.2-1b-instruct-q4_k_m.gguf")
    setContextLength(2048)
}
```

---

## Integration Architecture

### Recommended Stack

| Layer | Choice | Reason |
|-------|--------|--------|
| Inference Engine | llama.cpp | Production-proven, largest ecosystem, Metal GPU |
| Swift Wrapper | LLM.swift or llama-cpp-swift | SPM package, AsyncStream, simple API |
| Model Format | GGUF (Q4_K_M) | Best quality-to-size ratio |
| Model Delivery | Download on first launch | Keeps app binary under 200 MB |
| Storage | Documents directory | NSFileProtectionComplete compatible |

### Framework Comparison

| Framework | Device Support | Performance | Build Complexity | Verdict |
|-----------|---------------|-------------|-----------------|---------|
| **llama.cpp** | iPhone 12+ (4 GB) | Best documented | Medium (C++ interop) | **Recommended** |
| MLX Swift | iPhone 15 Pro+ (8 GB) | 10-20% faster | Medium | Too restrictive |
| CoreML | iPhone 8+ | Variable | High (conversion fragile) | Maintenance-heavy |
| Apple Foundation Models | iPhone 15 Pro+ (iOS 26) | System-optimized | Low | Future option (2026-2027) |
| MLC LLM | iPhone 12+ | Competitive | High (TVM toolchain) | Overkill |

### Recommended File Structure

```
AtlasTracker/
├── Services/
│   ├── LLMService.swift              -- llama.cpp wrapper (load, infer, unload)
│   ├── ModelDownloadManager.swift     -- Download GGUF from HuggingFace
│   └── MemoryPressureMonitor.swift    -- Respond to memory warnings
├── ViewModels/
│   └── ChatViewModel.swift            -- @Observable, manages chat state
├── Views/
│   └── AI/
│       ├── AIChatView.swift           -- Main chat interface
│       ├── MessageBubble.swift        -- Individual message bubble
│       └── ModelLoadingView.swift     -- Loading/download progress
└── Resources/
    └── (GGUF file NOT bundled -- downloaded on first use)
```

### Key Integration Patterns

**Model Loading:**
```swift
import llama_cpp_swift

final class LLMService {
    private var model: Model?

    func loadModel(from url: URL) async throws {
        let loaded = try Model(modelPath: url.path)
        await MainActor.run { self.model = loaded }
    }
}
```

**Streaming Inference:**
```swift
func generate(prompt: String) -> AsyncThrowingStream<String, Error> {
    guard let model = self.model else { /* error */ }
    return model.infer(prompt: prompt, maxTokens: 512)
}
```

**Memory Warning Handler:**
```swift
.onReceive(NotificationCenter.default.publisher(
    for: UIApplication.didReceiveMemoryWarningNotification
)) { _ in
    viewModel.handleMemoryWarning()  // Unload model if not generating
}
```

### App Store Compliance

- On-device inference with zero network calls = fully compliant with Apple Guideline 5.1.2(i)
- Privacy label: "Data Not Collected" (matches Atlas Tracker's existing posture)
- App bundle limit: 4 GB (model not bundled, downloaded separately)
- No guardrail requirements for custom models (unlike Apple Foundation Models)

---

## Fine-Tuning Pipeline

### Recommended Approach

| Setting | Value |
|---------|-------|
| Method | QLoRA (4-bit base, 16-bit adapters) |
| Tool | Unsloth |
| Platform | Google Colab Free (T4, 15 GB) or RunPod RTX 4090 ($0.34/hr) |
| Dataset Format | ChatML JSONL |
| Dataset Size | 5,000-10,000 examples recommended |
| Training Time | 2-4 hours for 3B model on Colab T4 |
| Cost | $0 (Colab Free) or ~$0.50-$1.50 (RunPod) |

### VRAM Requirements

| Model | Full Fine-Tune | LoRA | QLoRA |
|-------|---------------|------|-------|
| 1B | ~12-16 GB | ~4-6 GB | ~2-4 GB |
| 3B | ~48 GB | ~10-14 GB | ~5-8 GB |

### LoRA Configuration (Recommended)

```python
model = FastLanguageModel.get_peft_model(
    model,
    r=16,                    # Rank 16 -- sweet spot for 1B-3B
    lora_alpha=32,           # Alpha = 2x rank
    lora_dropout=0.05,
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj",
                    "gate_proj", "up_proj", "down_proj"],
    bias="none",
    use_gradient_checkpointing="unsloth"
)
```

### Dataset Format (ChatML)

```json
{"messages": [
  {"role": "system", "content": "You are a supplement and health advisor."},
  {"role": "user", "content": "What is creatine monohydrate good for?"},
  {"role": "assistant", "content": "Creatine monohydrate is one of the most researched..."}
]}
```

### Complete Pipeline: Fine-Tune to iOS

```
1. Prepare dataset (ChatML JSONL)
   ↓
2. Fine-tune with Unsloth (QLoRA, 4-bit)
   ↓
3. Merge LoRA adapters into base model
   ↓
4. Save as FP16 SafeTensors (canonical checkpoint)
   ↓
5. Convert to GGUF (convert_hf_to_gguf.py)
   ↓
6. Generate importance matrix (imatrix -- recommended for small models)
   ↓
7. Quantize to Q4_K_M or Q5_K_M with imatrix
   ↓
8. Validate quality (perplexity + manual testing)
   ↓
9. Test in llama.cpp CLI or Ollama
   ↓
10. Bundle GGUF into iOS app via llama.cpp Swift binding
```

### Quantization Recommendations

| iPhone | RAM | Best Quant (3B) | Best Quant (1B) |
|--------|-----|-----------------|-----------------|
| 15 Pro (8 GB) | 8 GB | Q5_K_M (~1.9 GB) | Q6_K (~0.75 GB) |
| 15 / 14 Pro (6 GB) | 6 GB | Q4_K_M (~1.6 GB) | Q5_K_M (~0.65 GB) |
| 12 / 13 (4 GB) | 4 GB | Too tight -- use 1B | Q4_K_M (~0.55 GB) |

**Always use importance matrix (imatrix) quantization** for Q5_K_M and below on 1B-3B models. Small models lose proportionally more quality from quantization than large models.

### Abliteration vs Fine-Tuning for Uncensoring

For 1B-3B models, **fine-tuning on a dataset without refusal patterns is more reliable** than post-hoc abliteration. Abliteration was designed for 7B+ models where the refusal direction is more cleanly separable. On small models, abliteration carries higher risk of degrading output quality. However, pre-abliterated community variants (from huihui-ai, mlabonne, failspy) have been tested and work well.

---

## Licensing Analysis

### License Safety Tiers

#### Tier 1: SAFEST (Zero Restrictions)

| License | Models | Commercial | Revenue Limit | User Limit | In-App Attribution | Kill Switch |
|---------|--------|-----------|--------------|------------|-------------------|-------------|
| **MIT** | Phi-3/3.5/4 Mini | YES | NONE | NONE | NO | NO |
| **Apache 2.0** | Ministral 3B, Qwen 2.5 (0.5B/1.5B), Qwen 3 (all), SmolLM, TinyLlama | YES | NONE | NONE | NO | NO |

#### Tier 2: LOW RISK (Free but has conditions)

| License | Models | Commercial | Revenue Limit | User Limit | In-App Attribution | Kill Switch |
|---------|--------|-----------|--------------|------------|-------------------|-------------|
| **Llama Community** | Llama 3.2 1B/3B | YES | NONE | 700M MAU | YES ("Built with Llama") | NO |

#### Tier 3: MEDIUM RISK

| License | Models | Commercial | Revenue Limit | User Limit | In-App Attribution | Kill Switch |
|---------|--------|-----------|--------------|------------|-------------------|-------------|
| **Gemma ToU** | Gemma 2/3 | YES | NONE | NONE | NO | **YES** (remote restriction clause) |

#### BLOCKED (Cannot use in paid App Store app)

| License | Models | Reason |
|---------|--------|--------|
| Qwen Research | Qwen 2.5 3B | Non-commercial only |
| Stability Community | StableLM 2 | Free only below $1M revenue |

### Key Licensing Insights

- **Abliterated model derivatives inherit the base model's license.** An abliterated Phi-4 Mini remains MIT. An abliterated Llama 3.2 still requires "Built with Llama" attribution.
- **Community creators cannot relicense base model weights.** If a HuggingFace repo claims "Apache 2.0" for an abliterated Llama model, that claim is legally invalid for the base weights.
- **On-device inference is a compliance advantage.** Zero network calls = no third-party AI data sharing disclosure required under Apple Guideline 5.1.2(i).

---

## Deployment Strategy

### Recommended Approach: Tiered Model Selection

1. **Ship app without model weights** (binary stays under 200 MB for cellular download)
2. **On first launch**, detect device RAM and download appropriate model:
   - 6 GB+ RAM: Ministral 3B Q4_K_M (~2.0 GB)
   - 4 GB RAM: Qwen 3 1.7B Q4_K_M (~1.5 GB) or Llama 3.2 1B Q4_K_M (~0.8 GB)
3. **Store in Documents directory** with `isExcludedFromBackup = true` and NSFileProtectionComplete
4. **Require `increased-memory-limit` entitlement** in Xcode project
5. **Handle memory warnings** -- unload model when not actively generating

### Thermal Mitigation

- Cap generation at 256-512 tokens per response
- Add 2-3 second cooldown between consecutive requests
- Use bursty inference pattern (generate, idle, generate)
- For Atlas Tracker, most responses (supplement info, dosage guidance) should be under 200 tokens

### Cost Summary

| Item | Cost |
|------|------|
| Model license | $0 (Apache 2.0 / MIT) |
| Fine-tuning | $0-$1.50 (Colab Free or RunPod) |
| Model hosting | $0 (HuggingFace Hub) |
| Ongoing fees | $0 |
| **Total** | **$0-$1.50** |

---

## Abliteration Providers on HuggingFace

| Provider | Specialty | Notable Models |
|----------|-----------|---------------|
| **huihui-ai** | Largest abliteration collection | Ministral 3B, Phi-4, Llama 3.2, Qwen 3, Gemma 3n |
| **mlabonne** | Invented the popularized technique | Gemma 3 1B, Llama 3.1 8B |
| **failspy** | Created the original abliteration method | Phi-3 models |
| **DavidAU** | HERETIC abliteration variant | Qwen 2.5/3 small models |
| **bartowski** | GGUF quantization specialist | Pre-quantized abliterated models |

---

## Final Recommendation

### For Atlas Tracker Specifically

| Scenario | Model | License | Size | Speed |
|----------|-------|---------|------|-------|
| **Primary (6 GB+ devices)** | Ministral 3B abliterated | Apache 2.0 | ~2.0 GB | 15-25 t/s |
| **Fallback (4 GB devices)** | Qwen 3 1.7B abliterated | Apache 2.0 | ~1.5 GB | 30-40 t/s |
| **Alternative primary** | Phi-4 Mini abliterated | MIT | ~2.2 GB | 15-23 t/s |

**The deciding factor:** If you target only 6 GB+ devices, go with Ministral 3B. If you need universal iPhone 12+ support, implement the tiered approach with Qwen 3 1.7B as the lightweight model.

### Next Steps

1. Add `llama-cpp-swift` (or `LLM.swift`) to Xcode project via SPM
2. Build `ModelDownloadManager` to fetch GGUF from HuggingFace on first launch
3. Build `LLMService` wrapping llama.cpp with AsyncStream inference
4. Build `ChatViewModel` (@Observable) for conversation state management
5. Build `AIChatView` with loading state, chat interface, and memory pressure handling
6. Test on physical iPhone (Simulator does not reflect Metal GPU performance or memory constraints)
7. (Optional) Fine-tune on health/supplement domain data using Unsloth + QLoRA

---

## Sources

### Performance
- [llama.cpp A-series Benchmarks (GitHub #4508)](https://github.com/ggml-org/llama.cpp/discussions/4508)
- [CPU vs GPU On-Device LLM -- arXiv 2505.06461](https://arxiv.org/html/2505.06461v1)
- [Mobile LLM Benchmarking -- arXiv 2410.03613](https://arxiv.org/html/2410.03613v1)
- [PrivateLLM: Llama 3.2 on iOS](https://privatellm.app/blog/run-meta-llama-3-2-1b-3b-models-locally-on-ios-devices)
- [Enclave AI Quantization Guide](https://enclaveai.app/blog/2025/11/12/practical-quantization-guide-iphone-mac-gguf/)
- [Argmax iPhone 17 Benchmarks](https://www.argmaxinc.com/blog/iphone-17-on-device-inference-benchmarks)

### Models
- [Ministral 3B Model Card](https://huggingface.co/mistralai/Ministral-3-3B-Instruct-2512)
- [Phi-4 Mini Model Card](https://huggingface.co/microsoft/Phi-4-mini-instruct)
- [Llama 3.2 Model Card](https://huggingface.co/meta-llama/Llama-3.2-3B-Instruct)
- [Qwen 3 Collection](https://huggingface.co/collections/Qwen/qwen3-67dd247413f0e2e4f653967f)
- [huihui-ai Abliterated Collections](https://huggingface.co/huihui-ai)

### Licensing
- [Llama 3.2 Community License](https://www.llama.com/llama3_2/license/)
- [Gemma Terms of Use](https://ai.google.dev/gemma/terms)
- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple Guideline 5.1.2(i) AI Data Sharing](https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai/)

### Integration
- [llama.cpp GitHub](https://github.com/ggml-org/llama.cpp)
- [LLM.swift](https://github.com/eastriverlee/LLM.swift)
- [llama-cpp-swift](https://github.com/srgtuszy/llama-cpp-swift)
- [MLX Swift](https://github.com/ml-explore/mlx-swift)
- [Apple Foundation Models (iOS 26)](https://developer.apple.com/documentation/foundationmodels)

### Fine-Tuning
- [Unsloth](https://github.com/unslothai/unsloth)
- [Abliteration Technique (mlabonne)](https://huggingface.co/blog/mlabonne/abliteration)
- [Abliteration Academic Study (2025)](https://www.mdpi.com/1999-5903/17/10/477)
