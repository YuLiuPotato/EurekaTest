//
//  ContentView.swift
//  r2CamExample
//
//  Created by Tord Wessman on 2024-05-02.
//
import SwiftUI
import r2Cam

struct ContentView: View {
    // IP address is hard-coded here. You should change it if you change your device. Notice that the script in raspberryPi also uses this IP address. RaspberryPi will automatically connect to this hotspot.
    @StateObject var videoViewModelH264 = VideoViewModel(.h264(host: "172.20.10.1", port: 4444))
        // Siyi: 172.20.10.8
    @Environment(\.scenePhase) private var scenePhase
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        VStack {
            Text("Microscope Camera")
                .font(.title)
                .padding()
            
            GeometryReader { geometry in
                ZStack {
                    VideoView(viewModel: videoViewModelH264)
                        .scaleEffect(zoomScale)
                        .offset(offset)
                        .frame(width: geometry.size.height * (4/3), height: geometry.size.height)
                        .rotationEffect(.degrees(90))
                        .clipped()
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        self.zoomScale = self.lastZoomScale * value
                                    }
                                    .onEnded { _ in
                                        self.lastZoomScale = self.zoomScale
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        // Swap width and height, and invert one axis
                                        self.offset = CGSize(
                                            width: self.lastOffset.width + value.translation.height,
                                            height: self.lastOffset.height - value.translation.width
                                        )
                                    }
                                    .onEnded { _ in
                                        self.lastOffset = self.offset
                                    }
                            )
                        )

                    if videoViewModelH264.isLoading {
                        ProgressView()
                    }

                    Text(videoViewModelH264.errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .aspectRatio(3/4, contentMode: .fit)
            .padding()
            
            Button(action: {
                videoViewModelH264.start()
            }) {
                Text("Start Stream")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                videoViewModelH264.start()
            case .background:
                videoViewModelH264.stop()
            default:
                break
            }
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
