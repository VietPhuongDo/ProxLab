import UIKit
import AVFoundation
import Network

class ViewController: UIViewController {

    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var loopButton: UIButton!
    @IBOutlet weak var speedButton: UIButton!
    @IBOutlet weak var timeSlider: UISlider!

    private var audioPlayer: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var updateTimer: Timer?
    private var isLooping: Bool = false
    private var speeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    private var selectedSpeed: Float = 1.0
    private var pathMonitor: NWPathMonitor?
    private var isNetworkConnected = true


    override func viewDidLoad() {
        super.viewDidLoad()

        guard let audioURL = URL(string: "http://palestine.procyoni.com/public/file/fast/dbafec6d-3d73-4928-b0a9-4a7cc42d0187.mp3") else {
            fatalError("Invalid audio URL")
        }

        playerItem = AVPlayerItem(url: audioURL)
        audioPlayer = AVPlayer(playerItem: playerItem)

        audioPlayer?.pause()

        timeSlider.minimumValue = 0
        if let duration = playerItem?.asset.duration.seconds, !duration.isNaN {
            timeSlider.maximumValue = Float(duration)
        } else {
            print("Invalid duration")
            timeSlider.maximumValue = 0
        }

        timeSlider.value = 0
        timeSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)

        setupNetworkMonitoring()

        let endTime = CMTime(seconds: playerItem?.asset.duration.seconds ?? 0, preferredTimescale: 1)
        audioPlayer?.addBoundaryTimeObserver(forTimes: [NSValue(time: endTime)], queue: nil) { [weak self] in
            self?.handlePlaybackEnd()
        }
    }

    @IBAction func playPauseButtonTapped(_ sender: UIButton) {
        // Check network connection before playing
        if let currentPath = pathMonitor?.currentPath {
            handleNetworkUpdate(currentPath)
        }

        if let player = audioPlayer {
            if player.rate == 0 {
                player.play()
                updatePlayPauseButton(imageName: "pause.fill")
                startUpdateTimer()
            } else {
                player.pause()
                updatePlayPauseButton(imageName: "play.fill")
                stopUpdateTimer()
            }
        }
        
    }

    @IBAction func stopButtonTapped(_ sender: UIButton) {
        if let player = audioPlayer {
            player.pause()
            player.seek(to: CMTime.zero)
            updatePlayPauseButton(imageName: "play.fill")
            updateSlider()
            speedButton.titleLabel?.text = "1.0x"
            timeSlider.value = 0
        }
    }

    @IBAction func loopButtonTapped(_ sender: UIButton) {
        isLooping.toggle()
        let buttonText = isLooping ? "Looping" : "Normal"
        loopButton.setTitle(buttonText, for: .normal)
        audioPlayer?.actionAtItemEnd = isLooping ? .none : .pause
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
            let targetTime = CMTime(seconds: Double(sender.value), preferredTimescale: 1)
            player.seek(to: targetTime)
            updateSlider()
        }
    }

    @objc func updateSlider() {
        guard let player = audioPlayer else { return }
        timeSlider.value = Float(player.currentTime().seconds)
    }



    @objc func handlePlaybackEnd() {
        if isLooping, let player = audioPlayer {
            let currentRate = player.rate
            player.seek(to: CMTime.zero)
            player.play()
            player.rate = currentRate
        } else {
            updatePlayPauseButton(imageName: "play.fill")
            updateSlider()
            stopUpdateTimer()
            hidePlayButton()
        }
    }

    func hidePlayButton() {
        playPauseButton.isHidden = true
    }


    func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)
    }

    func updatePlayPauseButton(imageName: String) {
        playPauseButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    func updateSpeedButton() {
        speedButton.setTitle("\(selectedSpeed)x", for: .normal)
    }

    func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    func setupNetworkMonitoring() {
        pathMonitor = NWPathMonitor()
        let queue = DispatchQueue.global(qos: .background)
        pathMonitor?.start(queue: queue)
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handleNetworkUpdate(path)
            }
        }
    }

    func handleNetworkUpdate(_ path: NWPath) {
            let isConnected = path.status == .satisfied

            if isConnected != isNetworkConnected {
                isNetworkConnected = isConnected
                if isConnected {
                    print("Connected to the network.")
                    hideNoNetworkAlert()
                    enableMusicInteraction()
                } else {
                    print("Not connected to the network.")
                    showNoNetworkAlert()
                    disableMusicInteraction()
                }
            }
        }
    func showNoNetworkAlert() {
        let alertController = UIAlertController(title: "No Network Connection", message: "Please check your internet connection and try again.", preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.handleNoNetworkConnection()
        }
        alertController.addAction(okAction)

        present(alertController, animated: true, completion: nil)
    }

    func hideNoNetworkAlert() {
        dismiss(animated: true, completion: nil)
    }

    func disableMusicInteraction() {
        playPauseButton.isHidden = true
        audioPlayer?.pause()
    }

    func enableMusicInteraction() {
        playPauseButton.isHidden = false
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    }

    func handleNoNetworkConnection() {
    
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
