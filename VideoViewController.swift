//
//  VideoViewController.swift
//  r2CamExample
//
//  Created by Tord Wessman on 2024-05-03.
//

import Foundation
import AVFoundation
import UIKit
import SwiftUI
import Combine
import r2Cam

@MainActor
class VideoViewModel: ObservableObject, VideoConnectionDelegate {

    private var videoConnection: VideoConnection

    @Published private(set) var errorMessage = ""
    @Published private(set) var isLoading = false
    @Published private(set) var isStreamRunning = false
        private var retryCount = 0
        private let maxRetries = 3

    init(_ type: VideoConnectionFactory.StreamType) {
        print("VideoViewModel: Initializing")
        triggerNetworkAuthorizationDialog()
        self.videoConnection = VideoConnectionFactory.shared.create(type)
        self.videoConnection.delegate = self
    }

    func configure(displayLayer: AVSampleBufferDisplayLayer) {

        // In order for the videoConnection to handle the rendering, we set the `displayLayer` property.
        videoConnection.displayLayer = displayLayer
    }

    func start() {
        guard !isStreamRunning else { return }  // Prevent starting if already running
        isLoading = true
        errorMessage = ""
        Task { @MainActor [weak self] in
            guard let self else { return }
            var retries = 0
            let maxRetries = 3
            while retries < maxRetries {
                do {
                    try self.videoConnection.start()
                    self.isStreamRunning = true
                    self.errorMessage = ""  // Clear error after successful start
                    break  // Exit loop on success
                } catch {
                    retries += 1
                    self.errorMessage = "Unable to connect: \(error)"
                    sleep(2)  // Wait 2 seconds before retrying
                }
            }
            if retries == maxRetries {
                self.errorMessage = "Failed to connect after multiple attempts."
            }
            self.isLoading = false
        }
    }

    func stop() {
        videoConnection.stop()
    }

    nonisolated func videoConnection(detected mediaSize: CGSize) {
        print("new media size: \(mediaSize)")
        print("VideoViewModel: Received frame size: \(mediaSize)")
    }

    nonisolated func videoConnection(error: Error) {
        Task { @MainActor [weak self] in
            self?.errorMessage = "\(error)"
        }
    }
}

struct VideoView: UIViewControllerRepresentable {

    typealias UIViewControllerType = VideoViewController

    let viewModel: VideoViewModel

    func makeUIViewController(context: Context) -> VideoViewController {
        return VideoViewController(viewModel: viewModel)
    }

    func updateUIViewController(_ uiViewController: VideoViewController, context: Context) { }
}

/// Wraps an `AVSampleBufferDisplayLayer`
class VideoViewController: UIViewController {

    private let displayLayer = AVSampleBufferDisplayLayer()
    private let viewModel: VideoViewModel
    
    init(viewModel: VideoViewModel) {
        viewModel.configure(displayLayer: displayLayer)
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.addSublayer(displayLayer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        displayLayer.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stop()
    }
}
