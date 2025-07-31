/**
 * Client-side Logging System for WhisperLiveKit
 * Provides comprehensive logging for debugging WebSocket and audio issues
 */

class ClientLogger {
    constructor() {
        this.logs = [];
        this.maxLogs = 1000;
        this.logLevel = this.getLogLevel();
        this.initializeLogger();
    }

    getLogLevel() {
        // Get log level from URL parameter or localStorage
        const urlParams = new URLSearchParams(window.location.search);
        const level = urlParams.get('log') || localStorage.getItem('whisperlivekit_log_level') || 'info';
        return level.toLowerCase();
    }

    initializeLogger() {
        // Create log container if it doesn't exist
        if (!document.getElementById('log-container')) {
            const logContainer = document.createElement('div');
            logContainer.id = 'log-container';
            logContainer.style.cssText = `
                position: fixed;
                top: 10px;
                right: 10px;
                width: 400px;
                max-height: 300px;
                background: rgba(0, 0, 0, 0.9);
                color: #fff;
                font-family: monospace;
                font-size: 11px;
                padding: 10px;
                border-radius: 5px;
                overflow-y: auto;
                z-index: 10000;
                display: none;
            `;
            document.body.appendChild(logContainer);
        }

        // Add toggle button
        if (!document.getElementById('log-toggle')) {
            const toggleBtn = document.createElement('button');
            toggleBtn.id = 'log-toggle';
            toggleBtn.textContent = '📋 Logs';
            toggleBtn.style.cssText = `
                position: fixed;
                top: 10px;
                right: 420px;
                z-index: 10001;
                padding: 5px 10px;
                background: #007bff;
                color: white;
                border: none;
                border-radius: 3px;
                cursor: pointer;
                font-size: 12px;
            `;
            toggleBtn.onclick = () => this.toggleLogs();
            document.body.appendChild(toggleBtn);
        }

        // Add clear button
        if (!document.getElementById('log-clear')) {
            const clearBtn = document.createElement('button');
            clearBtn.id = 'log-clear';
            clearBtn.textContent = '🗑️ Clear';
            clearBtn.style.cssText = `
                position: fixed;
                top: 10px;
                right: 480px;
                z-index: 10001;
                padding: 5px 10px;
                background: #dc3545;
                color: white;
                border: none;
                border-radius: 3px;
                cursor: pointer;
                font-size: 12px;
            `;
            clearBtn.onclick = () => this.clearLogs();
            document.body.appendChild(clearBtn);
        }

        this.info('ClientLogger initialized', { logLevel: this.logLevel });
    }

    shouldLog(level) {
        const levels = { 'debug': 0, 'info': 1, 'warn': 2, 'error': 3 };
        return levels[level] >= levels[this.logLevel];
    }

    formatMessage(level, message, data = null) {
        const timestamp = new Date().toISOString();
        const levelUpper = level.toUpperCase();
        let formatted = `[${timestamp}] [${levelUpper}] ${message}`;
        
        if (data) {
            if (typeof data === 'object') {
                formatted += ` | ${JSON.stringify(data, null, 2)}`;
            } else {
                formatted += ` | ${data}`;
            }
        }
        
        return formatted;
    }

    addToLogs(level, message, data) {
        const logEntry = {
            timestamp: new Date(),
            level,
            message,
            data,
            formatted: this.formatMessage(level, message, data)
        };

        this.logs.push(logEntry);
        
        // Keep only the last maxLogs entries
        if (this.logs.length > this.maxLogs) {
            this.logs = this.logs.slice(-this.maxLogs);
        }

        // Update log display
        this.updateLogDisplay();
        
        // Also log to console
        const consoleMethod = level === 'error' ? 'error' : 
                            level === 'warn' ? 'warn' : 
                            level === 'debug' ? 'debug' : 'log';
        console[consoleMethod](`[WhisperLiveKit] ${message}`, data || '');
    }

    updateLogDisplay() {
        const container = document.getElementById('log-container');
        if (!container) return;

        container.innerHTML = this.logs
            .map(log => `<div style="color: ${this.getLevelColor(log.level)};">${log.formatted}</div>`)
            .join('');
        
        container.scrollTop = container.scrollHeight;
    }

    getLevelColor(level) {
        switch (level) {
            case 'error': return '#ff6b6b';
            case 'warn': return '#ffd93d';
            case 'info': return '#6bcf7f';
            case 'debug': return '#4dabf7';
            default: return '#fff';
        }
    }

    toggleLogs() {
        const container = document.getElementById('log-container');
        if (container) {
            container.style.display = container.style.display === 'none' ? 'block' : 'none';
        }
    }

    clearLogs() {
        this.logs = [];
        this.updateLogDisplay();
        this.info('Logs cleared');
    }

    // Logging methods
    debug(message, data = null) {
        if (this.shouldLog('debug')) {
            this.addToLogs('debug', message, data);
        }
    }

    info(message, data = null) {
        if (this.shouldLog('info')) {
            this.addToLogs('info', message, data);
        }
    }

    warn(message, data = null) {
        if (this.shouldLog('warn')) {
            this.addToLogs('warn', message, data);
        }
    }

    error(message, data = null) {
        if (this.shouldLog('error')) {
            this.addToLogs('error', message, data);
        }
    }

    // Specialized logging methods
    websocket(message, data = null) {
        this.info(`[WebSocket] ${message}`, data);
    }

    audio(message, data = null) {
        this.info(`[Audio] ${message}`, data);
    }

    transcription(message, data = null) {
        this.info(`[Transcription] ${message}`, data);
    }

    // Export logs for debugging
    exportLogs() {
        const logData = {
            timestamp: new Date().toISOString(),
            userAgent: navigator.userAgent,
            url: window.location.href,
            logs: this.logs
        };
        
        const blob = new Blob([JSON.stringify(logData, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `whisperlivekit-logs-${new Date().toISOString().slice(0, 19).replace(/:/g, '-')}.json`;
        a.click();
        URL.revokeObjectURL(url);
    }

    // Performance monitoring
    time(label) {
        console.time(`[WhisperLiveKit] ${label}`);
        return label;
    }

    timeEnd(label) {
        console.timeEnd(`[WhisperLiveKit] ${label}`);
    }
}

// Create global logger instance
window.clientLogger = new ClientLogger();

// Add export function to window for easy access
window.exportLogs = () => window.clientLogger.exportLogs(); 