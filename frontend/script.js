// Replace this with your Render service URL after deploying the backend, e.g.
//   const BACKEND_URL = "https://bedtime-story-api.onrender.com";
// For local development: keep "http://localhost:8000" and run uvicorn locally.
const BACKEND_URL = "https://bedtime-story-api-dmoy.onrender.com";

function escapeHtml(s) {
    return s.replace(/[&<>"']/g, c => ({
        "&": "&amp;", "<": "&lt;", ">": "&gt;", "\"": "&quot;", "'": "&#39;"
    }[c]));
}

function renderStory(text) {
    const out = document.getElementById("story-output");
    out.classList.remove("story-empty", "story-loading");
    out.classList.add("story-rendered");
    document.body.classList.add("story-active");
    const paragraphs = text.split(/\n\s*\n/).map(p => `<p>${escapeHtml(p)}</p>`).join("");
    out.innerHTML = paragraphs;
}

function showLoading() {
    const out = document.getElementById("story-output");
    out.classList.remove("story-empty", "story-rendered");
    out.classList.add("story-loading");
    out.innerHTML = '<p class="placeholder"><em>Writing your story…</em></p>';
}

function showEmpty() {
    const out = document.getElementById("story-output");
    out.classList.remove("story-loading", "story-rendered");
    out.classList.add("story-empty");
    out.innerHTML = '<p class="placeholder">Your story will appear here.</p>';
    document.body.classList.remove("story-active");
}

document.getElementById("generate-btn").addEventListener("click", async () => {
    const form = document.getElementById("story-form");
    const errEl = document.getElementById("error");
    errEl.textContent = "";
    showLoading();

    const payload = {
        child_name: form.child_name.value,
        characters: form.characters.value,
        setting: form.setting.value,
        plot: form.plot.value,
    };

    try {
        const r = await fetch(`${BACKEND_URL}/story`, {
            method: "POST",
            headers: {"Content-Type": "application/json"},
            body: JSON.stringify(payload),
        });
        const data = await r.json();
        if (!r.ok) throw new Error(data.detail || "Request failed");
        renderStory(data.story);
        loadRecentStories();
    } catch (e) {
        showEmpty();
        errEl.textContent = e.message;
    }
});

async function loadRecentStories() {
    const name = document.querySelector('[name="child_name"]').value.trim();
    const aside = document.getElementById("recent-stories");
    const list = document.getElementById("recent-list");
    if (!name) { aside.hidden = true; return; }
    try {
        const r = await fetch(`${BACKEND_URL}/stories?child_name=${encodeURIComponent(name)}`);
        if (!r.ok) { aside.hidden = true; return; }
        const items = await r.json();
        if (items.length === 0) { aside.hidden = true; return; }
        list.innerHTML = items.map(it =>
            `<li><button type="button" class="recent-item" data-body="${escapeHtml(it.body)}">
               <span class="recent-plot">${escapeHtml(it.plot)}</span>
               <span class="recent-date">${escapeHtml(it.created_at)}</span>
             </button></li>`
        ).join("");
        list.querySelectorAll(".recent-item").forEach(btn => {
            btn.addEventListener("click", () => renderStory(btn.dataset.body));
        });
        aside.hidden = false;
    } catch (e) { aside.hidden = true; }
}

document.querySelector('[name="child_name"]').addEventListener("blur", loadRecentStories);
