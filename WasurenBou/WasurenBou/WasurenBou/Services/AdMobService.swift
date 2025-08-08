//
//  AdMobService.swift
//  忘れないアプリ
//
//  Created by Claude on 2025/08/07.
//

import Foundation
import SwiftUI
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

// MARK: - AdMob Banner View (Runtime-Aware)
struct AdMobBannerView: UIViewRepresentable {
    let adUnitID: String
    
    init(adUnitID: String = "ca-app-pub-3940256099942544/2934735716") {
        self.adUnitID = adUnitID
    }
    
    func makeUIView(context: Context) -> UIView {
        #if canImport(GoogleMobileAds)
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitID
        let rootVC = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
        banner.rootViewController = rootVC
        banner.load(GADRequest())
        return banner
        #else
        let view = UIView()
        view.backgroundColor = .systemGray6
        let label = UILabel()
        label.text = "広告エリア (SDK未導入)"
        label.textColor = .systemGray2
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        return view
        #endif
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - AdMob Service
class AdMobService: ObservableObject {
    static let shared = AdMobService()
    
    @Published var isAdLoaded = false
    @Published var adError: String?
    
    private init() {}
    
    func initialize() {
        #if canImport(GoogleMobileAds)
        // ATT/同意のハンドリングはアプリ側で事前に実施想定
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        print("AdMob初期化")
        #else
        print("AdMob初期化（SDK未導入）")
        #endif
    }
    
    func loadBannerAd() -> AdMobBannerView { AdMobBannerView() }
}