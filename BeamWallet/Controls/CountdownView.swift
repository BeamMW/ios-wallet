//
// CountdownView.swift
// BeamWallet
//
// Copyright 2018 Beam Development
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

@objc public protocol CountdownViewDelegate: class {
    @objc optional func timerDidEnd()
}

public class CountdownView: UIView {
    private var lineWidth: CGFloat = 1.5
    private var lineColor: UIColor = UIColor.init(hexString: "#032E49")
    private var trailLineColor: UIColor = UIColor.main.steelGrey.withAlphaComponent(0.3)
    
    public weak var delegate: CountdownViewDelegate?
    
    private var timer: Timer?
    private var beginingValue: Int = 1
    private var totalTime: TimeInterval = 1
    private var elapsedTime: TimeInterval = 0
    private var interval: TimeInterval = 1
    private let fireInterval: TimeInterval = 0.01
    
    private lazy var counterLabel: UILabel = {
        let label = UILabel()
        self.addSubview(label)
        
        label.textAlignment = .center
        label.frame = self.bounds
        label.font = RegularFont(size: 14)
        label.textColor = UIColor.init(hexString: "#032E49")
        
        return label
    }()
    
    private var currentCounterValue: Int = 0 {
        didSet {
            counterLabel.text = getMinutesAndSeconds(remainingSeconds: currentCounterValue)
        }
    }
    
    // MARK: Inits
    override public init(frame: CGRect) {
        if frame.width != frame.height {
            fatalError(Localizables.shared.strings.fatalInitCoderError)
        }
        
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        layer.cornerRadius = frame.width / 2
        
        clipsToBounds = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let context = UIGraphicsGetCurrentContext()
        let radius = (rect.width - lineWidth) / 2
        let currentAngle = CGFloat((.pi * 2 * elapsedTime) / totalTime)
        
        context?.setLineWidth(lineWidth)
        
        // Main line
        context?.beginPath()
        context?.addArc(
            center: CGPoint(x: rect.midX, y:rect.midY),
            radius: radius,
            startAngle: currentAngle - .pi / 2,
            endAngle: .pi * 2 - .pi / 2,
            clockwise: false)
        context?.setStrokeColor(lineColor.cgColor)
        context?.strokePath()
        
        // Trail line
        context?.beginPath()
        context?.addArc(
            center: CGPoint(x: rect.midX, y:rect.midY),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: currentAngle - .pi / 2,
            clockwise: false)
        context?.setStrokeColor(trailLineColor.cgColor)
        context?.strokePath()
    }
    
    public func start(beginingValue: Int, interval: TimeInterval = 1) {
        self.beginingValue = beginingValue
        self.interval = interval
        
        totalTime = TimeInterval(beginingValue) * interval
        elapsedTime = 0
        currentCounterValue = beginingValue
        
        timer?.invalidate()
        timer = Timer(timeInterval: fireInterval, target: self, selector: #selector(CountdownView.timerFired(_:)), userInfo: nil, repeats: true)
        
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    
    public func pause() {
        timer?.fireDate = Date.distantFuture
    }
    
    
    public func resume() {
        timer?.fireDate = Date()
    }
    
    public func end() {
        self.currentCounterValue = 0
        timer?.invalidate()
        
        delegate?.timerDidEnd?()
    }
    
    public func cancel() {
        timer?.invalidate()
    }
    
    private func getMinutesAndSeconds(remainingSeconds: Int) -> (String) {
        return remainingSeconds.description
    }
    
    // MARK: Private methods
    @objc private func timerFired(_ timer: Timer) {
        elapsedTime += fireInterval
        
        if elapsedTime < totalTime {
            setNeedsDisplay()
            
            let computedCounterValue = beginingValue - Int(elapsedTime / interval)
            if computedCounterValue != currentCounterValue {
                currentCounterValue = computedCounterValue
            }
        } else {
            end()
        }
    }
}
