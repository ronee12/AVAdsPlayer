//
//  AdsPlayerView.swift
//  AVAdsPlayer
//
//  Created by Mehedi Hasan on 3/1/23.
//

import UIKit
import AVFoundation

public struct AdsInfo {
    var id: String
    var url: String
    
    public init(id: String, url: String) {
        self.id = id
        self.url = url
    }
}

public class AdsPlayerView: UIView {
    
    private lazy var container: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.cornerRadius = 10
        view.addShadowWithColor(shadowOpaciy: 0.15, color: UIColor.black.cgColor)
        return view
    }()
    
    private lazy var pausePlayView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.image = UIImage(named: "adsPause", in: Bundle.main, compatibleWith: nil)
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pausePlayTapped)))
        return imageView
    }()
    
    private lazy var replayView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.image = UIImage(named: "adsReplay")
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(replayButtonTapped)))
        return imageView
    }()
    
    @objc func replayButtonTapped() {

        replayView.isHidden = true
        currentIndex = 0

        showMedia()
    }
    
    @objc func pausePlayTapped() {
        
        guard let player = player else {
            return
        }
        
        let media = adsInfo[currentIndex]
        let time = player.currentTime().seconds
        
        if isPoused == false {
            player.pause()
            totalTimeStamp.isHidden = false
            volumeView.isHidden = false
            pausePlayView.image = UIImage(named: "adsPlay")
        } else {
            pausePlayView.image = UIImage(named: "adsPause")
            player.play()
            totalTimeStamp.isHidden = true
            //volumeView.isHidden = true
            pausePlayView.isHidden = true
        }
        
        isPoused = !isPoused
    }
    
    private lazy var totalTimeStamp: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = UIColor.white
        label.text = "00:00"
        label.isHidden = false
        label.layer.zPosition = playerView.layer.zPosition + 1
        return label
    }()
    
    private lazy var sponsoredLabel: UILabel = {
        let label = UILabel()
        label.text = "Sponsored"
        label.font = UIFont.systemFont(ofSize: 11)
        label.layer.zPosition = container.layer.zPosition + 1
        label.textColor = .white
        return label
    }()
    
    private lazy var volumeView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "volumeOn1")
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(volumeTapped)))
        imageView.layer.zPosition = playerView.layer.zPosition + 1
        return imageView
    }()
    
    public lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        return progressView
    }()
    
    private lazy var playerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.isUserInteractionEnabled = true
        view.cornerRadius = 10
        view.backgroundColor = .black
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(playerViewTapped)))
        return view
    }()
    
    private lazy var adsLoader: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .white)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var isPoused: Bool = false
    
    @objc func playerViewTapped() {
        
        if replayCount == 0 {
            totalTimeStamp.isHidden = false
            trackVisTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) {
                [weak self] _ in

                guard let self = self else {
                    return
                }
                self.totalTimeStamp.isHidden = true
            }
            return
        }
        
        pausePlayView.isHidden = false
        totalTimeStamp.isHidden = false
        volumeView.isHidden = false
        
        trackVisTimer?.invalidate()
        
        trackVisTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) {
            [weak self] _ in
            
            guard let self = self else {
                return
            }
            
            if !self.isPoused {
                self.pausePlayView.isHidden = true
                self.totalTimeStamp.isHidden = true
                //self.volumeView.isHidden = true
            }
        }
    }
    
    @objc func volumeTapped() {
        
        guard let player = player else {
            return
        }
        
        let media = adsInfo[currentIndex]
        let time = player.currentTime().seconds
        
        if player.isMuted {
            player.isMuted = false
            volumeView.image = UIImage(named: "volumeOn1")
            shouldMute = false
        } else {
            player.isMuted = true
            volumeView.image = UIImage(named: "VolumeOff1")
            shouldMute = true
        }
    }
    
    @objc func appEnterFromBackGround() {
        if let player = player {
            pausePlayView.image = UIImage(named: "adsPause")
            player.play()
            totalTimeStamp.isHidden = true
            //volumeView.isHidden = true
            pausePlayView.isHidden = true
        }
    }
    
    var playerItems: [AVPlayerItem] = []
    var lastPlayerItem: AVPlayerItem!
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    //var hnOrderTrackingStatus: HnOrderTrackingStatus?
    var adsCount:Int = 0
    public var adsInfo: [AdsInfo] = []
    var currentAds: AdsInfo!
    var currentIndex: Int = 0
    var timeObserver: Any?
    var trackVisTimer: Timer?
    var imageTimer: Timer?
    var isTimershowed: Bool = false
    var shouldMute: Bool? = nil
    var shouldReplay: Bool = false
    var replayCount: Int = 1
    var currentTotal: Double = 0.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        setupViews()
        progressView.setProgress(0, animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterFromBackGround), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        
        let media = adsInfo[currentIndex]
//        EventManager.shared.sendAdsEvent(id: media.id, title: media.title, type: .video, time: nil, eventType: .ad_end)
        self.currentIndex = self.currentIndex + 1
        self.repeatIfPossible()
        adsLoader.stopAnimating()
        if replayCount > 0 {
            player.replaceCurrentItem(with: nil)
            showMedia()
        } else {
            replayView.isHidden = false
        }
    }
    
    public func setupData(adsInfo: [AdsInfo]) {
        progressView.setProgress(0, animated: false)
        self.adsInfo = adsInfo
        print("sponsorded Data \(adsInfo)")
        showMedia()
    }
    
    private func showMedia() {
        progressView.setProgress(0, animated: false)
        imageTimer?.invalidate()
        prepareVideo()
    }
    
    private func repeatIfPossible() {
        if replayCount > 0 {
            if currentIndex == adsInfo.count {
                currentIndex = 0
                replayCount = replayCount - 1
            }
        } else {
            currentIndex = currentIndex - 1
        }
    }
    
    private func prepareVideo() {
        player = nil
        progressView.trackTintColor = UIColor.blue
        progressView.progressTintColor = UIColor.green
        
        guard let url = URL(string: adsInfo[currentIndex].url) else {
            return
        }
        //totalTimeStamp.isHidden = false
        volumeView.isHidden = false
        adsLoader.startAnimating()
        
        var fetchUrl = url
        
//        if PromoCacheManager.shared.isFileExists(urlString: adsInfo[currentIndex].url) {
//            print("Found file from local")
//            fetchUrl = PromoCacheManager.shared.directoryFor(stringUrl: url.absoluteString)
//        } else {
//            PromoCacheManager.shared.getFileWith(stringUrl: url.absoluteString) { url in
//                if url == nil {
//                    print("file did not saved")
//                } else {
//                    print("file saved")
//                }
//            }
//        }
        
        let playerItem = AVPlayerItem(url: fetchUrl)
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerView.layer.addSublayer(playerLayer)
        let xposition = container.frame.origin.x
        let yposition = container.frame.origin.y
        let totalHeight = UIScreen.main.bounds.width - 20
        let playerHeight = (totalHeight * 3) / 4
        playerLayer.frame = CGRect(x: xposition, y: yposition, width: UIScreen.main.bounds.width - 20, height: playerHeight)
        
        player.actionAtItemEnd = .none
        currentTotal = player.currentItem?.duration.seconds ?? 0
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)
        addTimeObserver()
        player.play()
        
        if player.isMuted {
            volumeView.image = UIImage(named: "VolumeOff1")
        } else {
            volumeView.image = UIImage(named: "volumeOn1")
        }
        playerView.isHidden = false
    }
    
    private func setupViews() {
        
        self.addSubview(container)
        container.anchor(top: self.topAnchor, left: self.leftAnchor, bottom: self.bottomAnchor, right: self.rightAnchor)
        
        container.addSubview(playerView)
        container.addSubview(progressView)
        playerView.addSubview(volumeView)
        playerView.addSubview(totalTimeStamp)
        playerView.addSubview(adsLoader)
        container.addSubview(pausePlayView)
        container.addSubview(replayView)
        container.addSubview(sponsoredLabel)
        
        replayView.centerX(inView: playerView)
        replayView.centerY(inView: playerView)
        replayView.setDimensions(height: 30, width: 30)
        
        pausePlayView.centerX(inView: playerView)
        pausePlayView.centerY(inView: playerView)
        pausePlayView.setDimensions(height: 50, width: 50)
        
        let totalHeight = UIScreen.main.bounds.width - 20
        let playerHeight = (totalHeight * 3) / 4
        
        playerView.anchor(top: container.topAnchor, left: container.leftAnchor, right: container.rightAnchor, height: playerHeight)
        
        adsLoader.centerXAnchor.constraint(equalTo: playerView.centerXAnchor).isActive = true
        adsLoader.centerYAnchor.constraint(equalTo: playerView.centerYAnchor).isActive = true
        
        
        volumeView.anchor(bottom: playerView.bottomAnchor, right: playerView.rightAnchor, paddingBottom: 10, paddingRight: 10, width: 20, height: 20)
        
        totalTimeStamp.anchor(left: playerView.leftAnchor, bottom: playerView.bottomAnchor, paddingLeft: 20, paddingBottom: 10, width: 50)
        
        sponsoredLabel.anchor(top: container.topAnchor, left: container.leftAnchor, paddingTop: 20, paddingLeft: 20)
        
        progressView.anchor(top: playerView.bottomAnchor, left: playerView.leftAnchor, right: playerView.rightAnchor, height: 5)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addTimeObserver() {
        let interval = CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let mainQueue = DispatchQueue.main
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue, using: {[weak self] time in
            
            guard let self = self else { return }
            guard let currentItem = self.player.currentItem else { return }
            let highest = currentItem.duration.seconds
            let current = currentItem.currentTime().seconds
            let min = Int(current / 60)
            let sec = Int(current) % 60
            
            var progress: Double = 0.0
            
            if highest.isNaN {
                progress = 0.0
            } else {
                progress = (current/highest)
                if self.isTimershowed == false {
                    self.isTimershowed = true
                    self.adsLoader.stopAnimating()
                    print(" seconds \(current) \(self.currentIndex)")
                    self.trackVisTimer = Timer.scheduledTimer(withTimeInterval: 2.2, repeats: false) {
                        [weak self] _ in

                        guard let self = self else {
                            return
                        }

                        self.totalTimeStamp.isHidden = true
                    }
                }
            }
            
            if current <= highest {
                self.totalTimeStamp.text = String(format: "%02d:%02d", min, sec)
            }
            
            self.progressView.setProgress(Float(progress), animated: true)
        })
    }

}
