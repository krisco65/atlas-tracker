# Fine-Tuning Small LLMs (1B-3B) for On-Device iOS Deployment

## Complete Research Guide & Recommended Workflows

---

## 1. Fine-Tuning Methods Comparison

### Full Fine-Tuning vs LoRA vs QLoRA

| Aspect | Full Fine-Tuning | LoRA | QLoRA |
|--------|-----------------|------|-------|
| Trainable Parameters | 100% | ~1-5% | ~1-5% |
| Base Model Precision | FP16/BF16 | FP16/BF16 | 4-bit (NF4) |
| Quality | Best | Near-identical for instruction tuning | Near-identical for instruction tuning |
| VRAM (1B model) | ~12-16 GB | ~4-6 GB | ~2-4 GB |
| VRAM (3B model) | ~36-48 GB | ~8-12 GB | ~4-7 GB |
| Training Speed | Slowest | Fast | Fastest (less data movement) |
| Best For | Maximum quality, domain shift | Best balance of quality/cost | Minimal hardware |

### VRAM Requirements (Extrapolated from Benchmarks)

**Based on the general formula: ~16 GB per 1B params for full FT (FP16), ~2 GB per 1B for LoRA, ~0.5-1 GB per 1B for QLoRA (4-bit) + overhead:**

| Model Size | Full FT (FP16) | LoRA (FP16) | QLoRA (4-bit) |
|-----------|----------------|-------------|---------------|
| 1B | ~16 GB | ~4-6 GB | ~2-4 GB |
| 1.5B | ~24 GB | ~6-8 GB | ~3-5 GB |
| 2B | ~32 GB | ~7-10 GB | ~4-6 GB |
| 3B | ~48 GB | ~10-14 GB | ~5-8 GB |

**Key real-world data points:**
- Qwen2.5-1.5B with QLoRA on RTX 4060 (8 GB): peaked at 6.2 GB VRAM
- Llama 3.2 1B with QLoRA via Unsloth: fits on 4 GB VRAM
- Llama 3.2 3B with QLoRA via Unsloth: fits on 7 GB VRAM

### Training Time Estimates (~10K Examples)

**Based on benchmarks with Qwen2.5-1.5B on RTX 4060 (8 GB, QLoRA):**
- Throughput: ~500-628 tokens/sec
- 10K examples at ~256 avg tokens each = ~2.56M tokens
- At 500 tokens/sec: ~85 minutes per epoch
- 3 epochs: ~4-5 hours on RTX 4060

**Estimated times for 10K dataset, 3 epochs:**

| Model | RTX 3090 (24 GB) | RTX 4090 (24 GB) | T4 (16 GB, Colab) | A100 (40 GB) |
|-------|-------------------|-------------------|---------------------|--------------|
| 1B QLoRA | ~1-2 hours | ~45 min - 1.5 hours | ~3-5 hours | ~30-60 min |
| 3B QLoRA | ~2-4 hours | ~1.5-3 hours | ~6-10 hours | ~1-2 hours |
| 1B LoRA | ~1.5-3 hours | ~1-2 hours | ~4-7 hours | ~45-90 min |
| 3B LoRA | ~3-6 hours | ~2-4 hours | ~8-14 hours | ~1.5-3 hours |

### Consumer GPU Feasibility

**RTX 3090 (24 GB VRAM):** Can handle full fine-tuning of 1B models, LoRA of 3B models, QLoRA of anything up to ~13B. Excellent choice.

**RTX 4090 (24 GB VRAM):** Same capacity as 3090 but ~30-50% faster due to Ada Lovelace architecture. Best consumer option.

**RTX 4060/4070 (8-12 GB):** QLoRA only for 1B-3B models. Confirmed working with Qwen2.5-1.5B.

### Cloud GPU Options

| Platform | GPU | VRAM | Cost/hr | Best For |
|----------|-----|------|---------|----------|
| Google Colab Free | T4 | 15 GB | Free (limited) | QLoRA 1B-3B prototyping |
| Google Colab Pro | V100/A100 | 16-40 GB | ~$10/mo | Serious fine-tuning |
| RunPod | RTX 4090 | 24 GB | ~$0.34/hr | Best value for 1B-3B |
| RunPod | A100 40GB | 40 GB | ~$1.19/hr | Faster training |
| RunPod | H100 80GB | 80 GB | ~$1.99/hr | Full FT of 3B+ |
| Lambda Labs | A100 40GB | 40 GB | ~$1.10/hr | Reliable, good tooling |

**Recommendation for 1B-3B models:** Google Colab Free/Pro is sufficient for QLoRA. RunPod RTX 4090 at $0.34/hr is the best value for LoRA.

---

## 2. Fine-Tuning Tools Comparison

### Framework Comparison Matrix

| Feature | HF Transformers + PEFT | Unsloth | Axolotl | LLaMA-Factory |
|---------|----------------------|---------|---------|---------------|
| Speed | Baseline | 2-5x faster | ~0.9x (slight overhead) | ~1x |
| VRAM Savings | Baseline | Up to 80% less | Similar to baseline | Similar to baseline |
| Ease of Use | Medium (code) | Easy (notebooks) | Easy (YAML config) | Easiest (Web UI) |
| Model Support | Broadest | Llama, Gemma, Phi, Qwen, Mistral | Very broad | 100+ models |
| LoRA/QLoRA | Yes | Yes | Yes | Yes |
| GGUF Export | Manual | Built-in | Manual | Manual |
| Google Colab | Yes | Yes (official notebooks) | Yes | Yes |
| Community | Largest | Growing fast | Strong | Large (esp. in Asia) |
| Documentation | Excellent | Good | Good | Good |

### Best Tool Per Model Family

| Model Family | Recommended Tool | Reason |
|-------------|-----------------|--------|
| Llama 3.2 1B/3B | **Unsloth** | Official notebooks, 2x speed, built-in GGUF export |
| Gemma 2 2B | **Unsloth** or HF PEFT | Good support, but watch for BOS token gotcha |
| Phi-3.5 Mini | **HF PEFT** or LLaMA-Factory | Broad support, Microsoft's recommended approach |
| Qwen 2.5 1.5B/3B | **Unsloth** | Official Qwen Coder notebooks, fast training |
| Any model (no code) | **LLaMA-Factory** | Web UI, zero-code workflow |

### Recommended: Unsloth

Unsloth is the top recommendation for this use case because:
1. 2x faster training, 60-80% less VRAM
2. Free Google Colab notebooks for every major model
3. Built-in GGUF export (no manual conversion needed)
4. Active development (supports latest models within days of release)
5. Works with standard HF datasets

---

## 3. Dataset Format Requirements

### Format Comparison

#### ChatML Format (RECOMMENDED - most universal)
```json
{
  "messages": [
    {"role": "system", "content": "You are a helpful supplement advisor."},
    {"role": "user", "content": "What is creatine monohydrate good for?"},
    {"role": "assistant", "content": "Creatine monohydrate is one of the most researched supplements..."}
  ]
}
```
**Used by:** Qwen 2.5 (natively), Phi-3.5, and widely supported.

#### Alpaca Format (simpler, single-turn)
```json
{
  "instruction": "Explain the benefits of creatine monohydrate",
  "input": "",
  "output": "Creatine monohydrate is one of the most researched supplements..."
}
```
**Used by:** Many fine-tuning tutorials, good for simple instruction-following.

#### ShareGPT Format (multi-turn conversations)
```json
{
  "conversations": [
    {"from": "human", "value": "What is creatine monohydrate good for?"},
    {"from": "gpt", "value": "Creatine monohydrate is one of the most researched supplements..."},
    {"from": "human", "value": "How much should I take daily?"},
    {"from": "gpt", "value": "The standard dosing protocol is 3-5g per day..."}
  ]
}
```
**Used by:** Unsloth (with conversion), community datasets.

### Model-Specific Chat Templates

| Model | Native Chat Template | Special Tokens |
|-------|---------------------|----------------|
| Llama 3.2 | `<\|begin_of_text\|><\|start_header_id\|>system<\|end_header_id\|>...` | `<\|eot_id\|>` for turn end |
| Gemma 2 | `<start_of_turn>user\n...<end_of_turn>` | BOS token auto-added (watch for duplicates) |
| Phi-3.5 | `<\|user\|>\n...<\|end\|>\n<\|assistant\|>` | Uses `<\|end\|>` delimiter |
| Qwen 2.5 | `<\|im_start\|>system\n...<\|im_end\|>` | ChatML natively |

**Important:** When using Unsloth or HF TRL, use `tokenizer.apply_chat_template()` to automatically handle these formats. Do NOT manually construct templates.

### Dataset Size Guidelines

| Dataset Size | Expected Outcome |
|-------------|-----------------|
| 100-500 | Minimal adaptation, might overfit |
| 500-1,000 | Basic style/format adaptation |
| 1,000-5,000 | Good domain adaptation |
| 5,000-10,000 | Strong instruction-following in domain |
| 10,000-50,000 | Excellent fine-tuning, robust behavior |
| 50,000+ | Approaching diminishing returns for small models |

**For a 10K example dataset: This is an excellent size** for fine-tuning 1B-3B models. You should see strong domain adaptation and robust instruction-following.

### Dataset Quality Best Practices

1. **Clean data thoroughly** - Remove duplicates, fix formatting, validate JSON
2. **Balance categories** - Avoid overrepresenting any single topic/style
3. **Vary response lengths** - Mix short and detailed responses
4. **Include edge cases** - "I don't know" responses, boundary conditions
5. **Quality over quantity** - 5K high-quality examples > 50K noisy ones
6. **Test synthetic data** - If using GPT-4/Claude to generate data, manually review a sample
7. **Match deployment format** - Train data should mirror how users will interact with the model

---

## 4. Quantization for Deployment

### Quantization Levels Comparison (7B Model Baseline)

| Method | Bits/Weight | Size (7B) | Perplexity Loss | Quality Rating | Recommendation |
|--------|-----------|-----------|-----------------|----------------|----------------|
| F16 | 16.0 | 13.00 GB | 0 (baseline) | Perfect | Storage only |
| Q8_0 | 8.5 | 6.70 GB | +0.0004 | Near-perfect | When quality is paramount |
| Q6_K | 6.6 | 5.15 GB | +0.0044 | Excellent | Mac with good RAM |
| Q5_K_M | 5.7 | 4.45 GB | +0.0142 | Very good | Best quality/size ratio |
| Q5_K_S | 5.5 | 4.33 GB | +0.0353 | Good | Slightly smaller Q5 |
| Q4_K_M | 4.9 | 3.80 GB | +0.0535 | Good | **Best for iPhone** |
| Q4_K_S | 4.6 | 3.56 GB | +0.1149 | Acceptable | Tight RAM budget |
| Q3_K_L | 3.6 | 3.35 GB | +0.1803 | Noticeable loss | Only if desperate |
| Q3_K_M | 3.4 | 3.06 GB | +0.2437 | Significant loss | Not recommended |
| Q2_K | 2.7 | 2.67 GB | +0.8698 | Severe loss | Avoid |

### Estimated File Sizes for Small Models

**Extrapolated from 7B data (sizes scale roughly linearly with parameter count):**

| Model Size | F16 | Q8_0 | Q6_K | Q5_K_M | Q4_K_M | Q3_K_M | Q2_K |
|-----------|------|------|------|--------|--------|--------|------|
| 1B | ~2.0 GB | ~1.0 GB | ~0.75 GB | ~0.65 GB | ~0.55 GB | ~0.45 GB | ~0.40 GB |
| 1.5B | ~3.0 GB | ~1.5 GB | ~1.1 GB | ~0.95 GB | ~0.80 GB | ~0.65 GB | ~0.55 GB |
| 2B | ~4.0 GB | ~2.0 GB | ~1.5 GB | ~1.3 GB | ~1.1 GB | ~0.90 GB | ~0.75 GB |
| 3B | ~6.0 GB | ~3.0 GB | ~2.2 GB | ~1.9 GB | ~1.6 GB | ~1.3 GB | ~1.1 GB |

**Critical insight for small models:** Quality degradation from quantization is MORE pronounced on smaller models. A 1B model at Q4_K_M loses proportionally more capability than a 7B model at Q4_K_M. For 1B-3B models, prefer Q5_K_M or Q6_K if RAM permits.

### iPhone RAM Budget

| iPhone Model | Total RAM | Available for Model | Recommended Quant (3B) | Recommended Quant (1B) |
|-------------|-----------|--------------------|-----------------------|-----------------------|
| iPhone 15 Pro | 8 GB | ~3-4 GB | Q4_K_M (~1.6 GB) | Q6_K (~0.75 GB) |
| iPhone 15 | 6 GB | ~2-3 GB | Q4_K_M (~1.6 GB) | Q5_K_M (~0.65 GB) |
| iPhone 14 Pro | 6 GB | ~2-3 GB | Q4_K_M (~1.6 GB) | Q5_K_M (~0.65 GB) |
| iPhone 14 | 6 GB | ~2-3 GB | Q3_K_M (~1.3 GB) | Q5_K_M (~0.65 GB) |
| iPhone SE 3 | 4 GB | ~1.5-2 GB | Too tight | Q4_K_M (~0.55 GB) |

### Quantization Tools

| Tool | Format | Best For |
|------|--------|----------|
| **llama.cpp quantize** | GGUF | On-device / llama.cpp inference (RECOMMENDED) |
| AutoGPTQ | GPTQ | GPU inference via vLLM/TGI |
| AWQ | AWQ | GPU inference, slightly better than GPTQ |
| Bitsandbytes | NF4/INT8 | Training (QLoRA), not deployment |

**For iOS deployment: Use llama.cpp quantize to GGUF.** This is the only practical path for on-device inference.

### Importance Matrix (imatrix) - Strongly Recommended for Small Models

The importance matrix tells the quantizer which weights are most critical. This is especially valuable for 1B-3B models where every bit matters.

**When to use imatrix:**
- Always for Q4_K_M and below on 1B-3B models
- Recommended for Q5_K_M on 1B models
- Optional for Q6_K+ (marginal benefit)

---

## 5. Model-Specific Fine-Tuning Notes

### Llama 3.2 1B / 3B

**Pros:**
- Excellent instruction-following even at 1B
- Strong community support, most tutorials target Llama
- Unsloth has official Google Colab notebooks
- 1B model outperforms Llama 2 13B on many benchmarks

**Chat Template:**
```
<|begin_of_text|><|start_header_id|>system<|end_header_id|>

{system_message}<|eot_id|><|start_header_id|>user<|end_header_id|>

{user_message}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

{assistant_message}<|eot_id|>
```

**Gotchas:**
- Use `tokenizer.apply_chat_template()` - do NOT manually construct templates
- The model auto-adds a "Cutting Knowledge Date: December 2023" system message
- Tool calling is supported but very sensitive to template format
- Ensure `<|eot_id|>` is properly set as the EOS token to prevent infinite generation
- Requires accepting Meta's license agreement on Hugging Face

**Recommended LoRA Config:**
```python
lora_r = 16          # Rank (8-32 for small models)
lora_alpha = 32      # Usually 2x rank
lora_dropout = 0.05
target_modules = ["q_proj", "k_proj", "v_proj", "o_proj",
                  "gate_proj", "up_proj", "down_proj"]
```

---

### Gemma 2 2B

**Pros:**
- Strong reasoning for its size
- Good multilingual support
- Google-backed with active development

**Chat Template:**
```
<start_of_turn>user
{user_message}<end_of_turn>
<start_of_turn>model
{assistant_message}<end_of_turn>
```

**Gotchas:**
- **BOS Token Duplication:** The model auto-adds a BOS token. If your chat template also adds one, you get duplicate BOS tokens. Remove the BOS from your template if using manual formatting.
- **Not ChatML-native:** Gemma was initially difficult to fine-tune with ChatML. Use its native template or HF's `setup_chat_format()`.
- **Remove 'lm_head' from LoRA target modules** when using 16-bit precision.
- GGUF conversion has had some issues reported with Unsloth - verify output.

**Recommended LoRA Config:**
```python
lora_r = 16
lora_alpha = 32
lora_dropout = 0.05
target_modules = ["q_proj", "k_proj", "v_proj", "o_proj",
                  "gate_proj", "up_proj", "down_proj"]
# Do NOT include "lm_head" for 16-bit LoRA
```

---

### Phi-3.5 Mini (3.8B)

**Pros:**
- Excellent reasoning and coding for its size
- Microsoft-backed with enterprise support
- Good at structured output / JSON generation

**Chat Template:**
```
<|user|>
{user_message}<|end|>
<|assistant|>
{assistant_message}<|end|>
```

**Gotchas:**
- At 3.8B parameters, it is slightly larger than the 3B target range
- LoRA rank 8-16 is sufficient; higher ranks waste compute
- Start learning rate at 5e-5 to 8e-4 (NOT 1e-3 or 2e-4, per Microsoft guidance)
- Set rank = alpha for small datasets
- Supports both LoRA and QLoRA via Unsloth, HF PEFT, and Azure AI

**Recommended LoRA Config:**
```python
lora_r = 8            # Lower rank sufficient
lora_alpha = 8        # Equal to rank for small datasets
lora_dropout = 0.05
learning_rate = 5e-5  # Conservative start
```

---

### Qwen 2.5 1.5B / 3B

**Pros:**
- Best-in-class at 1.5B and 3B parameter sizes (multiple benchmarks)
- Native ChatML support (cleanest template)
- Strong coding and math capabilities
- Active community, LLaMA-Factory native support
- Available in 0.5B / 1.5B / 3B / 7B sizes

**Chat Template (ChatML native):**
```
<|im_start|>system
{system_message}<|im_end|>
<|im_start|>user
{user_message}<|im_end|>
<|im_start|>assistant
{assistant_message}<|im_end|>
```

**Gotchas:**
- **Base model special tokens are untrained.** Do NOT use `<|im_start|>` / `<|im_end|>` on the BASE model. Only use them on the -Instruct variant.
- Use learning rate 1e-5 to 5e-5 for fine-tuning instruct models
- 1,000-10,000 examples recommended by Qwen team for good results
- Works excellently with Unsloth (official blog post exists for Qwen 2.5 Coder)

**Recommended LoRA Config:**
```python
lora_r = 16
lora_alpha = 32
lora_dropout = 0.05
target_modules = ["q_proj", "k_proj", "v_proj", "o_proj",
                  "gate_proj", "up_proj", "down_proj"]
learning_rate = 2e-5
```

---

## 6. Post-Fine-Tune Workflow

### Complete Pipeline: Fine-Tune to iOS Deployment

```
Step 1: Fine-Tune (Unsloth/PEFT)
    |
Step 2: Merge LoRA Adapters into Base Model
    |
Step 3: Save Merged Model (FP16 Safetensors)
    |
Step 4: Convert to GGUF (FP16 or BF16)
    |
Step 5: Generate Importance Matrix (Optional but Recommended)
    |
Step 6: Quantize to Target Format (Q4_K_M / Q5_K_M)
    |
Step 7: Validate Quality (Perplexity + Manual Testing)
    |
Step 8: Test in llama.cpp CLI
    |
Step 9: Bundle into iOS App
```

### Step-by-Step Commands

#### Step 1: Fine-Tune with Unsloth (Example: Llama 3.2 3B)

```python
from unsloth import FastLanguageModel
import torch

# Load model in 4-bit for QLoRA
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="unsloth/Llama-3.2-3B-Instruct",
    max_seq_length=2048,
    dtype=None,       # Auto-detect
    load_in_4bit=True # QLoRA
)

# Add LoRA adapters
model = FastLanguageModel.get_peft_model(
    model,
    r=16,
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj",
                    "gate_proj", "up_proj", "down_proj"],
    lora_alpha=32,
    lora_dropout=0.05,
    bias="none",
    use_gradient_checkpointing="unsloth"  # Saves 30% VRAM
)

# Train with SFTTrainer
from trl import SFTTrainer
from transformers import TrainingArguments

trainer = SFTTrainer(
    model=model,
    tokenizer=tokenizer,
    train_dataset=dataset,
    args=TrainingArguments(
        per_device_train_batch_size=2,
        gradient_accumulation_steps=4,
        warmup_steps=10,
        num_train_epochs=3,
        learning_rate=2e-4,
        fp16=not torch.cuda.is_bf16_supported(),
        bf16=torch.cuda.is_bf16_supported(),
        logging_steps=10,
        output_dir="outputs",
        optim="adamw_8bit",
    ),
)

trainer.train()
```

#### Step 2-3: Merge LoRA and Save (Unsloth Method)

```python
# Unsloth has built-in merge + save
model.save_pretrained_merged(
    "merged_model",
    tokenizer,
    save_method="merged_16bit"  # Full FP16 merged model
)
```

#### Step 4: Convert to GGUF (Option A: Unsloth Built-in)

```python
# Unsloth can directly export to GGUF
model.save_pretrained_gguf(
    "model_gguf",
    tokenizer,
    quantization_method="f16"  # Export as FP16 GGUF first
)
```

#### Step 4: Convert to GGUF (Option B: Manual with llama.cpp)

```bash
# Clone llama.cpp
git clone --depth=1 https://github.com/ggml-org/llama.cpp.git

# Convert HF model to GGUF FP16
python llama.cpp/convert_hf_to_gguf.py merged_model \
  --outtype f16 --outfile model-F16.gguf
```

#### Step 5: Generate Importance Matrix (Recommended for small models)

```bash
# Build llama.cpp
cd llama.cpp && mkdir build && cd build
cmake .. && cmake --build . --config Release

# Download calibration data
curl -L https://huggingface.co/datasets/ggml-org/ci/resolve/main/wikitext-2-raw-v1.txt \
  -o calibration.txt

# Generate imatrix (takes 30-60 minutes)
./bin/llama-imatrix -m ../model-F16.gguf \
  -f calibration.txt -ngl 99
```

#### Step 6: Quantize

```bash
# With importance matrix (recommended)
./bin/llama-quantize --imatrix imatrix.dat \
  model-F16.gguf model-Q4_K_M.gguf q4_k_m

# Or for higher quality
./bin/llama-quantize --imatrix imatrix.dat \
  model-F16.gguf model-Q5_K_M.gguf q5_k_m

# Without importance matrix (simpler)
./bin/llama-quantize model-F16.gguf model-Q4_K_M.gguf q4_k_m
```

#### Step 7: Validate Quality

```bash
# Perplexity test (lower is better, compare to FP16 baseline)
./bin/llama-perplexity -m model-Q4_K_M.gguf \
  -f wikitext-2-raw-v1.txt -ngl 99

# Compare against FP16 baseline
./bin/llama-perplexity -m model-F16.gguf \
  -f wikitext-2-raw-v1.txt -ngl 99

# Acceptable: perplexity increase < 0.5 for Q4_K_M
# Ideal: perplexity increase < 0.1
```

#### Step 8: Test Interactively

```bash
# Interactive chat test
./bin/llama-cli -m model-Q4_K_M.gguf -ngl 99 \
  --chat-template llama3  # Use appropriate template

# Or use Ollama for easier testing
# Create Modelfile:
# FROM ./model-Q4_K_M.gguf
ollama create mymodel -f Modelfile
ollama run mymodel
```

#### Step 9: iOS Integration

The quantized GGUF file can be loaded by:
- **llama.cpp C library** compiled for iOS (via Swift/Obj-C bridge)
- **MLX** (Apple's ML framework, if converting to MLX format instead)
- **llama.swift** or similar Swift wrappers around llama.cpp

---

## 7. Model-Specific Recommended Workflows

### Workflow A: Llama 3.2 3B (Best Overall Choice)

```
1. Tool: Unsloth (Google Colab Free or RTX 4090)
2. Method: QLoRA (4-bit) with r=16, alpha=32
3. Dataset: ChatML format, 10K examples
4. Training: 3 epochs, lr=2e-4, batch=2, grad_accum=4
5. VRAM needed: ~7 GB (QLoRA via Unsloth)
6. Training time: ~2-4 hours on Colab T4
7. Export: Unsloth built-in GGUF export
8. Quantize: Q4_K_M with imatrix (for iPhone)
9. Final size: ~1.6 GB
10. Test: llama-perplexity + interactive chat
```

### Workflow B: Llama 3.2 1B (Smallest/Fastest)

```
1. Tool: Unsloth (Google Colab Free)
2. Method: QLoRA (4-bit) with r=16, alpha=32
3. Dataset: ChatML format, 10K examples
4. Training: 3 epochs, lr=2e-4, batch=4, grad_accum=2
5. VRAM needed: ~4 GB (QLoRA via Unsloth)
6. Training time: ~1-2 hours on Colab T4
7. Export: Unsloth built-in GGUF export
8. Quantize: Q5_K_M with imatrix (afford higher quality at 1B)
9. Final size: ~0.65 GB
10. Test: llama-perplexity + interactive chat
```

### Workflow C: Qwen 2.5 3B (Best Benchmark Performance)

```
1. Tool: Unsloth (Google Colab Free or RTX 4090)
2. Method: QLoRA (4-bit) with r=16, alpha=32
3. Dataset: ChatML format (native!), 10K examples
4. Training: 3 epochs, lr=2e-5, batch=2, grad_accum=4
5. VRAM needed: ~7 GB (QLoRA via Unsloth)
6. Training time: ~2-4 hours on Colab T4
7. Export: Manual (convert_hf_to_gguf.py)
8. Quantize: Q4_K_M with imatrix
9. Final size: ~1.6 GB
10. Test: llama-perplexity + interactive chat
```

### Workflow D: Qwen 2.5 1.5B (Best Small Model)

```
1. Tool: Unsloth (Google Colab Free)
2. Method: QLoRA (4-bit) with r=16, alpha=32
3. Dataset: ChatML format (native!), 10K examples
4. Training: 3 epochs, lr=2e-5, batch=4, grad_accum=2
5. VRAM needed: ~5 GB (QLoRA via Unsloth)
6. Training time: ~1.5-3 hours on Colab T4
7. Export: Manual (convert_hf_to_gguf.py)
8. Quantize: Q5_K_M with imatrix
9. Final size: ~0.95 GB
10. Test: llama-perplexity + interactive chat
```

### Workflow E: Gemma 2 2B (Google Ecosystem)

```
1. Tool: HF PEFT + TRL (or Unsloth with caution on GGUF export)
2. Method: QLoRA (4-bit) with r=16, alpha=32
3. Dataset: Gemma native format, 10K examples
4. Training: 3 epochs, lr=2e-4, batch=2, grad_accum=4
5. VRAM needed: ~6 GB
6. Training time: ~2-3 hours on Colab T4
7. Export: Manual (convert_hf_to_gguf.py) - verify BOS handling
8. Quantize: Q5_K_M with imatrix
9. Final size: ~1.3 GB
10. Test: Verify BOS token not duplicated, then perplexity + chat
```

---

## 8. Summary Recommendations

### For Atlas Tracker (iOS Health App)

**Primary recommendation: Qwen 2.5 3B or Llama 3.2 3B**

| Criteria | Llama 3.2 3B | Qwen 2.5 3B | Winner |
|----------|-------------|-------------|--------|
| Benchmark quality | Very good | Slightly better | Qwen |
| Community support | Excellent | Very good | Llama |
| Fine-tuning ease | Excellent (Unsloth) | Excellent (Unsloth) | Tie |
| GGUF export | Built-in (Unsloth) | Manual | Llama |
| Chat template | Complex but well-supported | ChatML (simplest) | Qwen |
| License | Llama Community License | Apache 2.0 | Qwen |
| iOS deployment size (Q4_K_M) | ~1.6 GB | ~1.6 GB | Tie |

**Decision matrix:**
- If you want the easiest end-to-end pipeline: **Llama 3.2 3B** (Unsloth handles everything)
- If you want the best raw quality and open license: **Qwen 2.5 3B**
- If you need the smallest possible model: **Llama 3.2 1B** or **Qwen 2.5 1.5B**
- If iPhone 14 or older (6 GB RAM): Use 1B-1.5B model at Q5_K_M

### Key Quantization Rule for Small Models

**Use the highest quantization level your device RAM allows.** Small models lose proportionally more from aggressive quantization than large models. For 1B-3B models:
- iPhone 15 Pro (8 GB): Q5_K_M for 3B, Q6_K for 1B
- iPhone 15/14 Pro (6 GB): Q4_K_M for 3B, Q5_K_M for 1B-1.5B
- Always generate an importance matrix when quantizing below Q6_K

---

## Sources

- [How to fine-tune open LLMs in 2025 with Hugging Face](https://www.philschmid.de/fine-tune-llms-in-2025)
- [Comparing Fine Tuning Frameworks](https://www.hyperbolic.ai/blog/comparing-finetuning-frameworks)
- [The Fine-Tuning Renaissance: LLaMA-Factory, Unsloth, DeepSpeed, Axolotl](https://hiya31.medium.com/the-fine-tuning-renaissance-comparing-llama-factory-unsloth-deepspeed-and-axolotl-d67d26b26be4)
- [Comparing LLM Fine-Tuning Frameworks: Axolotl, Unsloth, Torchtune](https://blog.spheron.network/comparing-llm-fine-tuning-frameworks-axolotl-unsloth-and-torchtune-in-2025)
- [Best frameworks for fine-tuning LLMs in 2025](https://modal.com/blog/fine-tuning-llms)
- [How much VRAM do I need for LLM fine-tuning?](https://modal.com/blog/how-much-vram-need-fine-tuning)
- [Profiling LoRA/QLoRA Fine-Tuning on Consumer GPUs: RTX 4060 Case Study](https://arxiv.org/html/2509.12229)
- [Fine-Tuning Llama 3.2 1B/3B on Budget GPUs](https://kaitchup.substack.com/p/fine-tuning-metas-llama-32-1b-3b)
- [Unsloth GitHub Repository](https://github.com/unslothai/unsloth)
- [Unsloth: Llama 3.2 fits on 4GB GPU](https://x.com/UnslothAI/status/1839340091241869698)
- [Fine-Tuning 1B LLaMA 3.2: Step-by-Step Guide](https://huggingface.co/blog/ImranzamanML/fine-tuning-1b-llama-32-a-comprehensive-article)
- [The Practical Quantization Guide for iPhone and Mac](https://enclaveai.app/blog/2025/11/12/practical-quantization-guide-iphone-mac-gguf/)
- [llama.cpp Quantize README](https://github.com/ggml-org/llama.cpp/blob/master/tools/quantize/README.md)
- [Quantization Methods Comparison (llama.cpp Discussion #2094)](https://github.com/ggml-org/llama.cpp/discussions/2094)
- [GGUF Quantized Models Complete Guide 2025](https://apatero.com/blog/gguf-quantized-models-complete-guide-2025)
- [Step-by-Step Model Merging and GGUF imatrix Quantization](https://k4yt3x.com/step-by-step-model-merging-and-gguf-imatrix-quantization/)
- [Choosing a GGUF Model: K-Quants, I-Quants](https://kaitchup.substack.com/p/choosing-a-gguf-model-k-quants-i)
- [Unsloth Datasets Guide](https://unsloth.ai/docs/get-started/fine-tuning-llms-guide/datasets-guide)
- [Unsloth Chat Templates](https://docs.unsloth.ai/basics/chat-templates)
- [Fine-Tuning Gemma 2 and Using it Locally](https://www.datacamp.com/tutorial/fine-tuning-gemma-2)
- [Fine-Tuning Gemma Models in Hugging Face](https://huggingface.co/blog/gemma-peft)
- [Qwen 2.5 Coder Fine-tuning with Unsloth](https://unsloth.ai/blog/qwen-coder)
- [Fine-Tuning Phi-3.5 (DataCamp)](https://www.datacamp.com/tutorial/fine-tuning-phi-3-5)
- [Llama 3.2 Model Cards and Prompt Formats](https://www.llama.com/docs/model-cards-and-prompt-formats/llama3_2/)
- [LoRA vs Full Fine-tuning: An Illusion of Equivalence](https://arxiv.org/abs/2410.21228)
- [LoRA & QLoRA Best Practices, Setup & Pitfalls](https://medium.com/@QuarkAndCode/lora-qlora-llm-fine-tuning-best-practices-setup-pitfalls-c8147d34a6fd)
- [LLaMA-Factory GitHub](https://github.com/hiyouga/LLaMA-Factory)
- [Cheapest Cloud Platforms for LLMs (2025)](https://code-b.dev/blog/cloud-platforms-for-fine-tuning-llms)
- [RunPod vs Google Colab Pro](https://www.thundercompute.com/blog/runpod-vs-google-colab-pro-gpu-comparison)
- [Evaluating Quantized LLMs: Perplexity, Accuracy](https://apxml.com/courses/practical-llm-quantization/chapter-6-evaluating-deploying-quantized-llms/evaluating-quantized-models)
- [Guide to Model Quantization and Picking the Right GGUF](https://siquick.com/blog/model-quantization-fine-tuning-pick-right-gguf)
