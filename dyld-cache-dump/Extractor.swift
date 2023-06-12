/*******************************************************************************
 * The MIT License (MIT)
 *
 * Copyright (c) 2023, Jean-David Gadina - www.xs-labs.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the Software), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

import Cocoa
import Darwin

public class Extractor
{
    private static let extractorBundlePath = "/usr/lib/dsc_extractor.bundle"
    private static let extractorFuncName   = "dyld_shared_cache_extract_dylibs_progress"

    private typealias ExtractorFuncType = @convention( c ) ( UnsafePointer< CChar >, UnsafePointer< CChar >, ( Int32, Int32 ) -> Void ) -> Void

    private var extractorFunc: ExtractorFuncType

    public init() throws
    {
        guard let handle = dlopen( Extractor.extractorBundlePath, RTLD_LAZY )
        else
        {
            throw "Cannot open \( Extractor.extractorBundlePath )"
        }

        guard let symbol = dlsym( handle, Extractor.extractorFuncName )
        else
        {
            throw "Cannot load \( Extractor.extractorFuncName ) from \( Extractor.extractorBundlePath )"
        }

        self.extractorFunc = unsafeBitCast( symbol, to: ExtractorFuncType.self )
    }

    public func extract( cache: URL, to destination: URL, progress: ( ( Int32, Int32 ) -> Void )? ) throws
    {
        guard FileManager.default.fileExists( atPath: cache.path( percentEncoded: false ) )
        else
        {
            throw "Cache file does not exist at \( cache.path( percentEncoded: false ) )"
        }

        var isDir: ObjCBool = false

        if FileManager.default.fileExists( atPath: destination.path( percentEncoded: false ), isDirectory: &isDir )
        {
            if isDir.boolValue == false
            {
                throw "Cannot use existing file \( destination.path( percentEncoded: false ) ) as destination"
            }

            try self.recylce( url: destination )
        }

        self.extractorFunc( cache.path( percentEncoded: false ), destination.path( percentEncoded: false ) )
        {
            progress?( $0 + 1, $1 )
        }
    }

    private func recylce( url: URL ) throws
    {
        let group       = DispatchGroup()
        var recycleError: Error?

        group.enter()

        DispatchQueue.global( qos: .userInitiated ).async
        {
            NSWorkspace.shared.recycle( [ url ] )
            {
                urls, error in

                recycleError = error

                group.leave()
            }
        }

        group.wait()

        if let error = recycleError
        {
            throw error
        }
    }
}
