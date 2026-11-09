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

{ #category : 'accessing' }
SimdJSONTestCase >> ff [
	"Form feed: white space for NeoJSON (isSeparator), not for RFC 8259"

	^ String with: (Character value: 12)
]

{ #category : 'accessing' }
SimdJSONTestCase >> lf [

	^ String with: Character lf
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

{ #category : 'running' }
SimdJSONTestCase >> tearDown [
	"Undo what a test may have changed in the class of the reader"

	SimdJSONReader
		maxInputUnits: savedMaxInputUnits;
		nativeDictionaries: true.
	SimdJSONWriter maxOutputBytes: nil.
	#( #budget #pluginMissing #nativeSelfTestFails ) do: [ :each |
		SimdJSONReader testHook: each value: nil ].
	super tearDown
]
