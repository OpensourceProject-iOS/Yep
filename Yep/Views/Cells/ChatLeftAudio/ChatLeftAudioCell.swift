//
//  ChatLeftAudioCell.swift
//  Yep
//
//  Created by NIX on 15/4/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatLeftAudioCell: UICollectionViewCell {

    var message: Message?

    var audioPlayedDuration: Double = 0 {
        willSet {
            updateAudioInfoViews()
        }
    }

    var playing: Bool = false {
        willSet {
            if newValue != playing {
                if newValue {
                    playButton.setImage(UIImage(named: "icon_pause"), forState: .Normal)
                } else {
                    playButton.setImage(UIImage(named: "icon_play"), forState: .Normal)
                }
            }
        }
    }


    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var bubbleImageView: UIImageView!
    
    @IBOutlet weak var sampleView: SampleView!
    @IBOutlet weak var sampleViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var audioDurationLabel: UILabel!

    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var loadingProgressView: MessageLoadingProgressView!
    
    typealias AudioBubbleTapAction = (message: Message?) -> Void
    var audioBubbleTapAction: AudioBubbleTapAction?

    func loadingWithProgress(progress: Double) {
        
        println("audio loadingWithProgress \(progress)")
        
        if progress == 1.0 {
            loadingProgressView.hidden = true
            
        } else {
            loadingProgressView.progress = progress
            loadingProgressView.hidden = false
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageViewWidthConstraint.constant = YepConfig.chatCellAvatarSize()
        
        bubbleImageView.tintColor = UIColor.leftBubbleTintColor()

        sampleView.sampleColor = UIColor.leftWaveColor()

        audioDurationLabel.textColor = UIColor.blackColor()

        playButton.userInteractionEnabled = false
        playButton.tintColor = UIColor.darkGrayColor()

        bubbleImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tapMediaView")
        bubbleImageView.addGestureRecognizer(tap)
    }

    func tapMediaView() {
        audioBubbleTapAction?(message: message)
    }
    
    func configureWithMessage(message: Message, audioPlayedDuration: Double, audioBubbleTapAction: AudioBubbleTapAction?, collectionView: UICollectionView, indexPath: NSIndexPath) {

        self.message = message

        self.audioBubbleTapAction = audioBubbleTapAction

        self.audioPlayedDuration = audioPlayedDuration
        
        YepDownloader.downloadAttachmentsOfMessage(message, reportProgress: { [unowned self] progress in
            dispatch_async(dispatch_get_main_queue()) {
                self.loadingWithProgress(progress)
            }
        })

        if let sender = message.fromFriend {
            AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: YepConfig.chatCellAvatarSize() * 0.5) { [unowned self] roundImage in
                dispatch_async(dispatch_get_main_queue()) {
                    if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                        self.avatarImageView.image = roundImage
                    }
                }
            }
        }

        updateAudioInfoViews()
    }

    func updateAudioInfoViews() {
        
        if let message = message {

            if !message.metaData.isEmpty {

                if let data = message.metaData.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                    if let metaDataDict = decodeJSON(data) {

                        if let audioSamples = metaDataDict["audio_samples"] as? [CGFloat] {
                            sampleViewWidthConstraint.constant = CGFloat(audioSamples.count) * (YepConfig.audioSampleWidth() + YepConfig.audioSampleGap()) - YepConfig.audioSampleGap() // 最后最后一个 gap 不要

                            sampleViewWidthConstraint.constant = max(YepConfig.minMessageSampleViewWidth, sampleViewWidthConstraint.constant)

                            sampleView.samples = audioSamples

                            if let audioDuration = metaDataDict["audio_duration"] as? Double {
                                audioDurationLabel.text = NSString(format: "%.1f\"", audioDuration) as String

                                sampleView.progress = CGFloat(audioPlayedDuration / audioDuration)

                            } else {
                                sampleView.progress = 0
                            }
                        }
                    }

                } else {
                    sampleViewWidthConstraint.constant = 15 * (YepConfig.audioSampleWidth() + YepConfig.audioSampleGap())
                    audioDurationLabel.text = ""
                }
            }

            if let audioPlayer = YepAudioService.sharedManager.audioPlayer {
                if audioPlayer.playing {
                    if let playingMessage = YepAudioService.sharedManager.playingMessage {
                        if message.messageID == playingMessage.messageID {
                            playing = true
                            
                            return
                        }
                    }
                }
            }
        }

        playing = false
    }
}
