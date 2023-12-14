//
//  ViewController.swift
//  MusicRemote
//
//  Created by PhuongDo on 14/12/2023.
//


import UIKit
import AVFoundation
import Network

class ViewController: UIViewController {

    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var loopButton: UIButton!
    @IBOutlet weak var speedButton: UIButton!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var updateTimer: Timer?
    private var pathMonitor: NWPathMonitor?

    var isLooping: Bool = false
    var speeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    var selectedSpeed: Float = 1.0

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNetworkMonitoring()

        if let audioURL = URL(string: "http://palestine.procyoni.com/public/file/fast/dbafec6d-3d73-4928-b0a9-4a7cc42d0187.mp3") {
            playerItem = AVPlayerItem(url: audioURL)
            player = AVPlayer(playerItem: playerItem)

            if player != nil {
                let duration = CMTimeGetSeconds(playerItem!.asset.duration)
                timeSlider.maximumValue = Float(duration)
                addTimeObserver()
            }

            print("Audio player initialized successfully.")
        } else {
            print("Audio URL is invalid.")
        }

        timeSlider.minimumValue = 0
        timeSlider.value = 0
        timeSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        startUpdateTimer()
    }

    func setupNetworkMonitoring() {
        pathMonitor = NWPathMonitor()
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self?.showPlayButton()
                } else {
                    self?.hidePlayButton()
                    self?.showNetworkAlert()
                }
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitorQueue")
        pathMonitor?.start(queue: queue)
    }

    func showPlayButton() {
        playPauseButton.isHidden = false
        activityIndicator.stopAnimating()
    }

    func hidePlayButton() {
        playPauseButton.isHidden = true
        activityIndicator.startAnimating()
    }

    func showNetworkAlert() {
        let alertController = UIAlertController(title: "No Network Connection", message: "Please check your internet connection.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
            self?.showPlayButton()
        })
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func playPauseButtonTapped(_ sender: UIButton) {
        if let player = player {
            if player.rate == 0 {
                if let pathMonitor = self.pathMonitor, pathMonitor.currentPath.status == .satisfied {
                    player.play()
                    updatePlayPauseButton(imageName: "pause.fill")
                } else {
                    showNetworkAlert()
                }
            } else {
                player.pause()
                updatePlayPauseButton(imageName: "play.fill")
            }
        }
    }

    @objc func handlePlayerItemDidPlayToEndTimeNotification(_ notification: Notification) {
        if let player = player {
            if isLooping {
                player.seek(to: .zero)
                player.play()
            } else {
                player.pause()
                player.seek(to: .zero)
                updatePlayPauseButton(imageName: "play.fill")
                updateSlider()
                stopUpdateTimer()
            }
        }
    }

    @IBAction func stopButtonTapped(_ sender: UIButton) {
        if let player = player {
            player.pause()
            player.seek(to: .zero)
            updatePlayPauseButton(imageName: "play.fill")
            speedButton.setTitle("1.0x", for: .normal)
        }
    }

    @IBAction func loopButtonTapped(_ sender: UIButton) {
        isLooping.toggle()
        let buttonText = isLooping ? "Looping" : "Normal"
        loopButton.setTitle(buttonText, for: .normal)

        if let player = player {
            player.actionAtItemEnd = isLooping ? .none : .pause
        }
    }

    @IBAction func speedButtonTapped(_ sender: UIButton) {
        showSpeedAlert()
    }

    func showSpeedAlert() {
        let alertController = UIAlertController(title: "Choose Speed", message: nil, preferredStyle: .actionSheet)

        for speed in speeds {
            let action = UIAlertAction(title: "\(speed)x", style: .default) { [weak self] _ in
                self?.selectedSpeed = speed
                self?.player?.rate = speed
                self?.updateSpeedButton()
            }
            alertController.addAction(action)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    @objc func sliderValueChanged(_ sender: UISlider) {
        if let player = player {
            let seconds = Double(sender.value)
            let targetTime = CMTimeMakeWithSeconds(seconds, preferredTimescale: player.currentTime().timescale)
            player.seek(to: targetTime)
        }
    }

    func addTimeObserver() {
        if let player = player {
            let timeScale = playerItem?.asset.duration.timescale ?? CMTimeScale(NSEC_PER_SEC)
            let time = CMTime(seconds: 1, preferredTimescale: timeScale)
            timeObserver = player.addPeriodicTimeObserver(forInterval: time, queue: DispatchQueue.main) { [weak self] time in
                self?.updateSlider()
            }
        }
    }

    @objc func updateSlider() {
        if let player = player {
            let currentTime = CMTimeGetSeconds(player.currentTime())
            timeSlider.value = Float(currentTime)
        }
    }

    func startUpdateTimer() {
        if updateTimer == nil {
            updateTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)
        }
    }

    func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    func updatePlayPauseButton(imageName: String) {
        playPauseButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    func updateSpeedButton() {
        speedButton.setTitle("\(selectedSpeed)x", for: .normal)
    }

    deinit {
        stopUpdateTimer()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
}
