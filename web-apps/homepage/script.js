document.addEventListener("DOMContentLoaded", function() {
    initializeClock();
    initializeAnodyneIPCBridge();
});

// 1. Live Momentum Clock Tracking Logic
function initializeClock() {
    const clockElement = document.getElementById("live-clock");
    const greetingElement = document.getElementById("user-greeting");

    function updateTime() {
        const now = new Date();
        clockElement.textContent = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
        
        const hour = now.getHours();
        if (hour < 12) greetingElement.textContent = "Good Morning, User";
        else if (hour < 18) greetingElement.textContent = "Good Afternoon, User";
        else greetingElement.textContent = "Good Evening, User";
    }
    
    updateTime();
    setInterval(updateTime, 1000);
}

// 2. Multithreaded IPC WebChannel Connection Management
function initializeAnodyneIPCBridge() {
    if (typeof qt !== 'undefined' && qt.webChannelTransport) {
        new QWebChannel(qt.webChannelTransport, function(channel) {
            window.sysContext = channel.objects.sysContext;
            sysContext.logWebEvent("Dashboard UI successfully integrated with Hard Layer.");

            // Bind the incoming progress telemetry stream straight to the visual progress bar components
            sysContext.nativeJobProgressChanged.connect(function(jobId, progress) {
                updateVisualTaskBar(jobId, progress);
            });

            // Bind the operation resolution alert straight to clearing out widgets
            sysContext.nativeJobFinished.connect(function(jobId, success, message) {
                completeVisualTaskBar(jobId, message);
            });
        });
    }
}

function launchApp(appKeyword) {
    if (window.sysContext) {
        sysContext.executeSystemCommand(appKeyword);
    }
}

// 3. UI Update Automation Functions
function updateVisualTaskBar(jobId, progress) {
    document.getElementById("no-tasks-msg").classList.add("hidden");
    
    const container = document.getElementById("active-task-container");
    container.classList.remove("hidden");

    document.getElementById("task-id").textContent = "ID: " + jobId;
    document.getElementById("task-percentage").textContent = progress + "% Processing Data...";
    document.getElementById("task-progress-fill").style.width = progress + "%";
}

function completeVisualTaskBar(jobId, statusMessage) {
    document.getElementById("task-percentage").textContent = "✓ Finished successfully.";
    document.getElementById("task-progress-fill").style.width = "100%";
    document.getElementById("task-progress-fill").style.backgroundColor = "#4caf50"; // Turn bar green on success

    // Retain the success notice momentarily, then fade cleanly back to empty state
    setTimeout(function() {
        document.getElementById("active-task-container").classList.add("hidden");
        
        const msg = document.getElementById("no-tasks-msg");
        msg.classList.remove("hidden");
        
        // Reset element styles back to active blue defaults
        document.getElementById("task-progress-fill").style.width = "0%";
        document.getElementById("task-progress-fill").style.backgroundColor = "#007acc";
    }, 2500);
}