//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import Future

public class ChannelHandlerContext : ChannelInboundInvoker, ChannelOutboundInvoker {

    // visible for ChannelPipeline to modify
    var prev: ChannelHandlerContext?
    var next: ChannelHandlerContext?

    public let handler: ChannelHandler
    public let pipeline: ChannelPipeline
    public let name: String
    
    public var config: ChannelConfig {
        get {
            return pipeline.config
        }
    }
    
    public var allocator: BufferAllocator {
        get {
            return config.allocator
        }
    }
    
    public var eventLoop: EventLoop {
        get {
            return pipeline.eventLoop
        }
    }
    
    // Only created from within ChannelPipeline
    init(name: String, handler: ChannelHandler, pipeline: ChannelPipeline) {
        self.name = name
        self.handler = handler
        self.pipeline = pipeline
    }
    
    public func fireChannelRegistered() {
        next!.invokeChannelRegistered()
    }
    
    public func fireChannelUnregistered() {
        next!.invokeChannelUnregistered()
    }
    
    public func fireChannelActive() {
        next!.invokeChannelActive()
    }
    
    public func fireChannelInactive() {
        next!.invokeChannelInactive()
    }

    public func fireChannelRead(data: Any) {
        next!.invokeChannelRead(data: data)
    }
    
    public func fireChannelReadComplete() {
        next!.invokeChannelReadComplete()
    }

    public func fireChannelWritabilityChanged(writable: Bool) {
        next!.invokeChannelWritabilityChanged(writable: writable)
    }

    public func fireErrorCaught(error: Error) {
        next!.invokeErrorCaught(error: error)
    }
    
    public func fireUserEventTriggered(event: Any) {
        next!.invokeUserEventTriggered(event: event)
    }
    
    public func write(data: Any, promise: Promise<Void>) -> Future<Void> {
        prev!.invokeWrite(data: data, promise: promise)
        return promise.futureResult
    }
    
    public func writeAndFlush(data: Any, promise: Promise<Void>) -> Future<Void> {
        prev!.invokeWriteAndFlush(data: data, promise: promise)
        return promise.futureResult
    }
    
    public func flush() {
        prev!.invokeFlush()
    }
    
    public func read() {
        prev!.invokeRead()
    }
    
    public func close(promise: Promise<Void>) -> Future<Void> {
        prev!.invokeClose(promise: promise)
        return promise.futureResult
    }
    
    // Methods that are invoked itself by this class itself or ChannelPipeline
    func invokeChannelRegistered() {
        assert(inEventLoop)
        
        do {
            try handler.channelRegistered(ctx: self)
        } catch let err {
            safeErrorCaught(ctx: self, error: err)
        }
    }
    
    func invokeChannelUnregistered() {
        assert(inEventLoop)
        
        do {
            try handler.channelUnregistered(ctx: self)
        } catch let err {
            safeErrorCaught(ctx: self, error: err)
        }
    }
    
    func invokeChannelActive() {
        assert(inEventLoop)
        
        do {
            try handler.channelActive(ctx: self)
        } catch let err {
            safeErrorCaught(ctx: self, error: err)
        }
    }
    
    func invokeChannelInactive() {
        assert(inEventLoop)
        
        do {
            try handler.channelInactive(ctx: self)
        } catch let err {
            safeErrorCaught(ctx: self, error: err)
        }
    }
    
    func invokeChannelRead(data: Any) {
        assert(inEventLoop)
        
        do {
            try handler.channelRead(ctx: self, data: data)
        } catch let err {
            safeErrorCaught(ctx: self, error: err)
        }
    }
    
    func invokeChannelReadComplete() {
        assert(inEventLoop)
        
        do {
            try handler.channelReadComplete(ctx: self)
        } catch let err {
            safeErrorCaught(ctx: self, error: err)
        }
    }
    
    func invokeChannelWritabilityChanged(writable: Bool) {
        assert(inEventLoop)
        
        do {
            try handler.channelWritabilityChanged(ctx: self, writable: writable)
        } catch let err {
            safeErrorCaught(ctx: self, error: err)
        }
    }
    
    func invokeErrorCaught(error: Error) {
        assert(inEventLoop)
        
        do {
            try handler.errorCaught(ctx: self, error: error)
        } catch {
            // TODO: What to do ?
        }
    }

    func invokeUserEventTriggered(event: Any) {
        assert(inEventLoop)
        
        do {
            try handler.userEventTriggered(ctx: self, event: event)
        } catch let err {
            safeErrorCaught(ctx: self, error: err)
        }
    }

    func invokeWrite(data: Any, promise: Promise<Void>) {
        assert(inEventLoop)
        
        handler.write(ctx: self, data: data, promise: promise)
    }
    
    func invokeFlush() {
        assert(inEventLoop)
        
        handler.flush(ctx: self)
    }
    
    func invokeWriteAndFlush(data: Any, promise: Promise<Void>) {
        assert(inEventLoop)

        handler.write(ctx: self, data: data, promise: promise)
        handler.flush(ctx: self)
    }
    
    func invokeRead() {
        assert(inEventLoop)
        
        handler.read(ctx: self)
    }
    
    func invokeClose(promise: Promise<Void>) {
        assert(inEventLoop)
        
        handler.close(ctx: self, promise: promise)
    }
    
    func invokeHandlerAdded() throws {
        assert(inEventLoop)

        try handler.handlerAdded(ctx: self)
    }
    
    func invokeHandlerRemoved() throws {
        assert(inEventLoop)

        try handler.handlerRemoved(ctx: self)
    }
    
    private var inEventLoop : Bool {
    get {
        return pipeline.eventLoop.inEventLoop
    }
    }
    
    private func safeErrorCaught(ctx: ChannelHandlerContext, error: Error) {
        do {
            try handler.errorCaught(ctx: ctx, error: error)
        } catch {
            // TOOO: What to do here ?
        }
    }
}
