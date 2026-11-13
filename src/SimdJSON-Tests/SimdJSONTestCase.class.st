Class {
	#name : 'SimdJSONTestCase',
	#superclass : 'TestCase',
	#instVars : [
		'savedMaxInputUnits'
	],
	#category : 'SimdJSON-Tests-Support',
	#package : 'SimdJSON-Tests',
	#tag : 'Support'
}

{ #category : 'testing' }
SimdJSONTestCase class >> isAbstract [

	^ self == SimdJSONTestCase
]

{ #category : 'helpers' }
SimdJSONTestCase >> count: aSymbol during: aBlock [
	"How much the statistic aSymbol of SimdJSONReader grew while aBlock ran"

	| before |
	before := self statistic: aSymbol.
	aBlock value.
	^ (self statistic: aSymbol) - before
]

{ #category : 'running' }
SimdJSONTestCase >> defaultTimeLimit [
	"The interpreter of WebAssembly is slow"

	^ 1 minute
]

{ #category : 'helpers' }
SimdJSONTestCase >> externalAddress: aByteArray [
	"An ExternalAddress that holds the 8 bytes of aByteArray: a byte object of a subclass of
	 ByteArray, which primitiveRead reads as Latin-1, not at the address it holds"

	| address |
	address := ExternalAddress new.
	aByteArray doWithIndex: [ :each :index | address basicAt: index put: each ].
	^ address
]

{ #category : 'accessing' }
SimdJSONTestCase >> ff [
	"Form feed: white space for NeoJSON (isSeparator), not for RFC 8259"

	^ String with: (Character value: 12)
]

{ #category : 'helpers' }
SimdJSONTestCase >> integerOfBytes: aString [
	"The LargePositiveInteger whose bytes, the lowest first, are the characters of aString:
	 a byte object that primitiveRead reads as Latin-1"

	^ aString reverse inject: 0 into: [ :integer :each | integer * 256 + each asInteger ]
]

{ #category : 'accessing' }
SimdJSONTestCase >> lf [

	^ String with: Character lf
]

{ #category : 'helpers' }
SimdJSONTestCase >> outsideObject: aClass of: aString [
	"An instance of aClass, a byte or word class rooted at ProtoObject, whose units are the
	 code points of aString; thisContext stores them, since it has no basicAt:put:"

	| object |
	object := aClass basicNew: aString size.
	aString doWithIndex: [ :each :index | thisContext object: object basicAt: index put: each asInteger ].
	^ object
]

{ #category : 'helpers' }
SimdJSONTestCase >> prim: source flags: flags budget: budget [
	"One call of primitiveRead on all of source, in tree mode"

	^ self prim: source from: 1 to: source size flags: flags budget: budget maxUnits: -1
]

{ #category : 'helpers' }
SimdJSONTestCase >> prim: source from: start to: stop flags: flags budget: budget maxUnits: maxUnits [
	"One call of primitiveRead on source from start to stop, in tree mode"

	^ SimdJSONReader
		primRead: source from: start to: stop flags: flags budget: budget maxUnits: maxUnits
		objectClass: SimdJSONFlatMap associationClass: nil wideStringClass: WideString
		hashSeed: ByteString hash dictLayout: 0
]

{ #category : 'helpers' }
SimdJSONTestCase >> primDict: source budget: budget [
	"One call of primitiveRead on all of source that builds Dictionaries"

	^ SimdJSONReader
		primRead: source from: 1 to: source size flags: 4 budget: budget maxUnits: -1
		objectClass: Dictionary associationClass: Association wideStringClass: WideString
		hashSeed: ByteString hash dictLayout: SimdJSONReader dictLayout
]

{ #category : 'helpers' }
SimdJSONTestCase >> probeJSON [
	"The input of the per-session self-test of the Dictionaries built in C
	 (SimdJSONReader class>>nativeSelfTestJSON): a duplicate key, non ASCII keys, empty
	 containers, number text, and 300 keys (the overflow header)"

	^ String streamContents: [ :stream |
		stream nextPutAll: '{"a":1,"\u00e9":2,"\u20ac":3,"a":4,"e":{},"l":[],"n":1e2,"o":{'.
		0 to: 299 do: [ :i |
			i > 0 ifTrue: [ stream nextPut: $, ].
			stream nextPutAll: '"k'; print: i; nextPutAll: '":'; print: i ].
		stream nextPutAll: '}}' ]
]

{ #category : 'helpers' }
SimdJSONTestCase >> read: aString [

	^ SimdJSONReader fromString: aString
]

{ #category : 'helpers' }
SimdJSONTestCase >> reader: aString [

	^ SimdJSONReader on: aString readStream
]

{ #category : 'helpers' }
SimdJSONTestCase >> requirePlugin [
	"Skip a test of the plugin itself (its primitives, its budget, the Dictionaries it builds)
	 on a VM without it"

	SimdJSONReader pluginAvailable ifFalse: [ self skip: 'the test needs the SimdJSONPlugin' ]
]

{ #category : 'running' }
SimdJSONTestCase >> setUp [
	"The first read of a session runs the native self-test, which reads too: run it before
	 the test counts anything"

	super setUp.
	savedMaxInputUnits := SimdJSONReader maxInputUnits.
	SimdJSONReader nativeDictionariesWork
]

{ #category : 'accessing' }
SimdJSONTestCase >> statistic: aSymbol [

	^ SimdJSONReader statistics at: aSymbol
]

{ #category : 'helpers' }
SimdJSONTestCase >> strictErrorOf: aString [
	"The SimdJSONParseError that the reader raises on aString, or nil"

	^ [ (self reader: aString) next. nil ]
		on: SimdJSONParseError
		do: [ :error | error return: error ]
]

{ #category : 'helpers' }
SimdJSONTestCase >> string: codePoints [
	"A String of codePoints, of the narrowest class, as the reader answers it: the file
	 stays ASCII"

	| string |
	string := (codePoints allSatisfy: [ :each | each < 256 ])
		ifTrue: [ ByteString new: codePoints size ]
		ifFalse: [ WideString new: codePoints size ].
	codePoints doWithIndex: [ :each :index | string at: index put: (Character value: each) ].
	^ string
]

{ #category : 'helpers' }
SimdJSONTestCase >> words: aString [
	"The code points of aString in a WordArray: a word object that primitiveRead reads as
	 UTF-32"

	^ WordArray withAll: (aString asArray collect: [ :each | each asInteger ])
]

{ #category : 'running' }
SimdJSONTestCase >> tearDown [
	"Undo what a test may have changed in the class of the reader"

	SimdJSONReader
		maxInputUnits: savedMaxInputUnits;
		nativeDictionaries: true.
	SimdJSONWriter maxOutputBytes: nil.
	#( #budget #pluginMissing #fallbackMissing #nativeSelfTestFails ) do: [ :each |
		SimdJSONReader testHook: each value: nil ].
	super tearDown
]
