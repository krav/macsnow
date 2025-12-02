import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var snowWindow: SnowWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBarItem()
        setupSnowWindow()
    }
    
    func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "snowflake", accessibilityDescription: "MacSnow")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Snowfall Speed", action: nil, keyEquivalent: ""))
        
        let lightSnow = NSMenuItem(title: "Light", action: #selector(setLightSnow), keyEquivalent: "")
        lightSnow.target = self
        menu.addItem(lightSnow)
        
        let mediumSnow = NSMenuItem(title: "Medium", action: #selector(setMediumSnow), keyEquivalent: "")
        mediumSnow.target = self
        mediumSnow.state = .on
        menu.addItem(mediumSnow)
        
        let heavySnow = NSMenuItem(title: "Heavy", action: #selector(setHeavySnow), keyEquivalent: "")
        heavySnow.target = self
        menu.addItem(heavySnow)
        
        menu.addItem(NSMenuItem.separator())
        
        let windItem = NSMenuItem(title: "Wind Effect", action: #selector(toggleWind), keyEquivalent: "")
        windItem.target = self
        windItem.state = .on
        menu.addItem(windItem)
        
        let settlingItem = NSMenuItem(title: "Snow Settling on Windows", action: #selector(toggleSettling), keyEquivalent: "")
        settlingItem.target = self
        settlingItem.state = .on
        menu.addItem(settlingItem)
        
        let santaItem = NSMenuItem(title: "Santa Sleigh", action: #selector(toggleSanta), keyEquivalent: "")
        santaItem.target = self
        santaItem.state = .on
        menu.addItem(santaItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    func setupSnowWindow() {
        if let screen = NSScreen.main {
            snowWindow = SnowWindow(screen: screen)
            snowWindow?.makeKeyAndOrderFront(nil)
            snowWindow?.startSnowing()
        }
    }
    
    @objc func setLightSnow() {
        updateMenuState(selected: 1)
        snowWindow?.setSnowIntensity(.light)
    }
    
    @objc func setMediumSnow() {
        updateMenuState(selected: 2)
        snowWindow?.setSnowIntensity(.medium)
    }
    
    @objc func setHeavySnow() {
        updateMenuState(selected: 3)
        snowWindow?.setSnowIntensity(.heavy)
    }
    
    @objc func toggleWind() {
        if let menu = statusItem?.menu,
           let windItem = menu.item(withTitle: "Wind Effect") {
            let newState: NSControl.StateValue = windItem.state == .on ? .off : .on
            windItem.state = newState
            snowWindow?.setWindEnabled(newState == .on)
        }
    }
    
    @objc func toggleSettling() {
        if let menu = statusItem?.menu,
           let settlingItem = menu.item(withTitle: "Snow Settling on Windows") {
            let newState: NSControl.StateValue = settlingItem.state == .on ? .off : .on
            settlingItem.state = newState
            snowWindow?.setSettlingEnabled(newState == .on)
        }
    }
    
    @objc func toggleSanta() {
        if let menu = statusItem?.menu,
           let santaItem = menu.item(withTitle: "Santa Sleigh") {
            let newState: NSControl.StateValue = santaItem.state == .on ? .off : .on
            santaItem.state = newState
            snowWindow?.setSantaEnabled(newState == .on)
        }
    }
    
    func updateMenuState(selected: Int) {
        if let menu = statusItem?.menu {
            menu.item(withTitle: "Light")?.state = selected == 1 ? .on : .off
            menu.item(withTitle: "Medium")?.state = selected == 2 ? .on : .off
            menu.item(withTitle: "Heavy")?.state = selected == 3 ? .on : .off
        }
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
