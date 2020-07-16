import AVFoundation
import MediaPlayer
import UIKit

enum PlaybackState {
    case stopped
    case wantPlayback
    case playback
}

class PlaybackController: UIViewController {
    private static let StreamURL = "http://icecast.commedia.org.uk:8000/keithcommunityradio.mp3"

    @IBOutlet weak var playbackButton: UIButton!

    var state: PlaybackState = .stopped
    var player: AVPlayer? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch {
            print(error)
        }

        self.update()
    }

    private func update(state: PlaybackState? = nil) {
        if (state != nil) {
            self.state = state!
        }

        var buttonEnabled: Bool
        var buttonText: String
        var nowPlaying: [String: Any]?

        switch (self.state) {
        case .stopped:
            buttonEnabled = true
            buttonText = "Play"
        case .wantPlayback:
            buttonEnabled = false
            buttonText = "Connecting…"
        case .playback:
            buttonEnabled = true
            buttonText = "Stop"

            let artwork = MPMediaItemArtwork(image: UIApplication.shared.icon!)
            nowPlaying = [
                MPMediaItemPropertyArtist: "KCR",
                MPMediaItemPropertyTitle: "KCR",
                MPMediaItemPropertyArtwork: artwork
            ]
        }

        playbackButton.isEnabled = buttonEnabled
        playbackButton.setTitle(buttonText, for: .normal)
        /* TODO: Why doesn't this work?! */
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlaying
    }

    @IBAction func playback(_ sender: Any) {
        if self.player == nil {
            self.play()
        } else {
            self.stop()
            self.player?.pause()
            self.player = nil
        }
    }

    private func play() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
            return
        }

        self.update(state: .wantPlayback)

        self.player = AVPlayer(url: URL(string: PlaybackController.StreamURL)!)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemFailedToPlayToEndTime, object: nil)

        self.player?.play()

        self.update(state: .playback)
    }

    @objc private func playerDidFinishPlaying(note: NSNotification) {
        self.update(state: .stopped)
    }

    private func stop() {
        self.player?.pause()
        self.player?.replaceCurrentItem(with: nil)
        self.player = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print(error)
        }

        self.update(state: .stopped)
    }
}
