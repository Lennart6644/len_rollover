const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'len_rollover';
const stack = document.getElementById('stack');
const KINDS = ['error', 'warning', 'info', 'success'];
const ICONS = { error: '!', warning: '!', info: 'i', success: '✓' };
let maxVisible = 4;

function applyTheme(ui) {
    if (!ui) return;
    const root = document.documentElement.style;
    root.setProperty('--width', ui.width + 'px');
    root.setProperty('--radius', ui.radius + 'px');
    root.setProperty('--font', ui.font);
    if (ui.colors) {
        Object.entries(ui.colors).forEach(([key, value]) => {
            root.setProperty('--c-' + key, value);
        });
    }
    stack.dataset.position = ui.position || 'top-left';
    maxVisible = ui.maxVisible || 4;
}

function activeToasts() {
    return [...stack.children].filter(t => !t.dataset.closing);
}

function dismiss(toast) {
    if (!toast || toast.dataset.closing) return;
    toast.dataset.closing = '1';
    toast.classList.remove('show');
    setTimeout(() => toast.remove(), 350);
}

function dismissByKey(key) {
    if (!key) return;
    activeToasts()
        .filter(t => t.dataset.key === key)
        .forEach(dismiss);
}

function notify(data) {
    const kind = KINDS.includes(data.kind) ? data.kind : 'info';
    const duration = Number(data.duration) || 5000;

    dismissByKey(data.key);

    const visible = activeToasts();
    while (visible.length >= maxVisible) {
        dismiss(visible.shift());
    }

    const toast = document.createElement('div');
    toast.className = 'toast kind-' + kind;
    if (data.key) {
        toast.dataset.key = data.key;
    }

    const icon = document.createElement('div');
    icon.className = 'icon';
    icon.textContent = ICONS[kind];

    const body = document.createElement('div');
    body.className = 'body';

    const title = document.createElement('div');
    title.className = 'title';
    title.textContent = data.title || '';

    const desc = document.createElement('div');
    desc.className = 'desc';
    desc.textContent = data.description || '';

    body.append(title, desc);

    const progress = document.createElement('div');
    progress.className = 'progress';

    toast.append(icon, body, progress);
    stack.appendChild(toast);

    requestAnimationFrame(() => {
        toast.classList.add('show');
        progress.style.transitionDuration = duration + 'ms';
        progress.classList.add('run');
    });

    setTimeout(() => dismiss(toast), duration);
}

window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data) return;

    if (data.action === 'notify') {
        notify(data);
    } else if (data.action === 'dismiss') {
        dismissByKey(data.key);
    }
});

fetch(`https://${RESOURCE}/ready`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: '{}'
})
    .then(response => response.json())
    .then(applyTheme)
    .catch(() => {});
