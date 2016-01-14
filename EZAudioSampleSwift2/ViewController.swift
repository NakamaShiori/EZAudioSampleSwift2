//
//  ViewController.swift
//  EZAudioSampleSwift2
//
//  Created by N on 2016/01/13.
//  Copyright © 2016年 Nakama. All rights reserved.
//

import UIKit

class ViewController: UIViewController,EZAudioPlayerDelegate,EZMicrophoneDelegate,EZRecorderDelegate {
    
    /*ステータスバー*/
    //先にinofo.plistにてView controller-based status bar appearance = NOと設定。
    
    //基本的な再生・録音機能
    var isRecording = false
    
    var microphone = EZMicrophone()
    
    var recorder:EZRecorder?
    
    var examplePlayer = EZAudioPlayer()
    
    var recordedPlayer = EZAudioPlayer()
    
    //UIパーツ
    var recordingAudioPlot = EZAudioPlotGL(frame:CGRectMake(0,0,ScreenSize.Width,ScreenSize.Height))
    
    var playingAudioPlot = EZAudioPlot(frame:CGRectMake(60,0,ScreenSize.Width-60,40))
    
    var currentTimeLabel = UILabel(frame: CGRectMake(0,0,60,40))
    
    var recordSwitch = UISwitch(frame: CGRectMake(0,40,40,60))
    
    var playSwitch = UISwitch(frame: CGRectMake(60,40,40,60))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //AVセッションの動作設定
        let session = AVAudioSession.sharedInstance()
        do{
            //マイク入力と音声出力を行う
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        }catch let error as NSError {
            print("Error setting up audio session category:\(error.localizedDescription)")
        }
        do{
            //AVFoundation利用開始
            try session.setActive(true)
        }catch let error as NSError {
            print("Error setting up audio session active:\(error.localizedDescription)")
        }
        
        //EZAudio設定
        microphone = EZMicrophone(delegate: self)
        examplePlayer = EZAudioPlayer(delegate: self)
        recordedPlayer = EZAudioPlayer(delegate: self)
        
        //UI設定
        self.recordingAudioPlot.backgroundColor = GlobalColor.DarkGray
        self.recordingAudioPlot.plotType        = EZPlotType.Rolling
        self.recordingAudioPlot.shouldFill      = true
        self.recordingAudioPlot.shouldMirror    = true
        self.view.addSubview(self.recordingAudioPlot)
        
        self.playingAudioPlot.backgroundColor = GlobalColor.WhiteGray
        self.playingAudioPlot.plotType        = EZPlotType.Rolling
        self.playingAudioPlot.shouldFill      = true
        self.playingAudioPlot.shouldMirror    = true
        self.playingAudioPlot.gain = 2.5
        self.view.addSubview(self.playingAudioPlot)
        
        self.currentTimeLabel.backgroundColor = GlobalColor.LightGray
        self.currentTimeLabel.text = "00:00"
        self.view.addSubview(self.currentTimeLabel)
        
        self.recordSwitch.onTintColor = UIColor.redColor()
        self.recordSwitch.addTarget(self, action: "toggleRecording:", forControlEvents: UIControlEvents.ValueChanged)
        self.view.addSubview(self.recordSwitch)
        
        self.playSwitch.onTintColor = UIColor.greenColor()
        self.playSwitch.addTarget(self, action: "togglePlaying:", forControlEvents: UIControlEvents.ValueChanged)
        self.view.addSubview(self.playSwitch)
        
        //サンドボックス内のファイルパスを確認
        print("File written to application sandbox's documents directory:\(self.testFilePathURL())")
        
        //キー監視追加
        self.setupNortifications()
    }
    
    //キー監視設定
    func setupNortifications(){
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:"playerDidChangePlayState:",
            name: EZAudioPlayerDidChangePlayStateNotification,
            object: self.recordedPlayer)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:"playerDidReachEndOfFile:",
            name: EZAudioPlayerDidReachEndOfFileNotification,
            object: self.recordedPlayer)
    }
    
    func playerDidChangePlayState(notification:NSNotification){
        if let player = notification.object as? EZAudioPlayer{
            let isPlaying = player.isPlaying
            if (isPlaying == true){
                //再生開始時
                self.recorder!.delegate = nil
            }
        }
    }
    
    func playerDidReachEndOfFile(notification:NSNotification){
        //再生終了時
        self.playingAudioPlot.clear()
        self.playSwitch.on = false
    }
    
    //サンドボックス内のファイルパス取得
    func testFilePathURL () -> NSURL{
        let paths:NSArray = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var basePath:String
        if (paths.count>0){
            basePath = paths.objectAtIndex(0) as! String
        }else{
            basePath = ""
        }
        return NSURL.fileURLWithPath("\(basePath)/\(kAudioFilePath)")
    }
    
    //UI関連
    
    func toggleRecording(sender:UISwitch){
        print("Record")
        
        //録音音声プレーヤー停止
        self.recordedPlayer.pause()
        
        if sender.on{
            
            //波形画像をリセット
            self.recordingAudioPlot.clear()
            //マイクスイッチをオン
            self.microphone.startFetchingAudio()
            //録音開始
            self.recorder = EZRecorder(URL: self.testFilePathURL(),
                clientFormat:microphone.audioStreamBasicDescription(),
                fileType: EZRecorderFileType.M4A,
                delegate: self)
            isRecording = true
            
        }else{
            
            //マイクスイッチをオフ
            self.microphone.stopFetchingAudio()
            //録音終了
            recorder!.closeAudioFile()
            isRecording = false
            
        }
    }
    
    func togglePlaying(sender:UISwitch){
        print("Play")
        
        if sender.on{
            
            //マイクスイッチをオフ
            self.microphone.stopFetchingAudio()
            //録音終了
            if self.recorder != nil{
                recorder!.closeAudioFile()
            }
            //レコーダートグルスイッチをオフ
            self.recordSwitch.on = false
            isRecording = false
            
            //録音音声を再生
            let audioFile = EZAudioFile(URL: self.testFilePathURL())
            self.recordedPlayer.playAudioFile(audioFile)
            
        }else{
            
        }
    }
    
    //EZMicrophoneDelegate
    
    func microphone(microphone: EZMicrophone!, hasBufferList bufferList: UnsafeMutablePointer<AudioBufferList>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {
        if(isRecording==true){
            self.recorder!.appendDataFromBufferList(bufferList, withBufferSize: bufferSize)
        }
    }
    
    func microphone(microphone: EZMicrophone!,
        hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>,
        withBufferSize bufferSize: UInt32,
        withNumberOfChannels numberOfChannels: UInt32) {
            dispatch_async(dispatch_get_main_queue()) {
                self.recordingAudioPlot.updateBuffer(buffer[0], withBufferSize: bufferSize)
            }
    }
    
    //EZRecorderDelegate
    
    func recorderDidClose(recorder: EZRecorder!) {
        recorder.delegate = nil
    }
    
    func recorderUpdatedCurrentTime(recorder: EZRecorder!) {
        let formattedCurrentTime = recorder.formattedCurrentTime
        dispatch_async(dispatch_get_main_queue()) {
            [weak self] in
            self?.currentTimeLabel.text = formattedCurrentTime
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //EZAudioPlayerDelegate
    
    func audioPlayer(audioPlayer: EZAudioPlayer!, playedAudio buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32, inAudioFile audioFile: EZAudioFile!) {
        dispatch_async(dispatch_get_main_queue()) {
            [weak self] in
            self?.playingAudioPlot.updateBuffer(buffer[0], withBufferSize: bufferSize)
        }
    }
    
    func audioPlayer(audioPlayer: EZAudioPlayer!, updatedPosition framePosition: Int64, inAudioFile audioFile: EZAudioFile!) {
        dispatch_async(dispatch_get_main_queue()) {
            [weak self] in
            self?.currentTimeLabel.text = audioPlayer.formattedCurrentTime
        }
    }
}

