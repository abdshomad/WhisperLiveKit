/**
 * WhisperLiveKit Main JavaScript
 * Handles WebSocket connections, audio recording, and UI interactions
 */

class WhisperLiveKit {
    constructor() {
        this.websocket = null;
        this.mediaRecorder = null;
        this.audioContext = null;
        this.isRecording = false;
        this.isConnected = false;
        this.chunkSize = 500;
        this.transcriptionText = '';
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 3;
        this.reconnectDelay = 1000; // 1 second
        
        // Initialize logger
        this.logger = window.clientLogger || console;
        
        this.initializeElements();
        this.bindEvents();
        this.initializeUI();
        // AudioContext will be created only when user clicks record button
        // This prevents the "AudioContext was not allowed to start" error
    }

    initializeElements() {
        // Status elements
        this.connectionStatus = document.getElementById('connection-status');
        this.connectionText = document.getElementById('connection-text');
        this.recordingStatus = document.getElementById('recording-status');
        this.recordingText = document.getElementById('recording-text');
        
        // Control elements
        this.recordBtn = document.getElementById('record-btn');
        this.stopBtn = document.getElementById('stop-btn');
        this.clearBtn = document.getElementById('clear-btn');
        this.chunkSizeSlider = document.getElementById('chunk-size');
        this.chunkSizeValue = document.getElementById('chunk-size-value');
        
        // Transcription elements
        this.transcriptionContainer = document.getElementById('transcription-container');
        this.transcriptionText = document.getElementById('transcription-text');
        
        // Settings elements
        this.languageSelect = document.getElementById('language-select');
        this.taskSelect = document.getElementById('task-select');
        this.modelSelect = document.getElementById('model-select');
    }

    bindEvents() {
        // Recording controls
        this.recordBtn.addEventListener('click', () => this.toggleRecording());
        this.stopBtn.addEventListener('click', () => this.stopRecording());
        this.clearBtn.addEventListener('click', () => this.clearTranscription());
        
        // Chunk size slider
        this.chunkSizeSlider.addEventListener('input', (e) => {
            this.chunkSize = parseInt(e.target.value);
            this.chunkSizeValue.textContent = `${this.chunkSize}ms`;
        });
        
        // Settings changes
        this.languageSelect.addEventListener('change', () => this.updateSettings());
        this.taskSelect.addEventListener('change', () => this.updateSettings());
        this.modelSelect.addEventListener('change', () => this.updateSettings());
        
        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if (e.code === 'Space' && e.target.tagName !== 'INPUT') {
                e.preventDefault();
                this.toggleRecording();
            }
        });
    }

    initializeUI() {
        // Set initial transcription message
        this.transcriptionText.innerHTML = '<div class="text-gray-400 italic">Click "Start Recording" to begin transcription...</div>';
        
        // Initialize connection status
        this.updateConnectionStatus(false);
        this.updateRecordingStatus(false);
        
        // Show initial toast
        this.showToast('Ready to record! Click the microphone button to start.', 'info');
    }

    async initializeAudio() {
        this.logger.audio('Initializing audio context');
        try {
            this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
            
            // Check if AudioContext is suspended and needs user interaction
            if (this.audioContext.state === 'suspended') {
                this.logger.audio('AudioContext is suspended, waiting for user interaction');
                // We'll resume it when the user clicks the record button
                return;
            }
            
            await this.audioContext.resume();
            this.logger.audio('Audio context initialized successfully', { 
                sampleRate: this.audioContext.sampleRate,
                state: this.audioContext.state 
            });
        } catch (error) {
            this.logger.error('Failed to initialize audio context', { error: error.message });
            this.showToast('Audio initialization failed. Please try clicking the record button again.', 'error');
            throw error; // Re-throw to be handled by startRecording
        }
    }

    async connectWebSocket() {
        if (this.websocket && this.websocket.readyState === WebSocket.OPEN) {
            this.logger.websocket('WebSocket already connected, skipping connection attempt');
            return;
        }

        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/ws/asr`;
        
        this.logger.websocket('Attempting to connect', { url: wsUrl, protocol });
        
        try {
            this.websocket = new WebSocket(wsUrl);
            
            this.websocket.onopen = () => {
                this.logger.websocket('Connection established successfully');
                this.isConnected = true;
                this.reconnectAttempts = 0; // Reset reconnection attempts on successful connection
                this.updateConnectionStatus(true);
                this.showToast('Connected to server', 'success');
            };
            
            this.websocket.onmessage = (event) => {
                this.logger.websocket('Message received', { 
                    dataLength: event.data.length,
                    dataType: typeof event.data 
                });
                this.handleWebSocketMessage(event.data);
            };
            
            this.websocket.onclose = (event) => {
                this.logger.websocket('Connection closed', { 
                    code: event.code, 
                    reason: event.reason,
                    wasClean: event.wasClean 
                });
                this.isConnected = false;
                this.updateConnectionStatus(false);
                this.stopRecording();
                
                // Show appropriate message based on close code
                if (event.code === 1008) {
                    this.logger.error('Server error: Transcription engine not initialized');
                    this.showToast('Server error: Transcription engine not initialized', 'error');
                } else if (event.code === 1000) {
                    this.logger.websocket('Connection closed normally');
                    this.showToast('Connection closed normally', 'info');
                } else {
                    this.logger.warn('Connection closed unexpectedly', { code: event.code });
                    this.showToast('Disconnected from server', 'warning');
                    
                    // Attempt to reconnect if not a normal close
                    if (event.code !== 1000 && this.reconnectAttempts < this.maxReconnectAttempts) {
                        this.reconnectAttempts++;
                        this.logger.websocket('Attempting reconnection', { 
                            attempt: this.reconnectAttempts, 
                            maxAttempts: this.maxReconnectAttempts 
                        });
                        this.showToast(`Attempting to reconnect (${this.reconnectAttempts}/${this.maxReconnectAttempts})...`, 'info');
                        setTimeout(() => {
                            this.connectWebSocket();
                        }, this.reconnectDelay * this.reconnectAttempts);
                    } else if (this.reconnectAttempts >= this.maxReconnectAttempts) {
                        this.logger.error('Max reconnection attempts reached');
                        this.showToast('Max reconnection attempts reached. Please refresh the page.', 'error');
                    }
                }
            };
            
            this.websocket.onerror = (error) => {
                this.logger.error('WebSocket error occurred', { error });
                this.isConnected = false;
                this.updateConnectionStatus(false);
                this.showToast('Connection error', 'error');
            };
            
        } catch (error) {
            this.logger.error('Failed to create WebSocket connection', { error: error.message });
            this.isConnected = false;
            this.updateConnectionStatus(false);
            this.showToast('Failed to connect', 'error');
        }
    }

    handleWebSocketMessage(data) {
        this.logger.websocket('📥 PROCESSING WEBSOCKET MESSAGE', { 
            dataLength: data.length,
            dataType: typeof data,
            isRecording: this.isRecording,
            recordingDuration: this.isRecording && this.recordingStartTime ? Date.now() - this.recordingStartTime : null
        });
        
        try {
            const message = JSON.parse(data);
            this.logger.websocket('📥 MESSAGE PARSED SUCCESSFULLY', { 
                messageType: message.type || 'N/A',
                messageStatus: message.status || 'N/A',
                hasLines: !!message.lines,
                linesCount: message.lines ? message.lines.length : 0,
                hasBufferTranscription: !!message.buffer_transcription,
                hasBufferDiarization: !!message.buffer_diarization,
                isRecording: this.isRecording
            });
            
            // Handle the actual message structure from the server
            if (message.status === 'active_transcription' || message.status === 'no_audio_detected') {
                this.logger.transcription('📝 PROCESSING TRANSCRIPTION MESSAGE', { 
                    status: message.status,
                    isRecording: this.isRecording,
                    recordingDuration: this.isRecording && this.recordingStartTime ? Date.now() - this.recordingStartTime : null
                });
                // Update transcription with the lines and buffer information
                this.updateTranscriptionFromServer(message);
            } else if (message.status === 'error') {
                this.logger.error('❌ SERVER ERROR MESSAGE RECEIVED', { 
                    error: message.error,
                    isRecording: this.isRecording
                });
                this.showToast(`Server error: ${message.error}`, 'error');
            } else if (message.type === 'ready_to_stop') {
                this.logger.websocket('✅ READY TO STOP MESSAGE RECEIVED', {
                    isRecording: this.isRecording,
                    recordingDuration: this.isRecording && this.recordingStartTime ? Date.now() - this.recordingStartTime : null
                });
                this.showToast('Transcription completed', 'success');
            } else {
                // Log the message for debugging but don't show as error
                this.logger.debug('📥 RECEIVED MESSAGE', { 
                    message,
                    isRecording: this.isRecording
                });
            }
        } catch (error) {
            this.logger.error('❌ FAILED TO PARSE WEBSOCKET MESSAGE', { 
                error: error.message,
                data: data.substring(0, 200), // Log first 200 chars of raw data
                isRecording: this.isRecording
            });
        }
    }

    updateTranscriptionFromServer(message) {
        const { lines = [], buffer_transcription = '', buffer_diarization = '' } = message;
        
        // Clear existing transcription if this is a new session
        if (lines.length === 0 && !buffer_transcription && !buffer_diarization) {
            return;
        }
        
        // Build the transcription text from lines and buffers
        let transcriptionText = '';
        
        // Add lines with speaker information
        lines.forEach(line => {
            if (line.text && line.text.trim()) {
                const speakerLabel = line.speaker > 0 ? `Speaker ${line.speaker}: ` : '';
                transcriptionText += `${speakerLabel}${line.text}\n`;
            }
        });
        
        // Add buffer transcription if available
        if (buffer_transcription && buffer_transcription.trim()) {
            transcriptionText += `${buffer_transcription}\n`;
        }
        
        // Add buffer diarization if available
        if (buffer_diarization && buffer_diarization.trim()) {
            transcriptionText += `${buffer_diarization}\n`;
        }
        
        if (transcriptionText.trim()) {
            // Replace the entire transcription content for real-time updates
            this.transcriptionText.innerHTML = '';
            const segment = document.createElement('div');
            segment.className = 'transcription-segment final';
            segment.textContent = transcriptionText.trim();
            this.transcriptionText.appendChild(segment);
            
            // Auto-scroll to bottom
            this.transcriptionContainer.scrollTop = this.transcriptionContainer.scrollHeight;
        }
    }

    updateTranscription(text, isFinal) {
        if (!text || text.trim() === '') return;
        
        const segment = document.createElement('div');
        segment.className = `transcription-segment ${isFinal ? 'final' : 'interim'}`;
        segment.textContent = text;
        
        if (isFinal) {
            // Remove any interim segments
            const interimSegments = this.transcriptionText.querySelectorAll('.interim');
            interimSegments.forEach(seg => seg.remove());
            
            // Add final segment
            this.transcriptionText.appendChild(segment);
        } else {
            // Replace or add interim segment
            const existingInterim = this.transcriptionText.querySelector('.interim');
            if (existingInterim) {
                existingInterim.replaceWith(segment);
            } else {
                this.transcriptionText.appendChild(segment);
            }
        }
        
        // Auto-scroll to bottom
        this.transcriptionContainer.scrollTop = this.transcriptionContainer.scrollHeight;
    }

    async toggleRecording() {
        if (this.isRecording) {
            this.stopRecording();
        } else {
            this.startRecording();
        }
    }

    async startRecording() {
        if (this.isRecording) {
            this.logger.audio('Recording already in progress, ignoring start request');
            return;
        }
        
        this.logger.audio('🎤 START RECORDING - User clicked record button');
        this.recordingStartTime = Date.now();
        this.audioChunkCount = 0;
        this.totalBytesSent = 0;
        
        try {
            // Initialize audio context on first user interaction
            if (!this.audioContext) {
                this.logger.audio('Initializing audio context on first user interaction');
                await this.initializeAudio();
            }
            
            // Resume AudioContext if it's suspended (required for user interaction)
            if (this.audioContext && this.audioContext.state === 'suspended') {
                this.logger.audio('Resuming suspended AudioContext');
                await this.audioContext.resume();
                this.logger.audio('AudioContext resumed successfully', { state: this.audioContext.state });
            }
            
            // Connect WebSocket if not connected
            if (!this.isConnected) {
                this.logger.audio('Connecting WebSocket before starting recording');
                await this.connectWebSocket();
            }
            
            // Get audio stream
            this.logger.audio('🎤 REQUESTING MICROPHONE ACCESS');
            const stream = await navigator.mediaDevices.getUserMedia({ 
                audio: {
                    sampleRate: 16000,
                    channelCount: 1,
                    echoCancellation: true,
                    noiseSuppression: true,
                    autoGainControl: true
                } 
            });
            
            this.logger.audio('🎤 MICROPHONE ACCESS GRANTED', { 
                trackCount: stream.getTracks().length,
                audioTrack: stream.getAudioTracks()[0]?.label || 'Unknown'
            });
            
            // Create MediaRecorder
            this.mediaRecorder = new MediaRecorder(stream, {
                mimeType: 'audio/webm;codecs=opus'
            });
            
            let audioChunks = [];
            
            this.mediaRecorder.ondataavailable = (event) => {
                if (event.data.size > 0) {
                    audioChunks.push(event.data);
                    this.audioChunkCount++;
                    this.logger.audio('🎤 RECEIVED SOUND CHUNK', { 
                        chunkNumber: this.audioChunkCount,
                        chunkSize: event.data.size,
                        totalChunks: audioChunks.length,
                        timestamp: Date.now() - this.recordingStartTime
                    });
                }
            };
            
            this.mediaRecorder.onstop = async () => {
                const recordingDuration = Date.now() - this.recordingStartTime;
                this.logger.audio('🎤 END RECORDING - MediaRecorder stopped', { 
                    totalChunks: audioChunks.length,
                    totalChunkCount: this.audioChunkCount,
                    totalBytesSent: this.totalBytesSent,
                    recordingDuration: recordingDuration,
                    averageChunkSize: this.totalBytesSent / this.audioChunkCount
                });
                
                if (audioChunks.length > 0) {
                    const audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
                    this.logger.audio('🎤 SENDING FINAL AUDIO DATA', { 
                        blobSize: audioBlob.size,
                        mimeType: audioBlob.type 
                    });
                    await this.sendAudioData(audioBlob);
                    audioChunks = [];
                }
            };
            
            // Start recording with specified chunk size
            this.mediaRecorder.start(this.chunkSize);
            this.isRecording = true;
            this.updateRecordingStatus(true);
            this.logger.audio('🎤 RECORDING STARTED SUCCESSFULLY', { 
                chunkSize: this.chunkSize,
                startTime: this.recordingStartTime
            });
            this.showToast('Recording started', 'success');
            
        } catch (error) {
            const recordingDuration = this.recordingStartTime ? Date.now() - this.recordingStartTime : 0;
            this.logger.error('🎤 RECORDING FAILED', { 
                error: error.message,
                recordingDuration: recordingDuration,
                chunksProcessed: this.audioChunkCount,
                bytesSent: this.totalBytesSent
            });
            
            if (error.name === 'NotAllowedError') {
                this.logger.error('Microphone access denied by user');
                this.showToast('Microphone access denied. Please allow microphone permissions and try again.', 'error');
            } else if (error.message && error.message.includes('AudioContext')) {
                this.logger.error('AudioContext error during recording start');
                this.showToast('Audio initialization failed. Please try clicking the record button again.', 'error');
            } else {
                this.logger.error('Unknown error during recording start');
                this.showToast('Failed to start recording. Please try again.', 'error');
            }
        }
    }

    stopRecording() {
        if (!this.isRecording) {
            this.logger.audio('Stop recording called but not currently recording');
            return;
        }
        
        const recordingDuration = this.recordingStartTime ? Date.now() - this.recordingStartTime : 0;
        this.logger.audio('🎤 STOP RECORDING - User clicked stop button', {
            recordingDuration: recordingDuration,
            totalChunks: this.audioChunkCount,
            totalBytesSent: this.totalBytesSent,
            averageBytesPerChunk: this.totalBytesSent / this.audioChunkCount
        });
        
        if (this.mediaRecorder && this.mediaRecorder.state !== 'inactive') {
            this.logger.audio('🎤 STOPPING MEDIARECORDER');
            this.mediaRecorder.stop();
        }
        
        if (this.mediaRecorder && this.mediaRecorder.stream) {
            this.logger.audio('🎤 STOPPING AUDIO STREAM TRACKS');
            this.mediaRecorder.stream.getTracks().forEach(track => {
                this.logger.audio('🎤 STOPPING TRACK', { 
                    trackKind: track.kind,
                    trackLabel: track.label,
                    trackEnabled: track.enabled
                });
                track.stop();
            });
        }
        
        this.isRecording = false;
        this.updateRecordingStatus(false);
        this.logger.audio('🎤 RECORDING STOPPED SUCCESSFULLY', {
            finalDuration: recordingDuration,
            finalChunkCount: this.audioChunkCount,
            finalBytesSent: this.totalBytesSent
        });
        this.showToast('Recording stopped', 'warning');
    }

    async sendAudioData(audioBlob) {
        if (!this.websocket || this.websocket.readyState !== WebSocket.OPEN) {
            this.logger.error('Cannot send audio data: WebSocket not connected', { 
                websocketExists: !!this.websocket,
                readyState: this.websocket ? this.websocket.readyState : 'N/A'
            });
            return;
        }
        
        this.logger.audio('📤 PREPARING TO SEND AUDIO CHUNK', { 
            blobSize: audioBlob.size,
            mimeType: audioBlob.type,
            websocketReadyState: this.websocket.readyState,
            chunkNumber: this.audioChunkCount,
            totalBytesSent: this.totalBytesSent
        });
        
        try {
            // Convert audio blob to array buffer
            const arrayBuffer = await audioBlob.arrayBuffer();
            this.logger.audio('📤 AUDIO BLOB CONVERTED TO ARRAYBUFFER', { 
                originalSize: audioBlob.size,
                arrayBufferSize: arrayBuffer.byteLength,
                conversionRatio: arrayBuffer.byteLength / audioBlob.size
            });
            
            this.websocket.send(arrayBuffer);
            this.totalBytesSent += arrayBuffer.byteLength;
            
            this.logger.audio('📤 AUDIO CHUNK SENT SUCCESSFULLY', { 
                bytesSent: arrayBuffer.byteLength,
                totalBytesSent: this.totalBytesSent,
                chunkNumber: this.audioChunkCount,
                timestamp: Date.now() - this.recordingStartTime,
                averageBytesPerChunk: this.totalBytesSent / this.audioChunkCount
            });
        } catch (error) {
            this.logger.error('📤 FAILED TO SEND AUDIO CHUNK', { 
                error: error.message,
                blobSize: audioBlob.size,
                chunkNumber: this.audioChunkCount,
                totalBytesSent: this.totalBytesSent
            });
        }
    }

    updateConnectionStatus(connected) {
        this.connectionStatus.className = `w-3 h-3 rounded-full ${connected ? 'status-connected' : 'status-disconnected'}`;
        this.connectionText.textContent = connected ? 'Connected' : 'Disconnected';
    }

    updateRecordingStatus(recording) {
        this.recordingStatus.className = `w-3 h-3 rounded-full ${recording ? 'status-recording recording-pulse' : 'status-not-recording'}`;
        this.recordingText.textContent = recording ? 'Recording' : 'Not Recording';
        
        // Update button visibility
        this.recordBtn.classList.toggle('hidden', recording);
        this.stopBtn.classList.toggle('hidden', !recording);
    }

    clearTranscription() {
        this.transcriptionText.innerHTML = '<div class="text-gray-400 italic">Click "Start Recording" to begin transcription...</div>';
        this.showToast('Transcription cleared', 'success');
    }

    updateSettings() {
        const settings = {
            language: this.languageSelect.value,
            task: this.taskSelect.value,
            model: this.modelSelect.value
        };
        
        console.log('Settings updated:', settings);
        this.showToast('Settings updated', 'success');
    }

    showToast(message, type = 'info') {
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.textContent = message;
        
        document.body.appendChild(toast);
        
        // Remove toast after 3 seconds
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 3000);
    }
}

// Initialize the application when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.whisperLiveKit = new WhisperLiveKit();
});

// Handle page visibility changes
document.addEventListener('visibilitychange', () => {
    if (document.hidden && window.whisperLiveKit && window.whisperLiveKit.isRecording) {
        window.whisperLiveKit.stopRecording();
    }
});

// Handle beforeunload to clean up
window.addEventListener('beforeunload', () => {
    if (window.whisperLiveKit) {
        window.whisperLiveKit.stopRecording();
    }
}); 