document.addEventListener("DOMContentLoaded", function() {
    initializeWebOSIPCBridge();
    // Default to container rootfs view
    switchDirectory('sandbox-rootfs');
});

// 1. Host QWebChannel Synchronization
function initializeWebOSIPCBridge() {
    if (typeof qt !== 'undefined' && qt.webChannelTransport) {
        new QWebChannel(qt.webChannelTransport, function(channel) {
            window.sysContext = channel.objects.sysContext;
            sysContext.logWebEvent("Files PWA: Channel bridge synchronized.");

            // Connect asynchronous job progress streams
            sysContext.nativeJobProgressChanged.connect(function(jobId, progress) {
                updateFooterTaskBar(jobId, progress);
            });

            // Connect final completion notifications
            sysContext.nativeJobFinished.connect(function(jobId, success, message) {
                completeFooterTaskBar(jobId, success, message);
            });
        });
    }
}

// 2. Directory Navigation Engine (Mocking namespaces)
const fileSystemData = {
    'system-root': {
        path: '/',
        items: [
            { name: 'bin', type: 'Directory', size: '--', perms: 'drwxr-xr-x' },
            { name: 'boot', type: 'Directory', size: '--', perms: 'drwxr-xr-x' },
            { name: 'etc', type: 'Directory', size: '--', perms: 'drwxr-xr-x' },
            { name: 'lib', type: 'Directory', size: '--', perms: 'drwxr-xr-x' },
            { name: 'var', type: 'Directory', size: '--', perms: 'drwxr-xr-x' },
            { name: 'initrd.img', type: 'File', size: '28.4 MB', perms: '-rw-r--r--' },
            { name: 'vmlinuz', type: 'File', size: '8.2 MB', perms: '-rw-r--r--' }
        ]
    },
    'user-home': {
        path: '/home/user/',
        items: [
            { name: 'Downloads', type: 'Directory', size: '--', perms: 'drwxr-xr-x' },
            { name: 'Documents', type: 'Directory', size: '--', perms: 'drwxr-xr-x' },
            { name: 'Pictures', type: 'Directory', size: '--', perms: 'drwxr-xr-x' },
            { name: '.config', type: 'Directory', size: '--', perms: 'drwx------' },
            { name: 'welcome.txt', type: 'File', size: '1.2 KB', perms: '-rw-r--r--' }
        ]
    },
    'sandbox-rootfs': {
        path: '/var/lib/webos/rootfs/',
        items: [
            { name: 'src', type: 'Directory', size: '--', perms: 'drwxr-xr-x' },
            { name: 'ui', type: 'Directory', size: '--', perms: 'drwxr-xr-x' },
            { name: 'web-apps', type: 'Directory', size: '--', perms: 'drwxr-xr-x' },
            { name: 'main.cpp', type: 'C++ Source', size: '1.9 KB', perms: '-rw-r--r--' },
            { name: 'WebOSAppliance.pro', type: 'Project config', size: '837 B', perms: '-rw-r--r--' },
            { name: 'LICENSE', type: 'License file', size: '35.8 KB', perms: '-rw-r--r--' },
            { name: 'README.md', type: 'Markdown doc', size: '5.8 KB', perms: '-rw-r--r--' }
        ]
    },
    'external-usb': {
        path: '/media/usb/backup/',
        items: [
            { name: 'SystemBackup_2026.tar.gz', type: 'Compressed Archive', size: '142.6 MB', perms: '-rw-r--r--' }
        ]
    }
};

function switchDirectory(key) {
    const data = fileSystemData[key];
    if (!data) return;

    // Update path label
    document.getElementById("current-path").textContent = data.path;

    // Update Sidebar visual highlights
    const listItems = document.querySelectorAll(".drive-list li");
    listItems.forEach(li => li.classList.remove("active"));
    
    // Find the clicked item
    event.currentTarget.classList.add("active");

    // Populate file table rows
    const tbody = document.getElementById("files-list-body");
    tbody.innerHTML = "";

    data.items.forEach(item => {
        const tr = document.createElement("tr");
        if (item.type === 'Directory') {
            tr.className = 'folder';
        }
        
        tr.innerHTML = `
            <td>${item.type === 'Directory' ? '📁' : '📄'} ${item.name}</td>
            <td>${item.type}</td>
            <td>${item.size}</td>
            <td><code>${item.perms}</code></td>
        `;
        tbody.appendChild(tr);
    });
}

// 3. Asynchronous Job Trigger
function triggerBackupJob() {
    if (window.sysContext) {
        // executeSystemCommand("files") triggers the background copy worker in C++
        sysContext.executeSystemCommand("files");
    } else {
        alert("Standalone Mode: QWebChannel not connected. Cannot start C++ worker.");
    }
}

// 4. Telemetry UI Updates
function updateFooterTaskBar(jobId, progress) {
    const footer = document.getElementById("files-telemetry-footer");
    footer.classList.remove("hidden");

    document.getElementById("footer-job-id").textContent = "ID: " + jobId;
    document.getElementById("footer-percentage-text").textContent = progress + "% Completed";
    document.getElementById("footer-progress-fill").style.width = progress + "%";
    document.getElementById("footer-status-msg").textContent = "Writing file blocks asynchronously...";
}

function completeFooterTaskBar(jobId, success, message) {
    document.getElementById("footer-percentage-text").textContent = "✓ Finished";
    document.getElementById("footer-status-msg").textContent = message;
    
    const progressFill = document.getElementById("footer-progress-fill");
    progressFill.style.width = "100%";
    progressFill.style.backgroundColor = "#4caf50";

    // Wait and then slide the footer out of view
    setTimeout(function() {
        document.getElementById("files-telemetry-footer").classList.add("hidden");
        // Reset styling
        progressFill.style.width = "0%";
        progressFill.style.backgroundColor = "#007acc";
    }, 3000);
}
