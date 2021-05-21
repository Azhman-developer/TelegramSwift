//
//  GroupCallView.swift
//  Telegram
//
//  Created by Mikhail Filimonov on 06.04.2021.
//  Copyright © 2021 Telegram. All rights reserved.
//

import Foundation
import TGUIKit
import SwiftSignalKit
import TelegramCore
import Postbox



final class GroupCallView : View {
    
    enum ControlsMode {
        case normal
        case invisible
    }
    
    private var controlsMode: ControlsMode = .normal
//    private var resizeMode: CALayerContentsGravity = .resizeAspect {
//        didSet {
//            mainVideoView?.currentResizeMode = resizeMode
//        }
//    }
    let peersTable: TableView = TableView(frame: NSMakeRect(0, 0, 340, 329))
    
    let titleView: GroupCallTitleView = GroupCallTitleView(frame: NSMakeRect(0, 0, 380, 54))
    private let peersTableContainer: View = View(frame: NSMakeRect(0, 0, 340, 329))
    private let controlsContainer = GroupCallControlsView(frame: .init(x: 0, y: 0, width: 360, height: 320))
    
    private var mainVideoView: GroupCallMainVideoContainerView? = nil
    private var scheduleView: GroupCallScheduleView?
    private var tileView: GroupCallTileView?

    
    var arguments: GroupCallUIArguments? {
        didSet {
            controlsContainer.arguments = arguments
        }
    }
    
    override func viewDidMoveToWindow() {
        if window == nil {
            var bp:Int = 0
            bp += 1
        }
    }
    
    deinit {
        var bp:Int = 0
        bp += 1
    }
    
    
    
    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(peersTableContainer)
        addSubview(peersTable)
        addSubview(titleView)
        addSubview(controlsContainer)
                
        peersTableContainer.layer?.cornerRadius = 10
        updateLocalizationAndTheme(theme: theme)
        

        peersTable._mouseDownCanMoveWindow = true
        
        peersTable.getBackgroundColor = {
            .clear
        }
        peersTable.addScroll(listener: TableScrollListener(dispatchWhenVisibleRangeUpdated: false, { [weak self] pos in
            guard let `self` = self else {
                return
            }
            self.peersTableContainer.frame = self.substrateRect()
        }))
    }
    
    private func substrateRect() -> NSRect {
        var h = self.peersTable.listHeight
        if peersTable.documentOffset.y < 0 {
            h -= peersTable.documentOffset.y
        }
        h = min(h, self.peersTable.frame.height)
        return .init(origin:  tableRect.origin, size: NSMakeSize(self.peersTable.frame.width, h))

    }
    
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
    
    override func updateLocalizationAndTheme(theme: PresentationTheme) {
        super.updateLocalizationAndTheme(theme: theme)
        peersTableContainer.backgroundColor = GroupCallTheme.membersColor
        backgroundColor = GroupCallTheme.windowBackground
        titleView.backgroundColor = .clear
    }
    
    func updateMouse(event: NSEvent, animated: Bool, isReal: Bool) {
        guard let window = self.window else {
            return
        }
        let location = self.convert(window.mouseLocationOutsideOfEventStream, from: nil)
        
        var mode: ControlsMode
        let videoView = self.mainVideoView ?? self.tileView
        if let videoView = videoView {
            if NSPointInRect(location, videoView.frame) && mouseInside() {
                if isReal {
                    mode = .normal
                } else {
                    mode = self.controlsMode
                }
            } else {
                mode = .invisible
            }
        } else {
            mode = .normal
        }
        
        if state?.state.networkState == .connecting {
            mode = .normal
        }
        
        let previousMode = self.controlsMode
        self.controlsMode = mode
        
       // if previousMode != mode {
            controlsContainer.change(opacity: mode == .invisible && isFullScreen ? 0 : 1, animated: animated)
            mainVideoView?.updateMode(controlsMode: mode, controlsState: controlsContainer.mode, animated: animated)
            tileView?.updateMode(controlsMode: mode, controlsState: controlsContainer.mode, animated: animated)

    ///    }
    }
    
    func idleHide() {
        
        guard let window = self.window else {
            return
        }
        let location = window.mouseLocationOutsideOfEventStream
        
        let frame = controlsContainer.convert(controlsContainer.fullscreenBackgroundView.frame, to: nil)

        
        
        let hasVideo = (mainVideoView ?? tileView) != nil
        let mode: ControlsMode = hasVideo && isFullScreen && !NSPointInRect(location, frame) ? .invisible :.normal
        let previousMode = self.controlsMode
        self.controlsMode = mode
        
        if previousMode != mode {
            controlsContainer.change(opacity: mode == .invisible && isFullScreen ? 0 : 1, animated: true)
            
            
            var videosMode: ControlsMode
            if !isFullScreen {
                if NSPointInRect(location, frame) && mouseInside() {
                    videosMode = .normal
                } else {
                    videosMode = .invisible
                }
            } else {
                videosMode = mode
            }
            
            self.controlsMode = videosMode
            
            mainVideoView?.updateMode(controlsMode: videosMode, controlsState: controlsContainer.mode, animated: true)
            tileView?.updateMode(controlsMode: videosMode, controlsState: controlsContainer.mode, animated: true)

        }
    }
    
    func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition) {
        
        
        let hasVideo = isFullScreen && (self.tileView != nil || self.mainVideoView != nil)
        
        let isVideo = state?.mode == .video
        
        
        peersTableContainer.setFrameSize(NSMakeSize(substrateRect().width, peersTableContainer.frame.height))
        peersTable.setFrameSize(NSMakeSize(tableRect.width, peersTable.frame.height))
        
        transition.updateFrame(view: peersTable, frame: tableRect)

        transition.updateFrame(view: peersTableContainer, frame: substrateRect())
        if hasVideo {
            if isFullScreen, state?.hideParticipants == true {
                transition.updateFrame(view: controlsContainer, frame: controlsContainer.centerFrameX(y: frame.height - controlsContainer.frame.height + 75))
            } else {
                transition.updateFrame(view: controlsContainer, frame: controlsContainer.centerFrameX(y: frame.height - controlsContainer.frame.height + 75, addition: peersTable.frame.width / 2 + 5))
            }
        } else {
            if isVideo {
                transition.updateFrame(view: controlsContainer, frame: controlsContainer.centerFrameX(y: frame.height - controlsContainer.frame.height + 100))
            } else {
                transition.updateFrame(view: controlsContainer, frame: controlsContainer.centerFrameX(y: frame.height - controlsContainer.frame.height + 50))
            }
        }
        
        let titleRect = NSMakeRect(0, 0, frame.width, 54)
        transition.updateFrame(view: titleView, frame: titleRect)
        titleView.updateLayout(size: titleRect.size, transition: transition)
        
        controlsContainer.updateLayout(size: controlsContainer.frame.size, transition: transition)
        if let mainVideoView = mainVideoView {
            transition.updateFrame(view: mainVideoView, frame: mainVideoRect)
            mainVideoView.updateLayout(size: mainVideoRect.size, transition: transition)
        }
        if let tileView = tileView {
            transition.updateFrame(view: tileView, frame: mainVideoRect)
            tileView.updateLayout(size: mainVideoRect.size, transition: transition)
        }
        
        
        if let scheduleView = self.scheduleView {
            let rect = tableRect
            transition.updateFrame(view: scheduleView, frame: rect)
            scheduleView.updateLayout(size: rect.size, transition: transition)
        }
    }
    
    
    
    private var tableRect: NSRect {
        var size = peersTable.frame.size
        let width = min(frame.width - 40, 600)
        
        if let state = state, !state.videoActive(.main).isEmpty {
            if isFullScreen {
                switch state.layoutMode {
                case .classic:
                    size = NSMakeSize(GroupCallTheme.smallTableWidth, frame.height - 54 - 10)
                case .tile:
                    size = NSMakeSize(GroupCallTheme.tileTableWidth, frame.height - 54 - 10)
                }
            } else {
                size = NSMakeSize(width, frame.height - 180 - mainVideoRect.height)
            }
        } else {
            size = NSMakeSize(width, frame.height - 271)
        }
        var rect = focus(size)
        rect.origin.y = 54
        
        if let state = state, !state.videoActive(.main).isEmpty {
            if !isFullScreen {
                rect.origin.y = mainVideoRect.maxY + 10
            } else {
                rect.origin.x = 10
                rect.origin.y = 54
                
                if state.hideParticipants {
                    rect.origin.x = -(rect.width + 10)
                }
            }
        }
        
        return rect
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        let prevFullScreen = self.isFullScreen
        super.setFrameSize(newSize)
        
        if prevFullScreen != self.isFullScreen, let state = self.state {
            updateUIAfterFullScreenUpdated(state, reloadTable: false)
        }
    }
    
    override func layout() {
        super.layout()
        updateLayout(size: frame.size, transition: .immediate)
    }
    
    var isFullScreen: Bool {
        if let tempVertical = tempFullScreen {
            return tempVertical
        }
        if frame.width >= GroupCallTheme.fullScreenThreshold {
            return true
        }
        return false
    }
    
    var mainVideoRect: NSRect {
        var rect: CGRect
        if isFullScreen, let state = state {
            let tableWidth: CGFloat
            switch state.layoutMode {
            case .classic:
                tableWidth = (GroupCallTheme.smallTableWidth + 20)
            case .tile:
                tableWidth = (GroupCallTheme.tileTableWidth + 20)
            }
            
            if state.hideParticipants, isFullScreen {
                let width = frame.width - 20
                let height = frame.height - 54 - 10
                rect = CGRect(origin: .init(x: 10, y: 54), size: .init(width: width, height: height))
            } else {
                let width = frame.width - tableWidth - 10
                let height = frame.height - 54 - 10
                rect = CGRect(origin: .init(x: tableWidth, y: 54), size: .init(width: width, height: height))
            }
            
        } else {
            let width = min(frame.width - 40, 600)
            rect = focus(NSMakeSize(width, max(200, frame.height - 180 - 200)))
            rect.origin.y = 54
        }
        return rect
    }
    
    var state: GroupCallUIState?
    
    var markWasScheduled: Bool? = false
    
    var tempFullScreen: Bool? = nil
    
    func applyUpdates(_ state: GroupCallUIState, _ transition: TableUpdateTransition, _ call: PresentationGroupCall, animated: Bool) {
                
        let duration: Double = 0.3
        
       
        let previousState = self.state
        if !transition.isEmpty {
            peersTable.merge(with: transition)
        }
        
        if let previousState = previousState {
            if let markWasScheduled = self.markWasScheduled, !state.state.canManageCall {
                if !markWasScheduled {
                    self.markWasScheduled = previousState.state.scheduleState != nil && state.state.scheduleState == nil
                }
                if self.markWasScheduled == true {
                    switch state.state.networkState {
                    case .connecting:
                        return
                    default:
                        self.markWasScheduled = nil
                    }
                }
               
            }
        }
        
        self.state = state

        
        titleView.update(state.peer, state, call.account, recordClick: { [weak self, weak state] in
            if let state = state {
                self?.arguments?.recordClick(state.state)
            }
        }, resizeClick: { [weak self] in
            self?.arguments?.toggleScreenMode()
        }, hidePeersClick: { [weak self] in
            self?.arguments?.togglePeersHidden()
        } , animated: animated)
        controlsContainer.update(state, voiceSettings: state.voiceSettings, audioLevel: state.myAudioLevel, animated: animated)
        
        let transition: ContainedViewLayoutTransition = animated ? .animated(duration: duration, curve: .easeInOut) : .immediate
        
        if let _ = state.state.scheduleTimestamp {
            let current: GroupCallScheduleView
            if let view = self.scheduleView {
                current = view
            } else {
                current = GroupCallScheduleView(frame: tableRect)
                self.scheduleView = current
                addSubview(current)
            }
        } else {
            if let view = self.scheduleView {
                self.scheduleView = nil
                if animated {
                    view.layer?.animateAlpha(from: 1, to: 0, duration: 0.2, removeOnCompletion: false, completion: { [weak view] _ in
                        view?.removeFromSuperview()
                    })
                    view.layer?.animateScaleSpring(from: 1, to: 0.1, duration: 0.3)
                } else {
                    view.removeFromSuperview()
                }
            }
        }
        
        scheduleView?.update(state, arguments: arguments, animated: animated)

        if animated {
            let from: CGFloat = state.state.scheduleTimestamp != nil ? 1 : 0
            let to: CGFloat = state.state.scheduleTimestamp != nil ? 0 : 1
            if previousState?.state.scheduleTimestamp != state.state.scheduleTimestamp {
                let remove: Bool = state.state.scheduleTimestamp != nil
                if !remove {
                    self.addSubview(peersTableContainer)
                    self.addSubview(peersTable)
                }
                self.peersTable.layer?.animateAlpha(from: from, to: to, duration: duration, removeOnCompletion: false, completion: { [weak self] _ in
                    if remove {
                        self?.peersTable.removeFromSuperview()
                        self?.peersTableContainer.removeFromSuperview()
                    }
                })
            }
        } else {
            if state.state.scheduleState != nil {
                peersTable.removeFromSuperview()
                peersTableContainer.removeFromSuperview()
            } else if peersTable.superview == nil {
                addSubview(peersTableContainer)
                addSubview(peersTable)
            }
        }
        
        switch state.layoutMode {
        case .classic:
            if let tileView = self.tileView {
                self.tileView = nil
                if animated {
                    tileView.layer?.animateAlpha(from: 1, to: 0, duration: duration, removeOnCompletion: false, completion: { [weak tileView] _ in
                        tileView?.removeFromSuperview()
                    })
                } else {
                    tileView.removeFromSuperview()
                }
            }
            if let currentDominantSpeakerWithVideo = state.currentDominantSpeakerWithVideo {
                let mainVideo: GroupCallMainVideoContainerView
                var isPresented: Bool = false
                if let video = self.mainVideoView {
                    mainVideo = video
                } else {
                    mainVideo = GroupCallMainVideoContainerView(call: call)
                    mainVideo.frame = mainVideoRect
                    
                    
                    self.mainVideoView = mainVideo
                    addSubview(mainVideo, positioned: .below, relativeTo: titleView)
                    isPresented = true
                }
                
                let member = state.memberDatas.first(where: { $0.peer.id == currentDominantSpeakerWithVideo.peerId})
                
                mainVideo.updatePeer(peer: currentDominantSpeakerWithVideo, participant: member, resizeMode: .resizeAspect, transition: .immediate, animated: animated, controlsMode: self.controlsMode, isFullScreen: state.isFullScreen, isPinned: true, arguments: arguments)
                
                if isPresented && animated {
                    mainVideo.layer?.animateAlpha(from: 0, to: 1, duration: duration)
                    mainVideo.updateLayout(size: mainVideoRect.size, transition: .immediate)
                    mainVideo.frame = mainVideoRect
                    mainVideo.layer?.animateAlpha(from: 0, to: 1, duration: duration)
                }
            } else {
                if let mainVideo = self.mainVideoView{
                    self.mainVideoView = nil
                    if animated {
                        mainVideo.layer?.animateAlpha(from: 1, to: 0, duration: duration, removeOnCompletion: false, completion: { [weak mainVideo] _ in
                            mainVideo?.removeFromSuperview()
                        })
                    } else {
                        mainVideo.removeFromSuperview()
                    }
                }
            }
        case .tile:
            if let mainVideo = self.mainVideoView {
                self.mainVideoView = nil
                if animated {
                    mainVideo.layer?.animateAlpha(from: 1, to: 0, duration: duration, removeOnCompletion: false, completion: { [weak mainVideo] _ in
                        mainVideo?.removeFromSuperview()
                    })
                } else {
                    mainVideo.removeFromSuperview()
                }
            }
            
            if !state.videoActive(.main).isEmpty {
                let current: GroupCallTileView
                if let tileView = self.tileView {
                    current = tileView
                } else {
                    current = GroupCallTileView(call: call, arguments: arguments, frame: mainVideoRect)
                    self.tileView = current
                    addSubview(current, positioned: .below, relativeTo: titleView)
                    if animated {
                        current.layer?.animateAlpha(from: 0, to: 1, duration: duration)
                    }
                }
                current.update(state: state, transition: transition, animated: animated, controlsMode: self.controlsMode)
            } else {
                if let tileView = self.tileView {
                    self.tileView = nil
                    if animated {
                        tileView.layer?.animateAlpha(from: 1, to: 0, duration: duration, removeOnCompletion: false, completion: { [weak tileView] _ in
                            tileView?.removeFromSuperview()
                        })
                    } else {
                        tileView.removeFromSuperview()
                    }
                }
            }
        }

        self.mainVideoView?.updateMode(controlsMode: controlsMode, controlsState: controlsContainer.mode, animated: animated)
        
        updateLayout(size: frame.size, transition: transition)
        updateUIAfterFullScreenUpdated(state, reloadTable: false)

    }
    
    var isVertical: Bool {
        return isFullScreen && state?.currentDominantSpeakerWithVideo != nil && state?.layoutMode == .classic
    }
    
    private func updateUIAfterFullScreenUpdated(_ state: GroupCallUIState, reloadTable: Bool) {
        
        peersTableContainer.isHidden = isVertical
        peersTable.layer?.cornerRadius = isVertical ? 0 : 10
        
        mainVideoView?.layer?.cornerRadius = 10
        
        if let event = NSApp.currentEvent {
            updateMouse(event: event, animated: false, isReal: false)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}