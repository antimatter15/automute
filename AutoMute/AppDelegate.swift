//
//  AppDelegate.swift
//  AutoMute
//
//  Created by Kevin Kwok on 8/15/21.
//

import Cocoa
import SimplyCoreAudio
import CoreAudio
import LaunchAtLogin


@main
class AppDelegate: NSObject, NSApplicationDelegate {

    private let simply = SimplyCoreAudio()
    let autoMuteSeconds: TimeInterval = 40
    
    var statusItem: NSStatusItem?
    var lastActive: Date = Date()
    var observation: NSKeyValueObservation?


    @IBOutlet weak var menu: NSMenu?
    @IBOutlet weak var isEnabled: NSMenuItem?
    @IBOutlet weak var startOnLogin: NSMenuItem?
    @IBOutlet weak var appStatus: NSMenuItem?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.setStatusIcon()
        if let menu = menu {
            statusItem?.menu = menu
        }
        
    }
    
    func setStatusIcon(){
        if(LaunchAtLogin.isEnabled){
            startOnLogin?.state = NSControl.StateValue.on
        }else{
            startOnLogin?.state = NSControl.StateValue.off
        }
        
        var sourceImage = NSApp.applicationIconImage!
        
        if(statusItem?.button?.effectiveAppearance.name.rawValue.lowercased().contains("dark") ?? false){
            let filter = CIFilter(name: "CIColorInvert")
            let data = sourceImage.tiffRepresentation!
            let bitmap = NSBitmapImageRep(data: data)
            let beginImage = CIImage(bitmapImageRep: bitmap!)

            filter?.setValue(beginImage, forKey: kCIInputImageKey)
            
            let rep = NSCIImageRep(ciImage: filter!.outputImage!)
            sourceImage = NSImage(size: rep.size)
            sourceImage.addRepresentation(rep)
        }
        
        let resizedLogo = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { (dstRect) -> Bool in
            sourceImage.draw(in: dstRect)
                return true
            }
        
        statusItem?.button?.image = resizedLogo
    }
    
    @IBAction func toggleStartOnLogin(sender: NSMenuItem){
        LaunchAtLogin.isEnabled = !LaunchAtLogin.isEnabled

        setStatusIcon()
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
        observation = statusItem?.button?.observe(\.effectiveAppearance) { (app, _) in
            app.effectiveAppearance.performAsCurrentDrawingAppearance {
                self.setStatusIcon()
            }
        }
    }
}

