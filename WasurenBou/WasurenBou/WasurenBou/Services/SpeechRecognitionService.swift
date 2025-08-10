//
//  SpeechRecognitionService.swift
//  WasurenBou
//
//  Created by Claude on 2025/08/06.
//

import Foundation
import Speech
import AVFoundation
import SwiftUI

@MainActor
class SpeechRecognitionService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isRecording = false
    @Published var transcription = ""
    @Published var isAuthorized = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @AppStorage("speechLanguage") private var speechLanguage = "auto"
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupSpeechRecognizer()
    }
    
    private func setupSpeechRecognizer() {
        // 選択された言語で音声認識を設定
        let localeIdentifier: String
        switch speechLanguage {
        case "en-US":
            localeIdentifier = "en-US"
        case "ja-JP":
            localeIdentifier = "ja-JP"
        case "auto":
            // システムの言語を使用
            localeIdentifier = Locale.current.languageCode == "ja" ? "ja-JP" : "en-US"
        default:
            localeIdentifier = "en-US"
        }
        
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
        speechRecognizer?.delegate = self
        
        // 権限状態を確認
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
        updateAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestSpeechAuthorization() async {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
                Task { @MainActor in
                    self?.authorizationStatus = authStatus
                    self?.updateAuthorizationStatus()
                    continuation.resume()
                }
            }
        }
    }
    
    private func requestMicrophoneAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    private func updateAuthorizationStatus() {
        switch authorizationStatus {
        case .authorized:
            isAuthorized = true
        case .denied:
            isAuthorized = false
        case .restricted:
            isAuthorized = false
        case .notDetermined:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
    
    // MARK: - Recording Control
    
    func startRecording() async {
        // 既存の録音を停止
        if isRecording {
            stopRecording()
            return
        }
        
        // 権限確認
        if !isAuthorized {
            await requestSpeechAuthorization()
        }
        
        guard isAuthorized else {
            return
        }
        
        // マイクの権限確認
        let micAuthorized = await requestMicrophoneAuthorization()
        guard micAuthorized else {
            return
        }
        
        do {
            try await startSpeechRecognition()
        } catch {
        }
    }
    
    private func startSpeechRecognition() async throws {
        // 既存のタスクをキャンセル
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // オーディオセッションを設定
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // 認識リクエストを作成
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.recognitionRequestCreationFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // オンデバイス認識を有効にする（iOS 13以降）
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        // オーディオエンジンの入力ノードを取得
        let inputNode = audioEngine.inputNode
        
        // 認識タスクを開始
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                var isFinal = false
                
                if let result = result {
                    self.transcription = result.bestTranscription.formattedString
                    isFinal = result.isFinal
                }
                
                if error != nil || isFinal {
                    self.stopRecording()
                }
            }
        }
        
        // オーディオフォーマットを設定
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // オーディオエンジンを開始
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        transcription = ""
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
    }
    
    // MARK: - Text Processing
    
    func processTranscription() -> String {
        // 音声認識結果をクリーンアップ
        let cleanText = transcription
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "。", with: "")
            .replacingOccurrences(of: "、", with: "")
            .replacingOccurrences(of: "！", with: "")
            .replacingOccurrences(of: "？", with: "")
            .replacingOccurrences(of: "ー", with: "")
        
        // 音声認識で間違いやすい表現を修正
        let correctedText = cleanText
            .replacingOccurrences(of: "薬飲む", with: "薬を飲む")
            .replacingOccurrences(of: "買い物", with: "買い物する")
            .replacingOccurrences(of: "洗濯", with: "洗濯物を取り込む")
            .replacingOccurrences(of: "ゴミ", with: "ゴミ出し")
            .replacingOccurrences(of: "電話", with: "電話をかける")
            .replacingOccurrences(of: "お母さんに電話", with: "母に電話")
            .replacingOccurrences(of: "ミルク買う", with: "牛乳を買う")
            .replacingOccurrences(of: "ミルク", with: "牛乳")
        
        return correctedText.isEmpty ? "音声を認識できませんでした" : correctedText
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension SpeechRecognitionService: SFSpeechRecognizerDelegate {
    
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            if available {
            } else {
                isAuthorized = false
            }
        }
    }
}

// MARK: - Error Types

enum SpeechError: Error {
    case recognitionRequestCreationFailed
    case audioEngineStartFailed
    case authorizationDenied
    
    var localizedDescription: String {
        switch self {
        case .recognitionRequestCreationFailed:
            return "音声認識リクエストの作成に失敗しました"
        case .audioEngineStartFailed:
            return "オーディオエンジンの開始に失敗しました"
        case .authorizationDenied:
            return "音声認識の権限が拒否されました"
        }
    }
}