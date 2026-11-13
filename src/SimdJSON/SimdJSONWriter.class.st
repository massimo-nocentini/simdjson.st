Class {
	#name : 'SimdJSONWriter',
	#superclass : 'SimdJSONMapper',
	#instVars : [
		'writeStream',
		'prettyPrint',
		'asciiOnly',
		'newLine',
		'writeNil',
		'nonFiniteAsNull',
		'level',
		'floatPrinter',
		'sink',
		'binary',
		'classes',
		'layout',
		'ownWriters',
		'budget'
	],
	#classVars : [
		'MaxOutputBytes'
	],
	#category : 'SimdJSON-Writing',
	#package : 'SimdJSON',
	#tag : 'Writing'
}

{ #category : 'primitives' }
SimdJSONWriter class >> flagAsciiOnly [
	^ 2

]

{ #category : 'primitives' }
SimdJSONWriter class >> flagBytes [
	"primWrite: flag: a ByteArray of UTF-8, else the narrowest String"

	^ 4

]

{ #category : 'primitives' }
SimdJSONWriter class >> flagFloatHoles [
	"primWrite: flag: leave the Floats to the image (a floatPrinter of its own)"

	^ 16

]

{ #category : 'primitives' }
SimdJSONWriter class >> flagNonFiniteNull [
	^ 8

]

{ #category : 'primitives' }
SimdJSONWriter class >> flagPretty [
	^ 1

]

{ #category : 'configuration' }
SimdJSONWriter class >> maxDepth [
	"The deepest nesting written: deeper, the value is likely a cycle"

	^ 1024

]

{ #category : 'configuration' }
SimdJSONWriter class >> maxOutputBytes [
	"The most bytes of UTF-8 that one write writes, holes and all (the whole of toString:,
	toBytes: or one nextPut:; each element of nextPutAll:), or nil (the default) for no cap;
	above it, writing signals SimdJSONResourceError before the bytes that would pass it"

	^ MaxOutputBytes

]

{ #category : 'configuration' }
SimdJSONWriter class >> maxOutputBytes: anIntegerOrNil [
	"nil, or a negative number as the -1 of primitiveWrite, for no cap; a cap beyond the
	SmallIntegers that primitiveWrite takes is the largest of them, which no output reaches"

	MaxOutputBytes := (anIntegerOrNil isNil or: [ anIntegerOrNil < 0 ])
		ifFalse: [ anIntegerOrNil min: SmallInteger maxVal ]

]

{ #category : 'instance creation' }
SimdJSONWriter class >> on: aWriteStream [
	"A stream of characters gets characters, a binary stream the bytes of UTF-8, and a
	ZnCharacterWriteStream of UTF-8 (a file, a socket) the bytes the plugin writes, on the
	binary stream it wraps"

	^ self new
		on: aWriteStream;
		yourself

]

{ #category : 'primitives' }
SimdJSONWriter class >> primWrite: value flags: flags newLine: aByteString level: level maxDepth: depth maxBytes: bytes
		classes: classes layout: layout [
	"The JSON of value, as { status. output. holes. code. culprit }; docs/SimdJSON.md,
	Primitive contract, has the whole contract"

	<primitive: 'primitiveWrite' module: 'SimdJSONPlugin' error: ec>
	^ SimdJSONFailure on: ec

]

{ #category : 'convenience' }
SimdJSONWriter class >> toBytes: anObject [
	"The UTF-8 bytes of toString:, made at once"

	^ self new bytesFor: anObject

]

{ #category : 'convenience' }
SimdJSONWriter class >> toString: anObject [
	"What NeoJSONWriter toString: answers, the same characters"

	^ self new stringFor: anObject

]

{ #category : 'convenience' }
SimdJSONWriter class >> toStringPretty: anObject [
	^ self new
		prettyPrint: true;
		stringFor: anObject

]

{ #category : 'configuration' }
SimdJSONWriter class >> writeClasses [
	"The classes that primitiveWrite knows besides those of the VM's proxy.  The exact
	classes it writes are listed again, one method each, by the isSimdJSONPlain of this
	package and the simdJSONTapeOn:level: of SimdJSON-FFI: they change with it"

	^ { ByteSymbol. WideString. WideSymbol. Dictionary. Association. OrderedCollection }

]

{ #category : 'configuration' }
SimdJSONWriter class >> writeLayout [
	"The 0-based slots, 4 bits each: SimdJSONReader dictLayout (Dictionary tally and array,
	Association key and value), then OrderedCollection array, firstIndex and lastIndex"

	| indexes |
	indexes := #( #array #firstIndex #lastIndex ) collect: [ :each |
		(OrderedCollection allInstVarNames indexOf: each) - 1 ].
	(indexes anySatisfy: [ :each | each < 0 or: [ each > 15 ] ])
		ifTrue: [ ^ SimdJSONResourceError new signal: 'the slots of OrderedCollection are not array, firstIndex and lastIndex' ].
	^ SimdJSONReader dictLayout
		+ (indexes first << 16) + (indexes second << 20) + (indexes third << 24)

]

{ #category : 'initialize-release' }
SimdJSONWriter >> asciiOnly: aBoolean [
	"Escape every character above 126 as \uXXXX (a surrogate pair beyond U+FFFF)"

	asciiOnly := aBoolean

]

{ #category : 'writing' }
SimdJSONWriter >> bytesFor: anObject [
	"The JSON of anObject in UTF-8"

	^ self output: anObject bytes: true

]

{ #category : 'private' }
SimdJSONWriter >> callPrim: anObject flags: flags [
	"One write by the plugin, or by the fallback of SimdJSONReader (SimdJSON-FFI) without
	it, which answers the same Array"

	| bytes |
	"what the write has left of maxOutputBytes, -1 without a cap"
	bytes := budget ifNil: [ MaxOutputBytes ifNil: [ -1 ] ].
	SimdJSONReader pluginAvailable ifFalse: [
		^ SimdJSONReader fallback
			ifNil: [ SimdJSONFailure on: nil ]
			ifNotNil: [ :fallback |
				fallback
					write: anObject flags: flags newLine: newLine asString asByteString level: level
					maxDepth: self class maxDepth maxBytes: bytes ] ].
	^ self class
		primWrite: anObject flags: flags newLine: newLine asString asByteString level: level
		maxDepth: self class maxDepth maxBytes: bytes
		classes: (classes ifNil: [ classes := self class writeClasses ])
		layout: (layout ifNil: [ layout := self class writeLayout ])

]

{ #category : 'private' }
SimdJSONWriter >> capped: aBlock [
	"Evaluate aBlock, a write that no other contains, counting what it writes against
	maxOutputBytes; the writing methods test budget and MaxOutputBytes themselves, inline,
	since that test is on the path of every value.  An exception that leaves the write
	finds the budget put aside, before the handlers outside it run: what they write on me
	is a write of its own, with the whole cap.  The write gets back what it had left on
	every way back into it: a handler that resumes, or resumeUnchecked: and resignalAs:,
	which go straight back to the signal; one that returns ends the write anyway"

	budget := MaxOutputBytes.
	^ [ aBlock
			on: Exception
			do: [ :exception | | left value |
				left := budget.
				budget := nil.
				value := [ exception outer ] ensure: [ budget := left ].
				exception resume: value ] ]
		ensure: [ budget := nil ]

]

{ #category : 'private' }
SimdJSONWriter >> charge: aNumber [
	"aNumber bytes, about to be written: refused when they exceed what the write has left,
	which then stays as it was, never under 0"

	aNumber > budget ifTrue: [ ^ self tooLarge ].
	budget := budget - aNumber

]

{ #category : 'initialize-release' }
SimdJSONWriter >> close [
	writeStream ifNotNil: [
		writeStream close.
		writeStream := sink := nil ]

]

{ #category : 'private' }
SimdJSONWriter >> emit: aString [
	"ASCII text of the writer itself, a byte a character"

	budget ifNotNil: [ self charge: aString size ].
	sink nextPutAll: (binary ifTrue: [ aString asByteArray ] ifFalse: [ aString ])

]

{ #category : 'private' }
SimdJSONWriter >> emitOutput: r [
	"The output of a call of primitiveWrite on the stream, with its holes written in; counted
	whole before its first byte, so that the holes get what is left"

	| output holes from |
	output := r at: 2.
	budget ifNotNil: [ self charge: output simdJSONUTF8Size ].
	(holes := r at: 3) ifNil: [ ^ sink nextPutAll: output ].
	from := 0.
	1 to: holes size by: 3 do: [ :i | | saved |
		sink next: (holes at: i) - from putAll: output startingAt: from + 1.
		saved := level.
		level := holes at: i + 2.
		self writeOther: (holes at: i + 1).
		level := saved.
		from := holes at: i ].
	sink next: output size - from putAll: output startingAt: from + 1

]

{ #category : 'writing' }
SimdJSONWriter >> encodeKey: key [
	key isString ifFalse: [ ^ self signalError: 1 culprit: key ].
	self nextPut: key.
	self prettyPrintSpace.
	self emit: ':'.
	self prettyPrintSpace

]

{ #category : 'writing' }
SimdJSONWriter >> encodeKey: key value: value [
	self encodeKey: key.
	self nextPut: value

]

{ #category : 'writing' }
SimdJSONWriter >> encodeKey: key value: value as: valueSchema [
	self encodeKey: key.
	self nextPut: value as: valueSchema

]

{ #category : 'private' }
SimdJSONWriter >> failed: aFailure [
	aFailure isUnavailable ifTrue: [
		^ SimdJSONResourceError new
			code: #'not found';
			signal: 'SimdJSONPlugin not available, or without primitiveWrite' ].
	aFailure isNoCMemory ifTrue: [
		^ SimdJSONResourceError new
			code: #'insufficient C memory';
			signal: 'SimdJSONPlugin: out of C memory' ].
	aFailure isNoMemory ifTrue: [ ^ OutOfMemory signal ].
	^ self primitiveFailed

]

{ #category : 'private' }
SimdJSONWriter >> flagsBytes: aBoolean [
	| class |
	class := self class.
	^ (prettyPrint ifTrue: [ class flagPretty ] ifFalse: [ 0 ])
		+ (asciiOnly ifTrue: [ class flagAsciiOnly ] ifFalse: [ 0 ])
		+ (aBoolean ifTrue: [ class flagBytes ] ifFalse: [ 0 ])
		+ (nonFiniteAsNull ifTrue: [ class flagNonFiniteNull ] ifFalse: [ 0 ])
		+ (floatPrinter ifNil: [ 0 ] ifNotNil: [ class flagFloatHoles ])

]

{ #category : 'initialize-release' }
SimdJSONWriter >> floatPrinter: anObject [
	"An object that answers printFloat:on:, which then writes every Float, in ASCII as JSON
	wants it (written a byte a character, not encoded); nil (the default) writes them as
	Float>>printOn: does, in the plugin"

	floatPrinter := anObject

]

{ #category : 'private' }
SimdJSONWriter >> hasOwnWriter: anObject [
	"Whether the class of anObject writes itself with neoJsonOn: (NeoJSON's protocol), with a
	method of its own rather than one of NeoJSON's, whose output is this writer's"

	ownWriters ifNil: [ ownWriters := IdentityDictionary new ].
	^ ownWriters at: anObject class ifAbsentPut: [
		(anObject class lookupSelector: #neoJsonOn:)
			ifNil: [ false ]
			ifNotNil: [ :method | (method package name asString beginsWith: 'Neo-JSON') not ] ]

]

{ #category : 'writing' }
SimdJSONWriter >> indentedDo: aBlock [
	level := level + 1.
	level > self class maxDepth ifTrue: [
		level := level - 1.
		^ self signalError: 3 culprit: nil ].
	aBlock value.
	level := level - 1

]

{ #category : 'initialize-release' }
SimdJSONWriter >> initialize [
	super initialize.
	prettyPrint := asciiOnly := writeNil := nonFiniteAsNull := binary := false.
	newLine := OSPlatform current lineEnding.
	level := 0

]

{ #category : 'private' }
SimdJSONWriter >> isPlain: anObject [
	"Whether the plugin writes anObject itself (its isSimdJSONPlain), but a Float when there
	is a floatPrinter"

	^ anObject isSimdJSONPlain and: [ floatPrinter isNil or: [ anObject isFloat not ] ]

]

{ #category : 'accessing' }
SimdJSONWriter >> level [
	"The indentation level of what is written next"

	^ level

]

{ #category : 'writing' }
SimdJSONWriter >> listElementSeparator [
	self emit: ','.
	self newlineIndent

]

{ #category : 'writing' }
SimdJSONWriter >> mapElementSeparator [
	self emit: ','.
	self newlineIndent

]

{ #category : 'initialize-release' }
SimdJSONWriter >> newLine: aString [
	"The line end of pretty printing; OSPlatform current lineEnding by default.  ASCII, as
	JSON wants it (CR, LF): it is written a byte a character, not encoded"

	newLine := aString

]

{ #category : 'writing' }
SimdJSONWriter >> newline [
	self emit: newLine

]

{ #category : 'writing' }
SimdJSONWriter >> newlineIndent [
	prettyPrint ifTrue: [
		self newline.
		level > 0 ifTrue: [ self emit: (String new: level withAll: Character tab) ] ]

]

{ #category : 'writing' }
SimdJSONWriter >> nextPut: anObject [
	"Write the JSON of anObject on the stream given to on:"

	budget ifNil: [ MaxOutputBytes ifNotNil: [ ^ self capped: [ self nextPut: anObject ] ] ].
	(self isPlain: anObject)
		ifTrue: [ self writePlain: anObject ]
		ifFalse: [ self writeOther: anObject ]

]

{ #category : 'writing' }
SimdJSONWriter >> nextPut: anObject as: schema [
	"Write anObject with the mapping of schema"

	budget ifNil: [ MaxOutputBytes ifNotNil: [ ^ self capped: [ self nextPut: anObject as: schema ] ] ].
	(schema isNil or: [ anObject isNil ]) ifTrue: [ ^ self nextPut: anObject ].
	^ (self mappingFor: schema) writeObject: anObject on: self

]

{ #category : 'writing' }
SimdJSONWriter >> nextPutAll: aCollection [
	"Each element as JSON, followed by a newline: NDJSON, or JSON Lines"

	aCollection do: [ :each |
		self nextPut: each.
		self newline ]

]

{ #category : 'initialize-release' }
SimdJSONWriter >> nonFiniteAsNull: aBoolean [
	"true: NaN and the infinities are written null; false (the default): they signal
	SimdJSONWriteError, since JSON has no such number (NeoJSONWriter writes Float nan)"

	nonFiniteAsNull := aBoolean

]

{ #category : 'initialize-release' }
SimdJSONWriter >> on: aWriteStream [
	"Write on aWriteStream, which close closes; the JSON goes to its simdJSONSink, the binary
	stream when it encodes UTF-8 with Zinc, so that it is not encoded twice, and in bytes to
	any sink that answers isBinary true"

	writeStream := aWriteStream.
	sink := aWriteStream simdJSONSink.
	binary := (sink respondsTo: #isBinary) and: [ sink isBinary ]

]

{ #category : 'private' }
SimdJSONWriter >> output: anObject bytes: aBoolean [
	"The JSON of anObject at once: the output of the plugin when it wrote all of it, else
	that output with its holes written in, on a stream of its own"

	| r stream savedSink savedBinary |
	budget ifNil: [ MaxOutputBytes ifNotNil: [ ^ self capped: [ self output: anObject bytes: aBoolean ] ] ].
	(self isPlain: anObject) ifTrue: [
		r := self prim: anObject bytes: aBoolean.
		(r at: 3) ifNil: [ ^ r at: 2 ] ].
	stream := ((aBoolean ifTrue: [ ByteArray ] ifFalse: [ String ])
		new: (r ifNil: [ 256 ] ifNotNil: [ (r at: 2) size + ((r at: 3) size * 8) ])) writeStream.
	savedSink := sink.
	savedBinary := binary.
	sink := stream.
	binary := aBoolean.
	[ r ifNil: [ self writeOther: anObject ] ifNotNil: [ self emitOutput: r ] ]
		ensure: [
			sink := savedSink.
			binary := savedBinary ].
	^ stream contents

]

{ #category : 'initialize-release' }
SimdJSONWriter >> prettyPrint: aBoolean [
	"Newlines and a tab per level, and a space around the colon of a key, as NeoJSONWriter"

	prettyPrint := aBoolean

]

{ #category : 'writing' }
SimdJSONWriter >> prettyPrintSpace [
	prettyPrint ifTrue: [ self emit: ' ' ]

]

{ #category : 'private' }
SimdJSONWriter >> prim: anObject bytes: aBoolean [
	"One call of primitiveWrite, answering its result of status OK; when the output did not
	fit in object memory, grow it by what the output needs and call it once more"

	| flags r |
	flags := self flagsBytes: aBoolean.
	r := self callPrim: anObject flags: flags.
	r isSimdJSONFailure ifTrue: [ ^ self failed: r ].
	(r at: 1) = 1 ifTrue: [
		SimdJSONReader count: #grows.
		Smalltalk growMemoryByAtLeast: (r at: 4) + 1048576.
		r := self callPrim: anObject flags: flags.
		r isSimdJSONFailure ifTrue: [ ^ self failed: r ].
		(r at: 1) = 1 ifTrue: [ ^ OutOfMemory signal ] ].
	(r at: 1) = 2 ifTrue: [ ^ self signalError: (r at: 4) culprit: (r at: 5) ].
	(r at: 1) = 3 ifTrue: [ ^ self tooLarge ].
	^ r

]

{ #category : 'private' }
SimdJSONWriter >> signalError: code culprit: anObject [
	^ SimdJSONWriteError new
		code: code;
		culprit: anObject;
		signal: (code = 1 ifTrue: [ 'JSON key names in objects must be strings' ]
			ifFalse: [ code = 2 ifTrue: [ 'JSON has no NaN or Infinity: ', anObject printString ]
			ifFalse: [ code = 3 ifTrue: [ 'nesting deeper than ', self class maxDepth printString, ' (a cycle?)' ]
			ifFalse: [ 'Character Unicode code point outside encoder range' ] ] ])

]

{ #category : 'writing' }
SimdJSONWriter >> stringFor: anObject [
	"The JSON of anObject, a ByteString or a WideString"

	^ self output: anObject bytes: false

]

{ #category : 'private' }
SimdJSONWriter >> tooLarge [

	^ SimdJSONResourceError new
		code: #tooLarge;
		signal: 'the JSON exceeds SimdJSONWriter maxOutputBytes; raise it'

]

{ #category : 'writing' }
SimdJSONWriter >> writeBoolean: aBoolean [
	budget ifNil: [ MaxOutputBytes ifNotNil: [ ^ self capped: [ self writeBoolean: aBoolean ] ] ].
	self emit: (aBoolean ifTrue: [ 'true' ] ifFalse: [ 'false' ])

]

{ #category : 'writing' }
SimdJSONWriter >> writeFloat: aFloat [
	budget ifNil: [ MaxOutputBytes ifNotNil: [ ^ self capped: [ self writeFloat: aFloat ] ] ].
	aFloat isFinite ifFalse: [
		nonFiniteAsNull ifTrue: [ ^ self writeNull ].
		^ self signalError: 2 culprit: aFloat ].
	floatPrinter ifNotNil: [
		^ self emit: (String streamContents: [ :stream | floatPrinter printFloat: aFloat on: stream ]) ].
	self writePlain: aFloat

]

{ #category : 'writing' }
SimdJSONWriter >> writeInteger: anInteger [
	budget ifNil: [ MaxOutputBytes ifNotNil: [ ^ self capped: [ self writeInteger: anInteger ] ] ].
	self emit: anInteger printString

]

{ #category : 'writing' }
SimdJSONWriter >> writeList: aCollection [
	self writeListStreamingDo: [ :listWriter |
		aCollection do: [ :each | listWriter writeElement: each ] ]

]

{ #category : 'writing' }
SimdJSONWriter >> writeListStreamingDo: aBlock [
	"aBlock gets a SimdJSONStreamingWriter, whose writeElement: writes each element"

	budget ifNil: [ MaxOutputBytes ifNotNil: [ ^ self capped: [ self writeListStreamingDo: aBlock ] ] ].
	self emit: '['.
	self writeStreamingDo: aBlock.
	self emit: ']'

]

{ #category : 'writing' }
SimdJSONWriter >> writeMap: aDictionary [
	self writeMapStreamingDo: [ :mapWriter |
		aDictionary keysAndValuesDo: [ :key :value | mapWriter writeKey: key value: value ] ]

]

{ #category : 'writing' }
SimdJSONWriter >> writeMapStreamingDo: aBlock [
	"aBlock gets a SimdJSONStreamingWriter, whose writeKey:value: writes each entry"

	budget ifNil: [ MaxOutputBytes ifNotNil: [ ^ self capped: [ self writeMapStreamingDo: aBlock ] ] ].
	self emit: '{'.
	self writeStreamingDo: aBlock.
	self emit: '}'

]

{ #category : 'accessing' }
SimdJSONWriter >> writeNil [
	"Whether the object mappings write the properties whose value is nil"

	^ writeNil

]

{ #category : 'initialize-release' }
SimdJSONWriter >> writeNil: aBoolean [
	"Whether the object mappings write the properties whose value is nil"

	writeNil := aBoolean

]

{ #category : 'writing' }
SimdJSONWriter >> writeNull [
	budget ifNil: [ MaxOutputBytes ifNotNil: [ ^ self capped: [ self writeNull ] ] ].
	self emit: 'null'

]

{ #category : 'writing' }
SimdJSONWriter >> writeObject: anObject [
	"Write anObject with the mapping of its class (SimdJSONMappingNotFound if none)"

	budget ifNil: [ MaxOutputBytes ifNotNil: [ ^ self capped: [ self writeObject: anObject ] ] ].
	(self mappingFor: anObject class) writeObject: anObject on: self

]

{ #category : 'private' }
SimdJSONWriter >> writeOther: anObject [
	"NeoJSON's neoJsonOn: of anObject, which the plugin does not write: its own, or what
	anObject answers to simdJSONWriteOn: (nil, Booleans and SmallIntegers, any other Number
	as a Float, any other String, dictionaries as maps, any other collection as a list, and
	any other object with the mapping of its class).  As with neoJsonOn:, the class of
	anObject chooses, not its isDictionary, isCollection or isNumber; for a proxy, the class
	of the object it stands for, but the mapping of its own (ProtoObject>>simdJSONWriteOn:)"

	(self hasOwnWriter: anObject) ifTrue: [ ^ anObject neoJsonOn: self ].
	^ anObject simdJSONWriteOn: self

]

{ #category : 'private' }
SimdJSONWriter >> writePlain: anObject [
	self emitOutput: (self prim: anObject bytes: binary)

]

{ #category : 'writing' }
SimdJSONWriter >> writeStreamingDo: aBlock [
	| streamingWriter |
	streamingWriter := SimdJSONStreamingWriter on: self.
	self indentedDo: [ aBlock value: streamingWriter ].
	streamingWriter wasUsed
		ifTrue: [ self newlineIndent ]
		ifFalse: [ self prettyPrintSpace ]

]

{ #category : 'writing' }
SimdJSONWriter >> writeString: aString [
	"Escaped by the plugin, as NeoJSONWriter escapes"

	budget ifNil: [ MaxOutputBytes ifNotNil: [ ^ self capped: [ self writeString: aString ] ] ].
	self writePlain: (aString isSimdJSONPlain
		ifTrue: [ aString ]
		ifFalse: [ String withAll: aString ])

]
