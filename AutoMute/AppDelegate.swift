//
//  AppDelegate.swift
//  AutoMute
//
//  Created by Kevin Kwok on 8/15/21.
//

import Cocoa
import SimplyCoreAudio
import CoreAudio

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    private let simply = SimplyCoreAudio()
    let autoMuteSeconds: TimeInterval = 40
    
    var statusItem: NSStatusItem?
    var lastActive: Date = Date()

    @IBOutlet weak var menu: NSMenu?
    @IBOutlet weak var isEnabled: NSMenuItem?
    @IBOutlet weak var appStatus: NSMenuItem?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
         
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "KaneMute"
        if let menu = menu {
            statusItem?.menu = menu
        }
    }
    
    @IBAction func toggleEnable(sender: NSMenuItem){
        if(isEnabled?.state == NSControl.StateValue.on){
            isEnabled?.state = NSControl.StateValue.off
            statusItem?.button?.appearsDisabled = true
        }else{
            isEnabled?.state = NSControl.StateValue.on
            statusItem?.button?.appearsDisabled = false
        }
    }
    
    func checkAudioPlayback() {
        let output = simply.defaultOutputDevice!
        let isMuted = output.isMasterChannelMuted(scope: .output)!
        if(output.isRunningSomewhere){
            lastActive = Date()
            appStatus?.title = "Active"
        }else{
            if(isMuted){
                appStatus?.title = "Muted"
            }else{
                appStatus?.title = "Muting in \(Int(autoMuteSeconds + lastActive.timeIntervalSinceNow)) seconds"
            }
        }
        if(lastActive.timeIntervalSinceNow < -autoMuteSeconds && !isMuted){
            output.setMute(true, channel: kAudioObjectPropertyElementMaster, scope: .output)
            
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (t: Timer) in
            self.checkAudioPlayback()
        
        }
        checkAudioPlayback()
    }


}

