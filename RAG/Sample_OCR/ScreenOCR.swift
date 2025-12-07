// ScreenOCR.swift
//
// A macOS command‑line tool that monitors global key and scroll events,
// captures the current screen image when a trigger occurs and performs OCR
// using DeepSeek‑OCR.  The OCR results are converted to a simple XML
// representation and printed to standard output.
//
// This example relies on ApplicationServices for taking the screenshot and
// NSEvent global monitors for event notifications.  When a trigger event
// (any key press or scroll wheel movement) is detected, the program saves
// the screenshot to a temporary location and invokes a Python helper
// (`perform_ocr.py`) that loads the DeepSeek‑OCR model to extract text.
//
// Note: running DeepSeek‑OCR requires a capable GPU and the Python
// dependencies listed in the official documentation.  See the provided
// `perform_ocr.py` script for details.  Without those dependencies the
// program will still capture screenshots but the OCR step will fail.

import Cocoa
import ApplicationServices
import CoreGraphics

/// ScreenWatcher encapsulates the global event monitoring and screenshot
/// capture logic.  It installs global monitors for keyDown and scrollWheel
/// events and cleans them up on program termination.
final class ScreenWatcher {
    /// Handles to the event monitors so they can be removed later.
    private var keyMonitor: Any?
    private var scrollMonitor: Any?

    init() {
        // Request accessibility privileges so the app can monitor global
        // keyboard and mouse events.  If the user hasn't granted the
        // permission yet, the system will show a dialog prompting for it.
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        _ = AXIsProcessTrustedWithOptions(options)

        // Register for keyDown events globally.  NSEvent's
        // addGlobalMonitorForEvents installs a passive listener that sees
        // copies of events posted to other applications【170263965578339†L144-L166】.
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleTrigger(for: event)
        }

        // Register for scroll wheel events globally.  When the user scrolls
        // with a mouse or trackpad the `scrollWheel` event is posted.  We
        // treat any scroll as a trigger to capture the screen.
        scrollMonitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleTrigger(for: event)
        }
    }

    deinit {
        stopMonitoring()
    }

    /// Cleans up the event monitors.  This should be called before exit.
    func stopMonitoring() {
        if let keyMonitor = keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
        if let scrollMonitor = scrollMonitor {
            NSEvent.removeMonitor(scrollMonitor)
        }
    }

    /// Handles an incoming trigger event by capturing the screen and
    /// performing OCR on it.  The results are printed as XML.
    private func handleTrigger(for event: NSEvent) {
        // Capture the screen by invoking the `screencapture` tool and
        // save directly to a temporary PNG file.  This avoids using
        // deprecated Quartz APIs and works on modern macOS SDKs.
        let tempDir = FileManager.default.temporaryDirectory
        let timestamp = Date().timeIntervalSince1970
        let fileURL = tempDir.appendingPathComponent("screen_\(timestamp).png")
        do {
            try captureScreenToFile(fileURL: fileURL)
        } catch {
            print("Failed to capture screen: \(error)", to: &standardError)
            return
        }
        // Invoke the Python OCR script on the saved file.
        performOCR(imageURL: fileURL)
    }

    /// Capture the current screen to the provided file path using the
    /// `screencapture` command-line tool.  Throws an error on failure.
    private func captureScreenToFile(fileURL: URL) throws {
        let candidates = ["/usr/sbin/screencapture", "/usr/bin/screencapture", "/usr/local/bin/screencapture"]
        var exe: String? = nil
        for c in candidates {
            if FileManager.default.isExecutableFile(atPath: c) {
                exe = c
                break
            }
        }
        guard let screencapture = exe else {
            throw NSError(domain: "com.example.ScreenOCR", code: -1, userInfo: [NSLocalizedDescriptionKey: "screencapture tool not found"])
        }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: screencapture)
        // -x disables the shutter sound; write to the given path
        proc.arguments = ["-x", fileURL.path]
        try proc.run()
        proc.waitUntilExit()
        if proc.terminationStatus != 0 {
            throw NSError(domain: "com.example.ScreenOCR", code: Int(proc.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "screencapture failed with status \(proc.terminationStatus)"])
        }
    }

    /// Captures the current contents of the main display as a CGImage.
    /// According to Apple's Quartz Display Services, passing
    /// `kCGDirectMainDisplay` to `CGDisplayCreateImage` returns a
    /// snapshot of the entire main display【977673730951989†L33-L63】.
        private func captureMainDisplay() -> CGImage? {
            // Not used on modern SDKs; screen capture is performed via
            // the `screencapture` subprocess. Keep this stub to avoid
            // referencing deprecated APIs at compile time.
            return nil
    }

    /// Saves a CGImage to disk as a PNG file.
    private func saveImage(_ cgImage: CGImage, to url: URL) throws {
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        if let data = bitmap.representation(using: .png, properties: [:]) {
            try data.write(to: url)
        } else {
            throw NSError(domain: "com.example.ScreenOCR", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not create PNG representation"])
        }
    }

    /// Runs the Python helper script to perform OCR.  The helper must be
    /// present in the app bundle's Resources directory.  The OCR script
    /// should print an XML document to stdout; this function reads the
    /// output and prints it to the console.
    private func performOCR(imageURL: URL) {
        // Resolve the OCR script path.  Priority:
        // 1. `PERFORM_OCR_SCRIPT` environment variable (full path to script)
        // 2. bundled `perform_ocr.py` resource
        // 3. `./perform_ocr.py` in current working directory
        let env = ProcessInfo.processInfo.environment
        var scriptPath: String? = nil
        if let override = env["PERFORM_OCR_SCRIPT"], FileManager.default.fileExists(atPath: override) {
            scriptPath = override
        } else if let bundlePath = Bundle.main.path(forResource: "perform_ocr", ofType: "py") {
            scriptPath = bundlePath
        } else {
            let cwd = FileManager.default.currentDirectoryPath
            let candidate = URL(fileURLWithPath: cwd).appendingPathComponent("perform_ocr.py").path
            if FileManager.default.fileExists(atPath: candidate) {
                scriptPath = candidate
            }
        }
        guard let script = scriptPath else {
            print("OCR script not found (set PERFORM_OCR_SCRIPT or place perform_ocr.py in cwd/bundle)", to: &standardError)
            return
        }

        // Allow overriding the python executable via `PYTHON` env var.
        let pythonPath = ProcessInfo.processInfo.environment["PYTHON"] ?? "/usr/bin/python3"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = [script, imageURL.path]
        // Ensure Python can import any local DeepSeek code.  If the
        // `DEEPSEEK_OCR_PATH` environment variable is set, prepend it to
        // `PYTHONPATH`.  Otherwise, if the standard local path exists,
        // add `/Users/ameekbains/DeepSeek-OCR` automatically.
        var newEnv = ProcessInfo.processInfo.environment
        if let dsPath = newEnv["DEEPSEEK_OCR_PATH"] {
            if let existing = newEnv["PYTHONPATH"], !existing.isEmpty {
                newEnv["PYTHONPATH"] = dsPath + ":" + existing
            } else {
                newEnv["PYTHONPATH"] = dsPath
            }
        } else {
            let defaultDeepSeek = "/Users/ameekbains/DeepSeek-OCR"
            if FileManager.default.fileExists(atPath: defaultDeepSeek) {
                if let existing = newEnv["PYTHONPATH"], !existing.isEmpty {
                    newEnv["PYTHONPATH"] = defaultDeepSeek + ":" + existing
                } else {
                    newEnv["PYTHONPATH"] = defaultDeepSeek
                }
            }
        }
        process.environment = newEnv

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        do {
            try process.run()
        } catch {
            print("Could not launch Python: \(error)", to: &standardError)
            return
        }
        process.waitUntilExit()
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        if let result = String(data: data, encoding: .utf8) {
            print(result)
        }
    }
}

// Provide a writable stream for stderr printing.
struct FileHandleTextOutputStream: TextOutputStream {
    let fh: FileHandle
    mutating func write(_ string: String) {
        if let data = string.data(using: .utf8) {
            fh.write(data)
        }
    }
}
var standardError = FileHandleTextOutputStream(fh: FileHandle.standardError)

// Set up a simple run loop so the tool stays alive.  Construct the
// ScreenWatcher, then run the main loop until interrupted.
let watcher = ScreenWatcher()
print("Screen OCR monitor started.  Press Control+C to exit.")
RunLoop.main.run()