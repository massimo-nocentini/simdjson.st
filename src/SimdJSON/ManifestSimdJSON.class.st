"
SimdJSON - a JSON reader for Pharo 15 whose parsing is done by simdjson, in the
SimdJSONPlugin of the VM (plugins/SimdJSONPlugin and docs/SimdJSON.md of
https://github.com/massimo-nocentini/pharo-vm, branch pharo-12), with the API of
NeoJSONReader and no other dependency: NeoJSON need not be in the image, and when it is,
SimdJSONReader still has no NeoJSON class in its hierarchy and sends nothing to NeoJSON.
SimdJSONWriter writes JSON as NeoJSONWriter does, byte for byte, with its protocol and
the writing side of the mappings: the plugin's primitiveWrite writes the plain data (nil,
Booleans, numbers, strings, Array, OrderedCollection, Dictionary), and leaves the other
objects to the writer, which writes them as NeoJSONWriter would.

SimdJSONReader is a subclass of SimdJSONMapper, a port of NeoJSON's mapper and mapping
classes (the reading side).  It is strict RFC 8259: what simdjson refuses, NeoJSON's
leniencies included (01, 1., a control character in a string), raises
SimdJSONParseError.  Load it, alone, with:

	Metacello new
		baseline: 'SimdJSON';
		repository: 'github://massimo-nocentini/simdjson.st:master/src';
		load: 'Core'

The primitive (primitiveRead) answers a whole value at a time: either Dictionaries and
Arrays built in C, when the reader is configured as NeoJSON's defaults, or a tree of
Arrays and SimdJSONFlatMaps (k1 v1 k2 v2 ...) that the reader turns into mapClass and
listClass instances, or walks as a cursor for the mappings.  Numbers whose token has an
exponent, and integers beyond 64 bits, come back as their text, which NeoJSON's rules
convert, so 1e2 is 100 and 1e-2 is 1/100.

The classes SimdJSONMapper, SimdJSONMapping, SimdJSONObjectMapping, SimdJSONCustomMapping,
SimdJSONPropertyMapping and SimdJSONMappingNotFound, and SimdJSONNumberParser, are ports
of NeoJSON (https://github.com/svenvc/NeoJSON), under its MIT licence:

	Copyright (C) 2012 Sven Van Caekenberghe

	Permission is hereby granted, free of charge, to any person obtaining a copy of this
	software and associated documentation files (the 'Software'), to deal in the Software
	without restriction, including without limitation the rights to use, copy, modify,
	merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
	permit persons to whom the Software is furnished to do so, subject to the following
	conditions:

	The above copyright notice and this permission notice shall be included in all copies
	or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
	INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
	PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
	CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
	OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"
Class {
	#name : 'ManifestSimdJSON',
	#superclass : 'PackageManifest',
	#category : 'SimdJSON-Manifest',
	#package : 'SimdJSON',
	#tag : 'Manifest'
}
