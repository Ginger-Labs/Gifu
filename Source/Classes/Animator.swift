/// Responsible for parsing GIF data and decoding the individual frames.
public class Animator {
    
    /// Total duration of one animation loop
    public var loopDuration: TimeInterval {
        return frameStore?.loopDuration ?? 0
    }
    
    
    
    /// Number of frame to buffer.
    public var frameBufferCount = 50
    
    /// Specifies whether GIF frames should be resized.
    public var shouldResizeFrames = false
    
    /// Responsible for loading individual frames and resizing them if necessary.
    public var frameStore: FrameStore?
    
    /// Tracks whether the display link is initialized.
    private var displayLinkInitialized: Bool = false
    
    /// Responsible for starting and stopping the animation.
    private lazy var displayLink: CADisplayLink = { [unowned self] in
        self.displayLinkInitialized = true
        let display = CADisplayLink(target: DisplayLinkProxy(target: self), selector: #selector(DisplayLinkProxy.onScreenUpdate))
        display.isPaused = true
        return display
        }()
    
    /// Introspect whether the `displayLink` is paused.
    private(set) public var isAnimating = false
    
    /// Total frame count of the GIF.
    public var frameCount: Int {
        return frameStore?.frameCount ?? 0
    }
    
    /// Gets the current image from the frame store.
    ///
    /// - returns: An optional frame image to display.
    public var currentFrame : UIImage? {
        return frameStore?.currentFrameImage
    }
    
    public var onNewFrame : ((UIImage) -> ())?
    
    public var size : CGSize? {
        return frameStore?.size
    }
    
    /// Creates a new animator
    public init(onNewFrame : ((UIImage) -> ())? = nil) {
        self.onNewFrame = onNewFrame
    }
    
    /// Checks if there is a new frame to display.
    fileprivate func updateFrameIfNeeded() {
        guard let store = frameStore else { return }
        if store.isFinished {
            stopAnimating()
            return
        }
        
        store.shouldChangeFrame(with: displayLink.duration) {
            if $0, let currentFrame = currentFrame {
                onNewFrame?(currentFrame)
            }
        }
    }
    
    /// Prepares the animator instance for animation.
    ///
    /// - parameter imageName: The file name of the GIF in the main bundle.
    /// - parameter size: The target size of the individual frames.
    /// - parameter contentMode: The view content mode to use for the individual frames.
    /// - parameter loopCount: Desired number of loops, <= 0 for infinite loop.
    /// - parameter completionHandler: Completion callback function
    func prepareForAnimation(withGIFNamed imageName: String, size: CGSize, contentMode: UIViewContentMode, loopCount: Int = 0, completionHandler: ((Void) -> Void)? = .none) {
        guard let extensionRemoved = imageName.components(separatedBy: ".")[safe: 0],
            let imagePath = Bundle.main.url(forResource: extensionRemoved, withExtension: "gif"),
            let data = try? Data(contentsOf: imagePath) else { return }
        
        prepareForAnimation(withGIFData: data, size: size, contentMode: contentMode, loopCount: loopCount, completionHandler: completionHandler)
    }
    
    /// Prepares the animator instance for animation.
    ///
    /// - parameter imageData: GIF image data.
    /// - parameter size: The target size of the individual frames.
    /// - parameter contentMode: The view content mode to use for the individual frames.
    /// - parameter loopCount: Desired number of loops, <= 0 for infinite loop.
    /// - parameter completionHandler: Completion callback function
    func prepareForAnimation(withGIFData imageData: Data, size: CGSize, contentMode: UIViewContentMode, loopCount: Int = 0, completionHandler: ((Void) -> Void)? = .none) {
        frameStore = FrameStore(data: imageData, size: size, contentMode: contentMode, framePreloadCount: frameBufferCount, loopCount: loopCount)
        frameStore?.shouldResizeFrames = shouldResizeFrames
        frameStore?.prepareFrames(completionHandler)
    }
    
    deinit {
        if displayLinkInitialized {
            displayLink.invalidate()
        }
    }
    
    /// Start animating.
    public func startAnimating() {
        if frameStore?.isAnimatable ?? false, !isAnimating {
            displayLink.add(to: .main, forMode: RunLoopMode.commonModes)
            displayLink.isPaused = false
            isAnimating = true
        }
    }
    
    /// Stop animating.
    public func stopAnimating() {
        if isAnimating {
            displayLink.isPaused = true
            displayLink.remove(from: .main, forMode: RunLoopMode.commonModes)
            isAnimating = false
        }
    }
    
    /// Prepare for animation and start animating immediately.
    ///
    /// - parameter imageName: The file name of the GIF in the main bundle.
    /// - parameter size: The target size of the individual frames.
    /// - parameter contentMode: The view content mode to use for the individual frames.
    /// - parameter loopCount: Desired number of loops, <= 0 for infinite loop.
    public func animate(withGIFNamed imageName: String, size: CGSize, contentMode: UIViewContentMode, loopCount: Int = 0) {
        prepareForAnimation(withGIFNamed: imageName, size: size, contentMode: contentMode, loopCount: loopCount)
        startAnimating()
    }
    
    /// Prepare for animation and start animating immediately.
    ///
    /// - parameter imageData: GIF image data.
    /// - parameter size: The target size of the individual frames.
    /// - parameter contentMode: The view content mode to use for the individual frames.
    /// - parameter loopCount: Desired number of loops, <= 0 for infinite loop.
    public func animate(withGIFData imageData: Data, size: CGSize, contentMode: UIViewContentMode, loopCount: Int = 0) {
        prepareForAnimation(withGIFData: imageData, size: size, contentMode: contentMode, loopCount: loopCount)
        startAnimating()
    }
    
    /// Stop animating and nullify the frame store.
    public func prepareForReuse() {
        stopAnimating()
        frameStore = nil
    }
    
}

/// A proxy class to avoid a retain cycle with the display link.
fileprivate class DisplayLinkProxy {
    
    /// The target animator.
    private weak var target: Animator?
    
    /// Create a new proxy object with a target animator.
    ///
    /// - parameter target: An animator instance.
    ///
    /// - returns: A new proxy instance.
    init(target: Animator) { self.target = target }
    
    /// Lets the target update the frame if needed.
    @objc func onScreenUpdate() { target?.updateFrameIfNeeded() }
}
