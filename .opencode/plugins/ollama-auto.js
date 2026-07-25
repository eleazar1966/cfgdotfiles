const OLLAMA_API = "http://localhost:11434";
const PROVIDER_ID = "ollama";

function detectCapabilities(name) {
  const lower = name.toLowerCase();
  const isReasoning = lower.includes("deepseek-r1") || lower.includes("qwq") || lower.includes("reason");
  const isCoder = lower.includes("coder");
  const isVision = lower.includes("vision") || lower.includes("llava") || lower.includes("gemma4");
  return {
    temperature: true,
    reasoning: isReasoning,
    tool_call: true,
    attachment: isVision,
  };
}

function estimateContext(name) {
  const lower = name.toLowerCase();
  const ctxMatch = lower.match(/(\d+)k/);
  if (ctxMatch) return parseInt(ctxMatch[1]) * 1024;
  if (lower.includes("32b") || lower.includes("27b") || lower.includes("26b")) return 131072;
  if (lower.includes("14b")) return 32768;
  if (lower.includes("8b") || lower.includes("7b")) return 16384;
  return 8192;
}

async function fetchOllamaModels() {
  try {
    const res = await fetch(`${OLLAMA_API}/api/tags`, { signal: AbortSignal.timeout(3000) });
    if (!res.ok) return null;
    const data = await res.json();
    return data.models || null;
  } catch {
    return null;
  }
}

async function buildProviderConfig() {
  const models = await fetchOllamaModels();
  if (!models || models.length === 0) return null;

  const modelMap = {};
  for (const m of models) {
    const name = m.name;
    const caps = detectCapabilities(name);
    modelMap[name] = {
      id: name,
      name: name,
      family: name.includes(":") ? name.split(":")[0] : name,
      temperature: caps.temperature,
      reasoning: caps.reasoning,
      tool_call: caps.tool_call,
      attachment: caps.attachment,
    };
  }

  return {
    npm: "@ai-sdk/openai-compatible",
    name: "Ollama (local)",
    options: { baseURL: `${OLLAMA_API}/v1` },
    models: modelMap,
  };
}

export default async function ollamaAutoPlugin() {
  return {
    config: async (cfg) => {
      const providerCfg = await buildProviderConfig();
      if (!providerCfg) return;

      if (!cfg.provider) cfg.provider = {};
      cfg.provider[PROVIDER_ID] = providerCfg;

      const modelKeys = Object.keys(providerCfg.models);
      if (!cfg.model) {
        const preferred = modelKeys.find((k) => k.includes("qwen2.5-coder") || k.includes("coder") || k.includes("gemma4"));
        cfg.model = `ollama/${preferred || modelKeys[0]}`;
      }

      if (!cfg.small_model && modelKeys.length > 0) {
        const small = modelKeys.find((k) => k.includes("7b") || k.includes("8b")) || modelKeys[modelKeys.length - 1];
        cfg.small_model = `ollama/${small}`;
      }
    },
  };
}
