//
//  ViewController.swift
//  MusicLocal
//
//  Created by PhuongDo on 14/12/2023.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate {

    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var loopButton: UIButton!
    @IBOutlet weak var speedButton: UIButton!
    @IBOutlet weak var timeSlider: UISlider!

    private var audioPlayer: AVAudioPlayer?
    private var updateTimer: Timer?
    var isLooping: Bool = false
    var speeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    var selectedSpeed: Float = 1.0

    override func viewDidLoad() {
        super.viewDidLoad()

        if let audioPath = Bundle.main.path(forResource: "sample", ofType: "mp3"),
           let audioData = try? Data(contentsOf: URL(fileURLWithPath: audioPath)) {

            do {
                audioPlayer = try AVAudioPlayer(data: audioData)
                audioPlayer?.delegate = self
                audioPlayer?.enableRate = true
                audioPlayer?.rate = selectedSpeed
                audioPlayer?.prepareToPlay()
                print("Audio player initialized successfully.")
            } catch let error as NSError {
                print("Error initializing AVAudioPlayer: \(error.localizedDescription)")
            }
        } else {
            print("Audio file not found in the bundle.")
        }

        timeSlider.minimumValue = 0
        timeSlider.maximumValue = Float(audioPlayer?.duration ?? 0)
        timeSlider.value = 0
        timeSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)

        startUpdateTimer()
    }

    @IBAction func playPauseButtonTapped(_ sender: UIButton) {
        if let player = audioPlayer {
            if player.isPlaying {
                player.pause()
                updatePlayPauseButton(imageName: "play.fill")
            } else {
                player.play()
                updatePlayPauseButton(imageName: "pause.fill")
            }
        }
    }

    @IBAction func stopButtonTapped(_ sender: UIButton) {
        if let player = audioPlayer {
            if player.isPlaying {
                player.stop()
                player.currentTime = 0
                updatePlayPauseButton(imageName: "play.fill")
            }
        }
    }

    @IBAction func loopButtonTapped(_ sender: UIButton) {
        isLooping.toggle()
        let buttonText = isLooping ? "Looping" : "Normal"
        loopButton.setTitle(buttonText, for: .normal)
        if let player = audioPlayer {
            player.numberOfLoops = isLooping ? -1 : 0
            print(player.numberOfLoops)
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
                self?.audioPlayer?.rate = speed
                self?.updateSpeedButton()
            }
            alertController.addAction(action)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    @objc func sliderValueChanged(_ sender: UISlider) {
        if let player = audioPlayer {
            player.currentTime = TimeInterval(sender.value)
            updateSlider()
        }
    }

    @objc func updateSlider() {
        guard let player = audioPlayer else { return }
        timeSlider.value = Float(player.currentTime)
    }

    func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)
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
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopUpdateTimer()
        updateSlider()

        if !isLooping {
            player.currentTime = 0
            updatePlayPauseButton(imageName: "play.fill")
            startUpdateTimer()
        }
    }


    deinit {
        stopUpdateTimer()
    }
    
    
}
