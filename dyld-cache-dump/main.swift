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

import Foundation

do
{
    guard let source = Arguments.shared.source, let destination = Arguments.shared.destination
    else
    {
        print( "Usage: \( Arguments.shared.executable ) SOURCE DESTINATION" )
        exit( EXIT_FAILURE )
    }

    var extracted: Int32 = 0

    try Extractor().extract( cache: URL( filePath: source ), to: URL( filePath: destination ) )
    {
        let percent = ( Double( $0 ) / Double( $1 ) ) * 100

        print( "Extracting DYLD shared cache: \( $0 ) of \( $1 ) - \( String( format: "%.0f", percent ) )%", terminator: "\r" )
        fflush( stdout )

        extracted = $0
    }

    print( "Extracted \( extracted ) files from \( source )" )
}
catch
{
    print( "Error: \( error )" )
    exit( EXIT_FAILURE )
}
