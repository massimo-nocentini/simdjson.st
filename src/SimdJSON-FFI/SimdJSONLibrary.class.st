"
I am libSimdJSONFFI, the engine of the SimdJSONPlugin built as a library of its own, which I call through the FFI of the image (plugins/SimdJSONPlugin/include/ffi/sjFFI.h of https://github.com/massimo-nocentini/pharo-vm has the contract).

SimdJSONReader and SimdJSONWriter go through me when the VM has no SimdJSONPlugin (SimdJSONReader class>>fallback).  I answer read:from:to:flags:maxUnits: as primitiveRead answers primRead:, with simdjson's parse, but the objects are made in the image, by SimdJSONTapeDecoder, from the tape that the library writes.  I answer write:flags:newLine:level:maxDepth:maxBytes: as primitiveWrite answers primWrite:, the same text, but the value is walked in the image, by SimdJSONTapeEncoder, which writes a tape from which the library writes the JSON.  Both are faster than NeoJSON, and slower than the plugin.

I look for the library in the directories of the VM, the image and the system (FFIUnix64LibraryFinder and the like), as libSimdJSONFFI.so, libSimdJSONFFI.dylib or libSimdJSONFFI.dll; libraryPath: names it instead, before the first read of a session.
"
Class {
	#name : 'SimdJSONLibrary',
	#superclass : 'FFILibrary',
	#classVars : [
		'Availability',
		'LibraryPath',
		'Scratch',
		'ScratchTape',
		'ScratchWords'
	],
	#category : 'SimdJSON-FFI-Library',
	#package : 'SimdJSON-FFI',
	#tag : 'Library'
}

{ #category : 'encodings' }
SimdJSONLibrary class >> encodingLatin1 [
	"SJ_ENC_LATIN1 of sjBridge.h: a ByteString, in place"

	^ 1

]

{ #category : 'encodings' }
SimdJSONLibrary class >> encodingUTF32 [
	"SJ_ENC_UTF32 of sjBridge.h: a WideString, in place"

	^ 2

]

{ #category : 'encodings' }
SimdJSONLibrary class >> encodingUTF8 [
	"SJ_ENC_UTF8 of sjBridge.h: a ByteArray, in place"

	^ 0

]

{ #category : 'reading' }
SimdJSONLibrary class >> errorMessage: code [
	"simdjson's message of the error code, or nil"

	^ self uniqueInstance errorMessage: code

]

{ #category : 'accessing' }
SimdJSONLibrary class >> implementationName [
	"The simdjson kernel: haswell, westmere, arm64, fallback..."

	^ self uniqueInstance primImplementation

]

{ #category : 'testing' }
SimdJSONLibrary class >> isAvailable [
	"Whether the library is found and speaks my protocol, asked once a session"

	(Availability notNil and: [ Availability first == Smalltalk session ])
		ifTrue: [ ^ Availability last ].
	Availability := {
		Smalltalk session.
		[ self uniqueInstance primProtocol = self protocol ]
			on: Error
			do: [ :error | error return: false ] }.
	^ Availability last

]

{ #category : 'accessing' }
SimdJSONLibrary class >> libraryPath [
	"The path of the library, or nil when it is looked for"

	^ LibraryPath

]

{ #category : 'accessing' }
SimdJSONLibrary class >> libraryPath: aStringOrNil [
	"The path of the library, nil to look for it; before the first read of a session (the
	callouts keep the library they found)"

	LibraryPath := aStringOrNil.
	Availability := nil

]

{ #category : 'accessing' }
SimdJSONLibrary class >> protocol [
	"The version of sjFFI.h that I speak (SJ_FFI_PROTOCOL); a library that answers another
	one is not used"

	^ 1

]

{ #category : 'reading' }
SimdJSONLibrary class >> read: source from: start to: stop flags: flags maxUnits: maxUnits [
	^ self uniqueInstance read: source from: start to: stop flags: flags maxUnits: maxUnits

]

{ #category : 'writing' }
SimdJSONLibrary class >> write: anObject flags: flags newLine: aByteString level: level maxDepth: depth maxBytes: maxBytes [
	^ self uniqueInstance
		write: anObject flags: flags newLine: aByteString level: level maxDepth: depth maxBytes: maxBytes

]

{ #category : 'reading' }
SimdJSONLibrary class >> releaseParser [
	"Free the memory of the parser of the library; the next read allocates it again"

	self uniqueInstance primRelease: 1

]

{ #category : 'private' }
SimdJSONLibrary class >> scratchSize [
	"The bytes of the buffer that a read is given: the answer, and the tape of a value that
	fits; a larger tape is copied into a ByteArray of its size"

	^ 65536

]

{ #category : 'accessing' }
SimdJSONLibrary class >> simdjsonVersion [

	^ self uniqueInstance primSimdjsonVersion

]

{ #category : 'reading' }
SimdJSONLibrary >> errorMessage: code [

	^ (self primErrorMessage: code) ifEmpty: [ nil ]

]

{ #category : 'private' }
SimdJSONLibrary >> libraryNamed: aString finder: aFinderClass [

	^ LibraryPath ifNil: [ aFinderClass findLibrary: aString ]

]

{ #category : 'accessing - platform' }
SimdJSONLibrary >> macLibraryName [

	^ self libraryNamed: 'libSimdJSONFFI.dylib' finder: FFIMacLibraryFinder

]

{ #category : 'primitives' }
SimdJSONLibrary >> primErrorMessage: code [

	^ self ffiCall: #( String sj_ffi_error_message ( int64 code ) )

]

{ #category : 'primitives' }
SimdJSONLibrary >> primImplementation [

	^ self ffiCall: #( String sj_ffi_implementation ( ) )

]

{ #category : 'primitives' }
SimdJSONLibrary >> primProtocol [

	^ self ffiCall: #( int64 sj_ffi_protocol ( ) )

]

{ #category : 'primitives' }
SimdJSONLibrary >> primRead: source encoding: encoding units: units start0: start0 stop0: stop0 flags: flags maxUnits: maxUnits buffer: buffer capacity: capacity [

	^ self ffiCall: #( int64 sj_ffi_read ( void * source , int64 encoding , int64 units , int64 start0 , int64 stop0 , int64 flags , int64 maxUnits , void * buffer , int64 capacity ) )

]

{ #category : 'primitives' }
SimdJSONLibrary >> primRelease: freeParser [

	^ self ffiCall: #( void sj_ffi_release ( int64 freeParser ) )

]

{ #category : 'primitives' }
SimdJSONLibrary >> primSimdjsonVersion [

	^ self ffiCall: #( String sj_ffi_simdjson_version ( ) )

]

{ #category : 'primitives' }
SimdJSONLibrary >> primTakeOutput: holes count: holeCount output: output bytes: outputBytes ticket: ticket [

	^ self ffiCall: #( int64 sj_ffi_take_output ( void * holes , int64 holeCount , void * output , int64 outputBytes , int64 ticket ) )

]

{ #category : 'primitives' }
SimdJSONLibrary >> primWrite: tape size: tapeSize words: words count: wordCount flags: flags newLine: newLine size: newLineSize level: level maxBytes: maxBytes buffer: buffer capacity: capacity [

	^ self ffiCall: #( int64 sj_ffi_write ( void * tape , int64 tapeSize , void * words , int64 wordCount , int64 flags , void * newLine , int64 newLineSize , int64 level , int64 maxBytes , void * buffer , int64 capacity ) )

]

{ #category : 'primitives' }
SimdJSONLibrary >> primTake: tape size: size words: words count: count ticket: ticket [

	^ self ffiCall: #( int64 sj_ffi_take ( void * tape , int64 size , void * words , int64 count , int64 ticket ) )

]

{ #category : 'reading' }
SimdJSONLibrary >> read: source from: start to: stop flags: flags maxUnits: maxUnits [
	"The JSON value at start in source (a String, or UTF-8 bytes), as SimdJSONReader
	class>>primRead:... answers it: { status. value. nextIndex. fixups. nil. code }, with
	Dictionaries for flagDict and Symbol keys for flagSymbolKeys; or a SimdJSONFailure.
	A read takes the scratch buffer, so that another process reading meanwhile makes one of
	its own"

	| buffer |
	(self refusalOf: source from: start to: stop flags: flags maxUnits: maxUnits)
		ifNotNil: [ :code | ^ SimdJSONFailure on: code ].
	buffer := Scratch.
	Scratch := nil.
	buffer ifNil: [ buffer := ByteArray new: self class scratchSize ].
	^ [ self read: (self passable: source) from: start to: stop flags: flags maxUnits: maxUnits buffer: buffer ]
		ensure: [ Scratch := buffer ]

]

{ #category : 'private' }
SimdJSONLibrary >> read: source from: start to: stop flags: flags maxUnits: maxUnits buffer: buffer [
	"sjFFI.h: the answer is in the first 64 bytes of buffer, and the tape after them when
	it fits; else, and for the words of the WideStrings, sj_ffi_take copies them, unless
	another read came in between (another process): then read again"

	| rc status tape offset count next words decoder result |
	[
		rc := self
			primRead: source encoding: source simdJSONEncoding units: source size
			start0: start - 1 stop0: stop flags: flags maxUnits: maxUnits
			buffer: buffer capacity: buffer size.
		rc = -2 ifTrue: [ ^ SimdJSONFailure on: #'insufficient C memory' ].
		rc = 0 ifFalse: [ ^ SimdJSONFailure on: #'bad argument' ].
		status := buffer int64AtOffset: 0.
		status = 0 ifFalse: [
			^ { status. nil. (buffer int64AtOffset: 16) + 1. nil. nil. buffer int64AtOffset: 8 } ].
		next := (buffer int64AtOffset: 16) + 1.
		count := buffer int64AtOffset: 48.
		(buffer int64AtOffset: 40) = 1
			ifTrue: [
				tape := buffer.
				offset := 64 ]
			ifFalse: [
				self roomFor: (buffer int64AtOffset: 24).
				tape := ByteArray new: (buffer int64AtOffset: 24).
				offset := 0 ].
		(tape == buffer and: [ count = 0 ]) or: [
			words := self takeWords: count.
			[ (self
				primTake: tape size: (tape == buffer ifTrue: [ 0 ] ifFalse: [ tape size ])
				words: words count: count
				ticket: (buffer int64AtOffset: 32)) = 0 ]
					ensure: [ self giveWords: words ] ] ] whileFalse.
	decoder := SimdJSONTapeDecoder new.
	result := { 0. decoder decode: tape at: offset words: words flags: flags. next. nil. nil. 0 }.
	result at: 4 put: (decoder fixupsFor: result).
	^ result

]

{ #category : 'private' }
SimdJSONLibrary >> giveWords: aWordArray [
	"Give back the WordArray of takeWords:, the largest one kept"

	(ScratchWords isNil or: [ ScratchWords size < aWordArray size ])
		ifTrue: [ ScratchWords := aWordArray ]

]

{ #category : 'private' }
SimdJSONLibrary >> giveTape: aByteArray [
	"Keep the tape of a write for the next one, up to 16 MB, the largest one kept"

	aByteArray size > 16777216 ifTrue: [ ^ self ].
	(ScratchTape isNil or: [ ScratchTape size < aByteArray size ])
		ifTrue: [ ScratchTape := aByteArray ]

]

{ #category : 'private' }
SimdJSONLibrary >> roomFor: bytes [
	"Before a large object is allocated (a tape, an output): when the free old space is
	under twice its size, grow the memory by twice its size.  new: of an object that does
	not fit collects all the garbage first (handleFailingBasicNew:), where the plugin, which
	allocates in the VM, grows the memory; growing by twice the size spares most of those
	collections (one in ten writes of 12 MB, rather than nine) and leaves the rest to the
	VM's own policy"

	| free room |
	bytes < 1048576 ifTrue: [ ^ self ].
	room := 2 * bytes + 4194304.
	free := Smalltalk vm parameterAt: 54.
	(free isInteger and: [ free < room ]) ifTrue: [ Smalltalk growMemoryByAtLeast: room ]

]

{ #category : 'private' }
SimdJSONLibrary >> takeTape [
	"A ByteArray for the tape of a write, kept between writes, taken while one uses it"

	| tape |
	tape := ScratchTape.
	ScratchTape := nil.
	^ tape ifNil: [ ByteArray new: 4096 ]

]

{ #category : 'private' }
SimdJSONLibrary >> takeWords: count [
	"A WordArray of at least count words, which the FFI pins: kept between reads, and taken
	while one uses it, so that another process makes one of its own"

	| words |
	words := ScratchWords.
	ScratchWords := nil.
	(words isNil or: [ words size < count ]) ifTrue: [
		words := WordArray new: ((count max: 1024) asLargerPowerOfTwo) ].
	^ words

]

{ #category : 'private' }
SimdJSONLibrary >> passable: source [
	"source, or a copy that the FFI passes as a pointer, with its simdJSONEncoding: a String
	of another class than ByteString and WideString (a Symbol) is copied, in characters
	(its simdJSONPassableCopy)"

	source simdJSONEncoding ifNotNil: [ ^ source ].
	^ source simdJSONPassableCopy

]

{ #category : 'private' }
SimdJSONLibrary >> refusalOf: source from: start to: stop flags: flags maxUnits: maxUnits [
	"nil, or the error code that primitiveRead fails with for these arguments, in its order:
	the source a String or a ByteArray (its simdJSONSourceKind), the numbers integers,
	start..stop in it, and not both flagDict and flagSymbolKeys"

	source simdJSONSourceKind ifNil: [ ^ #'bad argument' ].
	((start isInteger and: [ stop isInteger ])
		and: [ (flags isInteger and: [ flags >= 0 ])
		and: [ maxUnits isInteger and: [ maxUnits >= -1 ] ] ])
			ifFalse: [ ^ #'bad argument' ].
	(start < 1 or: [ start > (stop + 1) or: [ stop > source size ] ]) ifTrue: [ ^ #'bad index' ].
	(flags > 15 or: [ (flags bitAnd: 12) = 12 ]) ifTrue: [ ^ #'bad argument' ].
	^ nil

]

{ #category : 'writing' }
SimdJSONLibrary >> write: anObject flags: flags newLine: aByteString level: level maxDepth: depth maxBytes: maxBytes [
	"The JSON of anObject, as SimdJSONWriter class>>primWrite:... answers it: { status.
	output. holes. code. culprit }, or a SimdJSONFailure; arguments that primitiveWrite
	refuses fail with #'bad argument', as primitiveWrite checks them: SmallIntegers, level
	and depth up to 100000, and aByteString passed in place as Latin-1, exactly a ByteString"

	| buffer encoder |
	(flags isInteger and: [ flags between: 0 and: 31 ]) ifFalse: [ ^ SimdJSONFailure on: #'bad argument' ].
	((level isInteger and: [ level between: 0 and: 100000 ])
		and: [ (depth isInteger and: [ depth between: 0 and: 100000 ])
		and: [ maxBytes isInteger and: [ maxBytes between: -1 and: SmallInteger maxVal ] ] ])
			ifFalse: [ ^ SimdJSONFailure on: #'bad argument' ].
	aByteString simdJSONEncoding = self class encodingLatin1 ifFalse: [ ^ SimdJSONFailure on: #'bad argument' ].
	buffer := Scratch.
	Scratch := nil.
	buffer ifNil: [ buffer := ByteArray new: self class scratchSize ].
	^ [
		encoder := SimdJSONTapeEncoder new.
		encoder
			encode: anObject level: level maxDepth: depth floatHoles: (flags anyMask: 16)
			on: self takeTape words: (self takeWords: 0).
		self write: encoder flags: flags newLine: aByteString level: level maxBytes: maxBytes buffer: buffer ]
			ensure: [
				Scratch := buffer.
				encoder ifNotNil: [
					self giveTape: encoder tape.
					encoder words ifNotNil: [ :words | self giveWords: words ] ] ]

]

{ #category : 'private' }
SimdJSONLibrary >> write: encoder flags: flags newLine: aByteString level: level maxBytes: maxBytes buffer: buffer [
	"sjFFI.h: the answer is in the first 128 bytes of buffer, then the holes and the output
	when they fit; else sj_ffi_take_output copies them, unless another write came in
	between (another process): then write again"

	| rc status kind units bytes holeCount holes holesAt output objects |
	objects := encoder objects.

	[
		rc := self
			primWrite: encoder tape size: encoder position
			words: (encoder words ifNil: [ buffer ]) count: encoder wordPosition
			flags: (flags bitAnd: 15) newLine: aByteString size: aByteString size
			level: level maxBytes: maxBytes buffer: buffer capacity: buffer size.
		rc = -2 ifTrue: [ ^ SimdJSONFailure on: #'insufficient C memory' ].
		rc = 0 ifFalse: [ ^ SimdJSONFailure on: #'bad argument' ].
		status := buffer int64AtOffset: 0.
		status = 2 ifTrue: [
			^ { 2. nil. nil. buffer int64AtOffset: 8. objects at: (buffer int64AtOffset: 16) } ].
		status = 3 ifTrue: [ ^ { 3. nil. nil. 0. nil } ].
		kind := buffer int64AtOffset: 24.
		units := buffer int64AtOffset: 32.
		bytes := buffer int64AtOffset: 40.
		holeCount := buffer int64AtOffset: 48.
		(buffer int64AtOffset: 56) = 1
			ifTrue: [
				holes := buffer.
				holesAt := 128.
				output := self output: kind units: units from: buffer at: 128 + (24 * holeCount) ]
			ifFalse: [
				"copied into the output itself: a ByteArray, a ByteString or a WideString"
				holes := ByteArray new: (24 * holeCount max: 8).
				holesAt := 0.
				self roomFor: bytes.
				output := (kind = 0 ifTrue: [ ByteArray ] ifFalse: [ kind = 1 ifTrue: [ ByteString ] ifFalse: [ WideString ] ])
					new: units.
				(self
					primTakeOutput: holes count: holeCount
					output: (bytes = 0 ifTrue: [ buffer ] ifFalse: [ output ]) bytes: bytes
					ticket: (buffer int64AtOffset: 64)) = 0
						ifFalse: [ output := nil ] ].
		output isNil ] whileTrue.
	^ {
		0.
		output.
		holeCount = 0 ifTrue: [ nil ] ifFalse: [
			(1 to: holeCount) flatCollect: [ :i | | at |
				at := holesAt + (24 * (i - 1)).
				{ holes int64AtOffset: at. objects at: (holes int64AtOffset: at + 8). holes int64AtOffset: at + 16 } ] ].
		0.
		nil }

]

{ #category : 'private' }
SimdJSONLibrary >> output: kind units: units from: source at: offset [
	"The output of sj_ffi_write that follows the answer in buffer: a ByteArray of UTF-8
	(kind 0) or a ByteString (1)"

	| output |
	output := (kind = 0 ifTrue: [ ByteArray ] ifFalse: [ ByteString ]) new: units.
	units > 0 ifTrue: [ output replaceFrom: 1 to: units with: source startingAt: offset + 1 ].
	^ output

]

{ #category : 'accessing - platform' }
SimdJSONLibrary >> unix64LibraryName [

	^ self unixLibraryName

]

{ #category : 'accessing - platform' }
SimdJSONLibrary >> unixLibraryName [

	^ self libraryNamed: 'libSimdJSONFFI.so' finder: FFIUnix64LibraryFinder

]

{ #category : 'accessing - platform' }
SimdJSONLibrary >> win32LibraryName [

	^ LibraryPath ifNil: [ FFIWindowsLibraryFinder findAnyLibrary: #( 'libSimdJSONFFI.dll' 'SimdJSONFFI.dll' ) ]

]
