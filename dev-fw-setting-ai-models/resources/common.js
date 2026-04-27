// 公共配置
const PLATFORMS = {
    deepseek: {
        name: 'DeepSeek',
        endpoint: 'https://api.deepseek.com/v1/chat/completions',
        model: 'deepseek-chat',
        apiKeyHelp: '获取 API Key: <a href="https://platform.deepseek.com/" target="_blank" class="underline">https://platform.deepseek.com/</a>',
        pricing: { inputPerM: 0.28, outputPerM: 0.42, currency: '$', url: 'https://api-docs.deepseek.com/quick_start/pricing' }
    },
    siliconflow: {
        name: '硅基流动',
        endpoint: 'https://api.siliconflow.cn/v1/chat/completions',
        models: [
            { id: 'deepseek-ai/DeepSeek-V3.2', name: 'DeepSeek-V3.2', inputPerM: 2, outputPerM: 3 },
            { id: 'Qwen/Qwen2.5-7B-Instruct', name: 'Qwen2.5-7B', inputPerM: 0, outputPerM: 0, free: true },
            { id: 'THUDM/glm-4-9b-chat', name: 'GLM-4-9B', inputPerM: 0, outputPerM: 0, free: true },
            { id: 'deepseek-ai/DeepSeek-R1-Distill-Qwen-7B', name: 'R1-7B', inputPerM: 0, outputPerM: 0, free: true },
            { id: 'Qwen/Qwen3-8B', name: 'Qwen3-8B', inputPerM: 0, outputPerM: 0, free: true }
        ],
        apiKeyHelp: 'API Key: <a href="https://cloud.siliconflow.cn/me/account/ak" target="_blank" class="underline">https://cloud.siliconflow.cn/me/account/ak</a> | 余额: <a href="https://cloud.siliconflow.cn/me/expensebill" target="_blank" class="underline">https://cloud.siliconflow.cn/me/expensebill</a> | 官网: <a href="https://siliconflow.cn/" target="_blank" class="underline">https://siliconflow.cn/</a>',
        pricing: { inputPerM: 2, outputPerM: 3, currency: '¥', url: 'https://siliconflow.cn/pricing' }
    }
};

let currentPlatform = 'deepseek';
let currentModel = 'deepseek-chat';
let isGenerating = false;

// ========== 公共函数 ==========

function getCurrentModelConfig() {
    const platform = PLATFORMS[currentPlatform];
    if (platform.models) {
        return platform.models.find(m => m.id === currentModel) || platform.models[0];
    }
    return { id: platform.model, inputPerM: platform.pricing.inputPerM, outputPerM: platform.pricing.outputPerM };
}

function selectPlatform(platform) {
    currentPlatform = platform;
    
    document.querySelectorAll('.platform-btn').forEach(btn => {
        btn.classList.remove('bg-white/20');
        btn.classList.add('bg-white/10', 'text-white/60');
    });
    document.getElementById(`btn-${platform}`).classList.remove('bg-white/10', 'text-white/60');
    document.getElementById(`btn-${platform}`).classList.add('bg-white/20', 'text-white');
    
    document.getElementById('apiKeyHelp').innerHTML = PLATFORMS[platform].apiKeyHelp;
    
    const pricing = PLATFORMS[platform].pricing;
    if (pricing.currency === '$') {
        document.getElementById('pricingInfo').innerHTML = `定价: 输入 $${pricing.inputPerM}/M, 输出 $${pricing.outputPerM}/M <a id="pricingUrl" href="${pricing.url}" target="_blank" class="underline">(来源)</a>`;
        const estCost = (1000/1000000 * pricing.inputPerM) + (500/1000000 * pricing.outputPerM);
        document.getElementById('estimateInfo').textContent = `预计每次: 约 $${estCost.toFixed(4)} (~¥${(estCost*7.2).toFixed(2)})`;
    } else {
        document.getElementById('pricingInfo').innerHTML = `定价: 输入 ¥${pricing.inputPerM}/M, 输出 ¥${pricing.outputPerM}/M <a id="pricingUrl" href="${pricing.url}" target="_blank" class="underline">(来源)</a>`;
        const estCost = (1000/1000000 * pricing.inputPerM) + (500/1000000 * pricing.outputPerM);
        document.getElementById('estimateInfo').textContent = `预计每次: 约 ¥${estCost.toFixed(4)}`;
    }
    
    const modelSelector = document.getElementById('modelSelector');
    const platformConfig = PLATFORMS[currentPlatform];
    if (platformConfig.models && platformConfig.models.length > 1) {
        modelSelector.innerHTML = '';
        platformConfig.models.forEach(model => {
            const isFree = model.free ? 'text-green-400' : '';
            const label = model.free ? `${model.name} (免费)` : model.name;
            const btn = document.createElement('button');
            btn.className = `model-btn px-3 py-1 rounded-lg bg-white/10 text-white/70 text-xs transition-all hover:bg-white/20 ${isFree}`;
            btn.textContent = label;
            btn.onclick = () => selectModel(model.id);
            modelSelector.appendChild(btn);
        });
        modelSelector.classList.remove('hidden');
        const savedModel = localStorage.getItem(`model_${currentPlatform}`) || platformConfig.models[0].id;
        currentModel = savedModel;
        selectModel(savedModel);
    } else {
        modelSelector.classList.add('hidden');
        currentModel = platformConfig.models ? platformConfig.models[0].id : platformConfig.model;
        if (platformConfig.models && platformConfig.models[0]) {
            selectModel(platformConfig.models[0].id);
        } else {
            const pricing = platformConfig.pricing;
            document.getElementById('pricingInfo').innerHTML = `定价: 输入 $${pricing.inputPerM}/M, 输出 $${pricing.outputPerM}/M <a id="pricingUrl" href="${pricing.url}" target="_blank" class="underline">(来源)</a>`;
            const estCost = (1000/1000000 * pricing.inputPerM) + (500/1000000 * pricing.outputPerM);
            document.getElementById('estimateInfo').textContent = `预计每次: 约 $${estCost.toFixed(4)} (~¥${(estCost*7.2).toFixed(2)})`;
        }
    }
    
    const savedKey = localStorage.getItem(`api_key_${platform}`);
    document.getElementById('apiKey').value = savedKey || '';
    
    localStorage.setItem('selected_platform', platform);
    
    updateNextModelTip();
}

function updateNextModelTip() {
    const btnSubText = document.getElementById('btnSubText');
    if (!btnSubText) return;
    const modelConfig = getCurrentModelConfig();
    const freeTag = modelConfig.free ? ' (免费)' : '';
    btnSubText.textContent = `${PLATFORMS[currentPlatform].name} / ${modelConfig.name || currentModel}${freeTag}`;
}

function selectModel(modelId) {
    currentModel = modelId;
    localStorage.setItem(`model_${currentPlatform}`, modelId);
    
    document.querySelectorAll('.model-btn').forEach(btn => {
        btn.classList.remove('bg-white/20', 'text-white');
        btn.classList.add('bg-white/10', 'text-white/70');
    });
    
    const platformConfig = PLATFORMS[currentPlatform];
    const selectedModel = platformConfig.models.find(m => m.id === modelId);
    const buttons = document.querySelectorAll('.model-btn');
    const index = platformConfig.models.findIndex(m => m.id === modelId);
    if (buttons[index]) {
        buttons[index].classList.remove('bg-white/10', 'text-white/70');
        buttons[index].classList.add('bg-white/20', 'text-white');
    }
    
    if (selectedModel && selectedModel.free) {
        document.getElementById('pricingInfo').innerHTML = `定价: 免费 <a href="${PLATFORMS[currentPlatform].pricing.url}" target="_blank" class="underline">(来源)</a>`;
        document.getElementById('estimateInfo').textContent = '预计每次: 免费';
    } else if (selectedModel) {
        const inputPrice = selectedModel.inputPerM;
        const outputPrice = selectedModel.outputPerM;
        document.getElementById('pricingInfo').innerHTML = `定价: 输入 ¥${inputPrice}/M, 输出 ¥${outputPrice}/M <a href="${PLATFORMS[currentPlatform].pricing.url}" target="_blank" class="underline">(来源)</a>`;
        const estCost = (1000/1000000 * inputPrice) + (500/1000000 * outputPrice);
        document.getElementById('estimateInfo').textContent = `预计每次: 约 ¥${estCost.toFixed(4)}`;
    }
    
    updateNextModelTip();
}

function saveApiKey() {
    const apiKey = document.getElementById('apiKey').value.trim();
    if (apiKey) {
        localStorage.setItem(`api_key_${currentPlatform}`, apiKey);
        showToast('API Key 已保存！');
    }
}

function getApiKey() {
    return document.getElementById('apiKey').value.trim() || localStorage.getItem(`api_key_${currentPlatform}`);
}

function showToast(msg = '已复制到剪贴板！') {
    const toast = document.getElementById('toast');
    toast.textContent = msg;
    toast.style.opacity = '1';
    setTimeout(() => {
        toast.style.opacity = '0';
    }, 2000);
}

async function copyToClipboard(text) {
    try {
        await navigator.clipboard.writeText(text);
        showToast();
    } catch (err) {
        const textarea = document.createElement('textarea');
        textarea.value = text;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('copy');
        document.body.removeChild(textarea);
        showToast();
    }
}

function updateModelInfoDisplay() {
    const modelInfo = document.getElementById('modelInfo');
    const platformDisplay = document.getElementById('platformDisplay');
    const modelDisplay = document.getElementById('modelDisplay');
    platformDisplay.textContent = PLATFORMS[currentPlatform].name;
    const modelConfig = getCurrentModelConfig();
    modelDisplay.textContent = modelConfig.name || currentModel;
    modelInfo.classList.remove('hidden');
}

function updateTokenUsage(data) {
    const usage = data.usage;
    if (usage) {
        const totalTokens = usage.total_tokens || 0;
        const promptTokens = usage.prompt_tokens || 0;
        const completionTokens = usage.completion_tokens || 0;
        
        document.getElementById('tokenCount').textContent = totalTokens;
        
        const modelConfig = getCurrentModelConfig();
        if (modelConfig.free) {
            document.getElementById('tokenCost').textContent = '免费';
        } else {
            const inputCost = (promptTokens / 1000000) * modelConfig.inputPerM;
            const outputCost = (completionTokens / 1000000) * modelConfig.outputPerM;
            const totalCost = inputCost + outputCost;
            document.getElementById('tokenCost').textContent = `约 ¥${totalCost.toFixed(4)}`;
        }
        
        document.getElementById('tokenUsage').classList.remove('hidden');
    }
}

function showLoadingSkeleton(container) {
    container.innerHTML = `
        <div class="bg-white rounded-xl p-5 flex flex-col gap-3">
            <div class="skeleton h-6 w-24 rounded"></div>
            <div class="skeleton h-5 w-full rounded"></div>
            <div class="skeleton h-5 w-3/4 rounded"></div>
        </div>
        <div class="bg-white rounded-xl p-5 flex flex-col gap-3">
            <div class="skeleton h-6 w-24 rounded"></div>
            <div class="skeleton h-5 w-full rounded"></div>
            <div class="skeleton h-5 w-2/3 rounded"></div>
        </div>
        <div class="bg-white rounded-xl p-5 flex flex-col gap-3">
            <div class="skeleton h-6 w-24 rounded"></div>
            <div class="skeleton h-5 w-full rounded"></div>
            <div class="skeleton h-5 w-4/5 rounded"></div>
        </div>
        <div class="bg-white rounded-xl p-5 flex flex-col gap-3">
            <div class="skeleton h-6 w-24 rounded"></div>
            <div class="skeleton h-5 w-full rounded"></div>
            <div class="skeleton h-5 w-1/2 rounded"></div>
        </div>
    `;
}

function showErrorCard(container, errorMsg) {
    container.innerHTML = `
        <div class="bg-white rounded-xl p-6 col-span-2 text-center">
            <div class="text-4xl mb-3">😢</div>
            <p class="text-red-500 font-medium">生成失败</p>
            <p class="text-gray-500 text-sm mt-2">${errorMsg}</p>
        </div>
    `;
}

function initCommonUI() {
    const savedPlatform = localStorage.getItem('selected_platform') || 'deepseek';
    
    currentPlatform = savedPlatform;
    document.querySelectorAll('.platform-btn').forEach(btn => {
        btn.classList.remove('bg-white/20');
        btn.classList.add('bg-white/10', 'text-white/60');
    });
    document.getElementById(`btn-${savedPlatform}`).classList.remove('bg-white/10', 'text-white/60');
    document.getElementById(`btn-${savedPlatform}`).classList.add('bg-white/20', 'text-white');
    
    document.getElementById('apiKeyHelp').innerHTML = PLATFORMS[savedPlatform].apiKeyHelp;
    
    const modelSelector = document.getElementById('modelSelector');
    const platformConfig = PLATFORMS[savedPlatform];
    if (platformConfig.models && platformConfig.models.length > 1) {
        modelSelector.innerHTML = '';
        platformConfig.models.forEach(model => {
            const isFree = model.free ? 'text-green-400' : '';
            const label = model.free ? `${model.name} (免费)` : model.name;
            const btn = document.createElement('button');
            btn.className = `model-btn px-3 py-1 rounded-lg bg-white/10 text-white/70 text-xs transition-all hover:bg-white/20 ${isFree}`;
            btn.textContent = label;
            btn.onclick = () => selectModel(model.id);
            modelSelector.appendChild(btn);
        });
        modelSelector.classList.remove('hidden');
        const savedModel = localStorage.getItem(`model_${savedPlatform}`) || platformConfig.models[0].id;
        currentModel = savedModel;
        selectModel(savedModel);
    } else {
        modelSelector.classList.add('hidden');
        currentModel = platformConfig.models ? platformConfig.models[0].id : platformConfig.model;
        if (platformConfig.models && platformConfig.models[0]) {
            selectModel(platformConfig.models[0].id);
        }
    }
    
    const savedKey = localStorage.getItem(`api_key_${savedPlatform}`);
    document.getElementById('apiKey').value = savedKey || '';
    
    updateNextModelTip();
}

function startGenerating() {
    if (isGenerating) return true;
    isGenerating = true;
    
    const btnMainText = document.getElementById('btnMainText');
    const btn = document.getElementById('generateBtn');
    if (btnMainText) btnMainText.innerHTML = '<span class="loading-dots">✨ 思考中</span>';
    if (btn) btn.disabled = true;
    
    updateModelInfoDisplay();
    
    const container = document.getElementById('repliesContainer');
    const emptyState = document.getElementById('emptyState');
    if (emptyState) emptyState.style.display = 'none';
    
    document.getElementById('tokenUsage').classList.add('hidden');
    
    return false;
}

function finishGenerating(success = true) {
    isGenerating = false;
    const btnMainText = document.getElementById('btnMainText');
    const btnSubText = document.getElementById('btnSubText');
    const btn = document.getElementById('generateBtn');
    
    if (btnMainText) btnMainText.textContent = '✨ 重新生成';
    const modelConfig = getCurrentModelConfig();
    const freeTag = modelConfig.free ? ' (免费)' : '';
    if (btnSubText) btnSubText.textContent = `${PLATFORMS[currentPlatform].name} / ${modelConfig.name || currentModel}${freeTag}`;
    if (btn) btn.disabled = false;
}
