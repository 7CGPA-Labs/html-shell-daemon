document.addEventListener("DOMContentLoaded", function() {
    initializeWebOSIPCBridge();
    setupSettingListeners();
    startSimulatedModemTelemetry();
    startSystemMetricsSimulation();
});

// 1. QWebChannel Host Synchronization
function initializeWebOSIPCBridge() {
    if (typeof qt !== 'undefined' && qt.webChannelTransport) {
        new QWebChannel(qt.webChannelTransport, function(channel) {
            window.sysContext = channel.objects.sysContext;
            logSystemEvent("Bridge synchronized. Unified Control linked to host daemon.");
            sysContext.logWebEvent("Settings PWA: Connection interface active.");
            
            sysContext.nativeJobProgressChanged.connect(function(jobId, progress) {
                logSystemEvent(`Background worker active: Job [${jobId}] progress: ${progress}%`);
            });
            sysContext.nativeJobFinished.connect(function(jobId, success, message) {
                logSystemEvent(`Background worker completed: Job [${jobId}] Success: ${success}. Info: ${message}`);
            });
            
            // Query host sysfs zRAM configuration settings
            loadZramMetricsFromHost();
        });
    } else {
        logSystemEvent("Standalone Mode: QWebChannel not present. Running offline simulations.");
    }
}

function loadZramMetricsFromHost() {
    if (window.sysContext) {
        sysContext.getZramDiskSize(function(size) {
            document.getElementById("zram-size-val").textContent = size;
        });
        sysContext.getZramAlgorithm(function(algo) {
            document.getElementById("zram-algo-val").textContent = algo.trim();
        });
        sysContext.getSystemSwappiness(function(swappiness) {
            document.getElementById("swappiness-val").textContent = swappiness;
        });
    }
}

// 2. Setting Event Handlers
function setupSettingListeners() {
    const dataToggle = document.getElementById("mobile-data-toggle");
    dataToggle.addEventListener("change", function() {
        const state = dataToggle.checked ? "ENABLED" : "DISABLED";
        logSystemEvent(`Mobile 4G Data set to ${state}`);
        if (window.sysContext) {
            sysContext.logWebEvent(`Settings: Changed Mobile Data State to ${state}`);
        }
    });

    const netSelect = document.getElementById("network-type-select");
    netSelect.addEventListener("change", function() {
        const mode = netSelect.value.toUpperCase();
        logSystemEvent(`Preferred Network Type changed to: ${mode}`);
        if (window.sysContext) {
            sysContext.logWebEvent(`Settings: Network Type Preference set to ${mode}`);
        }
    });
}

// Hardware slider handles
function changeBrightness(val) {
    document.getElementById("brightness-val").textContent = val + "%";
    // Direct sysfs writes simulation
    logSystemEvent(`Sysfs Brightness output -> /sys/class/backlight/brightness set to: ${val}%`);
    if (window.sysContext) {
        sysContext.logWebEvent(`Settings: sysfs backlight write -> ${val}%`);
    }
}

function changeVolume(val) {
    document.getElementById("volume-val").textContent = val + "%";
    // ALSA volume mixer adjustment
    logSystemEvent(`ALSA Sound Mixer output -> Master volume set to: ${val}%`);
    if (window.sysContext) {
        sysContext.logWebEvent(`Settings: ALSA mixer volume -> ${val}%`);
    }
}

function saveAPN() {
    const name = document.getElementById("apn-name").value;
    const address = document.getElementById("apn-address").value;
    logSystemEvent(`APN Config Updated -> Name: "${name}", APN: "${address}"`);
    if (window.sysContext) {
        sysContext.logWebEvent(`Settings: Updated APN profile to Name:${name} / APN:${address}`);
    }
}

// Power actions - Shutdown, Reboot, Powerwash
function triggerPowerAction(action) {
    const consent = confirm(`Are you sure you want to perform system action: [${action.toUpperCase()}]?`);
    if (!consent) return;

    logSystemEvent(`System Action Triggered: ${action.toUpperCase()}`);
    if (window.sysContext) {
        sysContext.logWebEvent(`Settings: Executing native power execution -> ${action}`);
        // Trigger system command directly via host bridge (e.g. shutdown -h now, reboot, or recovery boots)
        sysContext.executeSystemCommand(action);
    } else {
        logSystemEvent(`[Simulation] Host system executing: ${action}`);
    }
}

// 3. Telemetry Log and Simulation
function logSystemEvent(msg) {
    const logsBox = document.getElementById("telemetry-logs");
    if (!logsBox) return;
    
    const now = new Date();
    const timestamp = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
    
    const entry = document.createElement("div");
    entry.className = "log-entry";
    entry.innerHTML = `[${timestamp}] ${msg}`;
    logsBox.appendChild(entry);
    
    logsBox.scrollTop = logsBox.scrollHeight;
}

function startSimulatedModemTelemetry() {
    const signalDisplay = document.getElementById("ofono-signal");
    
    setInterval(function() {
        const dbs = -70 - Math.floor(Math.random() * 15);
        let quality = "Excellent";
        if (dbs < -80) quality = "Good";
        if (dbs < -83) quality = "Fair";
        signalDisplay.textContent = `${dbs} dBm (${quality})`;
    }, 8000);

    const simulatedSMS = [
        "SMS from +14155552671: 'System deployment status: OK'",
        "SMS from Carrier: 'APN profile sync succeeded.'",
        "SMS from +14155559092: 'Check out the new WebOS workspace!'",
        "SMS from System Watchdog: 'Memory compression zRAM zstd optimized.'"
    ];

    setInterval(function() {
        const randomMsg = simulatedSMS[Math.floor(Math.random() * simulatedSMS.length)];
        logSystemEvent(randomMsg);
        if (window.sysContext) {
            sysContext.logWebEvent(`Settings (oFono Simulation): ${randomMsg}`);
        }
    }, 25000);
}

// Fluctuate CPU metrics
function startSystemMetricsSimulation() {
    const cpuDisplay = document.getElementById("cpu-load");
    
    setInterval(function() {
        // CPU load fluctuations
        const load = 5 + Math.floor(Math.random() * 20);
        cpuDisplay.textContent = `${load}% Load`;
    }, 4000);
}
