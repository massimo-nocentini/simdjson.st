Class {
	#name : 'SimdJSONReader',
	#superclass : 'SimdJSONMapper',
	#instVars : [
		'readStream',
		'mapClass',
		'listClass',
		'propertyNamesAsSymbols',
		'source',
		'streamKind',
		'index',
		'stop',
		'depth',
		'pending',
		'hasPending',
		'topStart',
		'multi',
		'exactNumbers',
		'nativeDictionaries',
		'keyTable',
		'originalStream'
	],
	#classVars : [
		'MaxInputUnits',
		'NativeEnabled',
		'NativeVerdict',
		'PluginInfo',
		'SessionToken',
		'Statistics',
		'TestHooks'
	],
	#category : 'SimdJSON-Core',
	#package : 'SimdJSON',
	#tag : 'Core'
}

{ #category : 'configuration' }
SimdJSONReader class >> budgetChecked [
	"Whether the plugin is given a budget, the free old space, and measures a large value
	before it builds it: on WebAssembly, and on a VM whose old space has a maximum.
	Elsewhere old space grows on demand: a shortage fails the primitive, the VM collects
	garbage and calls it again on the same parse, and read: grows memory (recover:)"

	^ self platform = 'emscripten'
		or: [ ((Smalltalk vm parameterAt: 67) ifNil: [ 0 ]) > 0 ]

]

{ #category : 'statistics' }
SimdJSONReader class >> count: aSymbol [
	self count: aSymbol by: 1

]

{ #category : 'statistics' }
SimdJSONReader class >> count: aSymbol by: anInteger [
	| i |
	Statistics ifNil: [ self resetStatistics ].
	i := self statisticsKeys identityIndexOf: aSymbol.
	Statistics at: i put: (Statistics at: i) + anInteger

]

{ #category : 'native dictionaries' }
SimdJSONReader class >> dictLayout [
	"The 0-based slots of Dictionary tally and array, and of Association key and value,
	4 bits each, for the Dictionaries the plugin builds"

	| memo |
	memo := self sessionMemo.
	^ (memo at: 2) ifNil: [
		memo at: 2 put: ((Dictionary allInstVarNames indexOf: #tally) - 1)
			+ (((Dictionary allInstVarNames indexOf: #array) - 1) << 4)
			+ (((Association allInstVarNames indexOf: #key) - 1) << 8)
			+ (((Association allInstVarNames indexOf: #value) - 1) << 12) ]

]

{ #category : 'plugin' }
SimdJSONReader class >> errorMessageFor: code [
	^ (self sessionMemo at: 3)
		at: code
		ifAbsentPut: [ (self primErrorMessage: code) ifNil: [ 'error ', code printString ] ]

]

{ #category : 'primitives' }
SimdJSONReader class >> flagDict [
	"primRead: flag: build Dictionaries, Associations and Arrays, not a tree"

	^ 4

]

{ #category : 'primitives' }
SimdJSONReader class >> flagExact [
	"primRead: flag: numbers with an exponent, and integers beyond 64 bits, as their text"

	^ 2

]

{ #category : 'primitives' }
SimdJSONReader class >> flagNext [
	"primRead: flag: scan for the end of the value, and parse only it (else the whole rest
	is parsed first, the fast path of fromString:)"

	^ 1

]

{ #category : 'primitives' }
SimdJSONReader class >> flagSymbolKeys [
	"primRead: flag: the keys of the tree are indexes in an Array of the distinct keys"

	^ 8

]

{ #category : 'convenience' }
SimdJSONReader class >> fromBytes: aByteArray [
	^ (self onBytes: aByteArray) next

]

{ #category : 'convenience' }
SimdJSONReader class >> fromBytes: aByteArray as: schema [
	^ (self onBytes: aByteArray) nextAs: schema

]

{ #category : 'convenience' }
SimdJSONReader class >> fromString: aString [
	^ (self on: aString readStream) next

]

{ #category : 'convenience' }
SimdJSONReader class >> fromString: aString as: schema [
	^ (self on: aString readStream) nextAs: schema

]

{ #category : 'plugin' }
SimdJSONReader class >> implementationName [
	"The simdjson kernel: haswell, westmere, arm64, fallback..."

	^ self pluginInfo ifNotNil: [ :info | info at: 4 ]

]

{ #category : 'configuration' }
SimdJSONReader class >> maxInputUnits [
	"The largest value, in units of the source (characters, or bytes of UTF-8), that the
	plugin parses: 16 Mi on WebAssembly, where the memory a parser takes is never given
	back; none natively.  It applies to each value, so a stream of many small values (NDJSON)
	of any size is read by the plugin"

	MaxInputUnits == #none ifTrue: [ ^ nil ].
	^ MaxInputUnits ifNil: [
		self platform = 'emscripten' ifTrue: [ 16 * 1024 * 1024 ] ]

]

{ #category : 'configuration' }
SimdJSONReader class >> maxInputUnits: anIntegerOrNil [
	"nil removes the cap"

	MaxInputUnits := anIntegerOrNil ifNil: [ #none ]

]

{ #category : 'configuration' }
SimdJSONReader class >> nativeDictionaries: aBoolean [
	"false: never let the plugin build Dictionaries (the kill switch of the fast path).  The
	setting stays, through image saves too, until it is set back to true"

	NativeEnabled := aBoolean

]

{ #category : 'native dictionaries' }
SimdJSONReader class >> nativeDictionariesWork [
	| verdict |
	NativeEnabled == false ifTrue: [ ^ false ].
	(NativeVerdict == #passed and: [ SessionToken == Smalltalk session ]) ifTrue: [ ^ true ].
	self pluginAvailable ifFalse: [ ^ false ].
	NativeVerdict ifNil: [
		verdict := self runNativeSelfTest.
		verdict ifNotNil: [
			Transcript show: 'SimdJSON: Dictionaries are built in Smalltalk in this session: ', verdict; cr ].
		NativeVerdict := verdict ifNil: [ #passed ] ].
	^ NativeVerdict == #passed

]

{ #category : 'native dictionaries' }
SimdJSONReader class >> nativeSelfTestJSON [
	"Latin-1 and wide keys, a duplicate, empty containers, a number text, and an object of
	300 keys, whose array has the overflow header"

	^ String streamContents: [ :stream |
		stream
			nextPutAll: '{"a":1,"'; nextPut: (Character value: 233);
			nextPutAll: '":2,"'; nextPut: (Character value: 8364);
			nextPutAll: '":3,"a":4,"e":{},"l":[],"n":1e2,"o":{'.
		0 to: 299 do: [ :i |
			i > 0 ifTrue: [ stream nextPut: $, ].
			stream nextPutAll: '"k'; print: i; nextPutAll: '":'; print: i ].
		stream nextPutAll: '}}' ]

]

{ #category : 'native dictionaries' }
SimdJSONReader class >> nativeSelfTestPrecheck [
	| wide |
	((Dictionary allInstVarNames includesAll: #(tally array))
		and: [ (Association allInstVarNames includesAll: #(key value))
		and: [ Dictionary isVariable not and: [ Association isVariable not ] ] ])
			ifFalse: [ ^ 'the slots of Dictionary or Association' ].
	'abc' hash = (ByteString stringHash: 'abc' initialHash: ByteString hash)
		ifFalse: [ ^ 'ByteString>>hash' ].
	wide := String with: (Character value: 300).
	wide hash = (wide class stringHash: wide initialHash: ByteString hash)
		ifFalse: [ ^ 'WideString>>hash' ].
	#abc hash = 'abc' hash
		ifFalse: [ ^ 'Symbol>>hash' ].
	^ nil

]

{ #category : 'native dictionaries' }
SimdJSONReader class >> nativeSelfTestProbe [
	"The same JSON built by the plugin and through the tree path, compared, looked up and
	changed alike"

	| json native tree |
	json := self nativeSelfTestJSON.
	native := self nativeSelfTestRead: json.
	tree := (self on: json readStream)
		nativeDictionaries: false;
		next.
	native class == Dictionary ifFalse: [ ^ 'no Dictionary built' ].
	(native = tree and: [ tree = native ]) ifFalse: [ ^ 'differs from the tree path' ].
	(native at: 'a') = 4 ifFalse: [ ^ 'the last of duplicate keys' ].
	{ tree -> native. (tree at: 'o') -> (native at: 'o') } do: [ :pair |
		pair key keysAndValuesDo: [ :key :value |
			((pair value includesKey: key) and: [ (pair value at: key) = value ])
				ifFalse: [ ^ 'the lookup of a key' ] ] ].
	1 to: 50 do: [ :i |
		native at: 'm', i printString put: i.
		tree at: 'm', i printString put: i ].
	(native = tree and: [ tree = native ]) ifFalse: [ ^ 'growth' ].
	native removeKey: 'a'.
	tree removeKey: 'a'.
	(native = tree and: [ tree = native and: [ native keys asSet = tree keys asSet ] ])
		ifFalse: [ ^ 'removeKey:' ].
	(native at: 'e') at: 'x' put: 1.
	(tree at: 'e') at: 'x' put: 1.
	(((native at: 'e') at: 'x') = 1 and: [ native = tree and: [ tree = native ] ])
		ifFalse: [ ^ 'an empty Dictionary' ].
	^ nil

]

{ #category : 'native dictionaries' }
SimdJSONReader class >> nativeSelfTestRead: json [
	| result |
	result := self
		primRead: json from: 1 to: json size flags: self flagExact + self flagDict budget: -1
		maxUnits: -1 objectClass: Dictionary associationClass: Association wideStringClass: WideString
		hashSeed: ByteString hash dictLayout: self dictLayout.
	result class == SimdJSONFailure
		ifTrue: [ ^ self error: 'primitiveRead failed: ', result ec printString ].
	(result at: 1) = 0
		ifFalse: [ ^ self error: 'primitiveRead answered status ', (result at: 1) printString ].
	^ self new finish: result

]

{ #category : 'instance creation' }
SimdJSONReader class >> on: aReadStream [
	"A ReadStream on a String or a ByteArray (UTF-8) is read by the plugin; any other
	stream that answers #next #atEnd (or #upToEnd) is read to its end here (on: waits for
	the end of a socket stream, and what is read from that stream afterwards is not seen
	by the reader); close closes it"

	^ self new
		on: aReadStream;
		yourself

]

{ #category : 'instance creation' }
SimdJSONReader class >> onBytes: aByteArray [
	"UTF-8 bytes; the positions are then byte indexes"

	^ self on: aByteArray readStream

]

{ #category : 'plugin' }
SimdJSONReader class >> platform [
	"'native' or 'emscripten'"

	^ self pluginInfo ifNotNil: [ :info | info at: 5 ]

]

{ #category : 'plugin' }
SimdJSONReader class >> pluginAvailable [
	^ self pluginInfo notNil

]

{ #category : 'plugin' }
SimdJSONReader class >> pluginInfo [
	"The answer of primitiveInfo, { protocol. plugin version. simdjson version.
	implementation. platform. parser capacity. cached bytes. stats }, or nil"

	| memo |
	memo := self sessionMemo.
	(memo at: 1) == #unknown ifTrue: [
		memo at: 1 put: ((self testHook: #pluginMissing) == true
			ifFalse: [
				self primInfo ifNotNil: [ :info |
					(info isArray and: [ info first = self protocol ]) ifTrue: [ info ] ] ]) ].
	^ memo at: 1

]

{ #category : 'plugin' }
SimdJSONReader class >> pluginStatisticsKeys [
	"The names of the counters of the plugin, the last slot of pluginInfo, in their order
	(SJ_NUM_STATS of sjBridge.h); parseNanos and buildNanos are cumulative nanoseconds"

	^ #( #calls #parses #cacheHits #builds #buildFailures #overBudget #measures
		#numberTexts #gateHits #enumerations #parseNanos #buildNanos )

]

{ #category : 'primitives' }
SimdJSONReader class >> primErrorMessage: code [
	<primitive: 'primitiveErrorMessage' module: 'SimdJSONPlugin' error: ec>
	^ nil

]

{ #category : 'primitives' }
SimdJSONReader class >> primInfo [
	<primitive: 'primitiveInfo' module: 'SimdJSONPlugin' error: ec>
	^ nil

]

{ #category : 'primitives' }
SimdJSONReader class >> primRead: source from: start to: stop flags: flags budget: budget maxUnits: maxUnits
		objectClass: objClass associationClass: assocClassOrNil wideStringClass: wideClass
		hashSeed: seed dictLayout: layout [
	"The JSON value at start in source (a String, or UTF-8 bytes), as
	{ status. value. nextIndex. fixups. keys. code }; flags are the sum of flagNext,
	flagExact, flagDict and flagSymbolKeys.  docs/SimdJSON.md, Primitive contract, has the
	whole contract"

	<primitive: 'primitiveRead' module: 'SimdJSONPlugin' error: ec>
	^ SimdJSONFailure on: ec

]

{ #category : 'primitives' }
SimdJSONReader class >> primRelease: freeParser [
	<primitive: 'primitiveRelease' module: 'SimdJSONPlugin' error: ec>
	^ nil

]

{ #category : 'plugin' }
SimdJSONReader class >> protocol [
	"The version of the primitives' contract that this file speaks; a plugin that answers
	another one in primitiveInfo is not used"

	^ 2

]

{ #category : 'plugin' }
SimdJSONReader class >> releaseParser [
	"Free the memory of the parser of the plugin; the next read allocates it again"

	^ self primRelease: true

]

{ #category : 'statistics' }
SimdJSONReader class >> resetStatistics [
	Statistics := Array new: self statisticsKeys size withAll: 0

]

{ #category : 'native dictionaries' }
SimdJSONReader class >> runNativeSelfTest [
	"Answer nil when the Dictionaries that the plugin builds behave as the image's own
	(slots, String>>hash, the probing of Dictionary>>scanFor:), else what failed"

	| hooks statistics |
	(self testHook: #nativeSelfTestFails) == true
		ifTrue: [ ^ 'forced by the test hook #nativeSelfTestFails' ].
	hooks := TestHooks.
	statistics := Statistics.
	TestHooks := Statistics := nil.
	^ [ [ self nativeSelfTestPrecheck ifNil: [ self nativeSelfTestProbe ] ]
			on: Error
			do: [ :error | error class name, ': ', error messageText asString ] ]
		ensure: [
			TestHooks := hooks.
			Statistics := statistics ]

]

{ #category : 'plugin' }
SimdJSONReader class >> sessionMemo [
	"What the plugin and the image answered in this session: { info (#unknown until
	asked). dictLayout. the messages of the error codes }; a new session, or a test hook,
	forgets it"

	SessionToken == Smalltalk session
		ifFalse: [
			SessionToken := Smalltalk session.
			PluginInfo := { #unknown. nil. Dictionary new }.
			NativeVerdict := nil ].
	^ PluginInfo

]

{ #category : 'plugin' }
SimdJSONReader class >> simdjsonVersion [
	^ self pluginInfo ifNotNil: [ :info | info at: 3 ]

]

{ #category : 'statistics' }
SimdJSONReader class >> statistics [
	"The counters, in a new Dictionary: reads (primitive calls), fastValues (values answered by
	simdjson), overBudget, grows, numberTexts, nativeDictionaries (values built as
	Dictionaries in C), tooLarge"

	| statistics |
	Statistics ifNil: [ self resetStatistics ].
	statistics := Dictionary new.
	self statisticsKeys with: Statistics do: [ :key :count | statistics at: key put: count ].
	^ statistics

]

{ #category : 'statistics' }
SimdJSONReader class >> statisticsKeys [
	^ #(reads fastValues overBudget grows numberTexts nativeDictionaries tooLarge)

]

{ #category : 'testing' }
SimdJSONReader class >> testHook: aSymbol [
	^ TestHooks ifNotNil: [ :hooks | hooks at: aSymbol ifAbsent: [ nil ] ]

]

{ #category : 'testing' }
SimdJSONReader class >> testHook: aSymbol value: anObject [
	"Test-only overrides, nil removes one: #budget (the budget of every read),
	#pluginMissing (true: as if the module were absent), #nativeSelfTestFails (true)"

	TestHooks ifNil: [ TestHooks := Dictionary new ].
	anObject
		ifNil: [ TestHooks removeKey: aSymbol ifAbsent: [ ] ]
		ifNotNil: [ TestHooks at: aSymbol put: anObject ].
	TestHooks isEmpty ifTrue: [ TestHooks := nil ].
	SessionToken := nil

]

{ #category : 'testing' }
SimdJSONReader >> atEnd [
	depth = 0 ifTrue: [ self syncIn ].
	^ index > stop

]

{ #category : 'private' }
SimdJSONReader >> cMemoryFailure [
	^ SimdJSONResourceError new
		code: #'insufficient C memory';
		signal: 'SimdJSONPlugin: out of C memory'

]

{ #category : 'private' }
SimdJSONReader >> classifyStream [
	"#string: a ReadStream on a String, read by the plugin in characters; #bytes: on a
	ByteArray, in bytes of UTF-8; anything else is read to its end now, into a ReadStream
	of my own: originalStream keeps the one given, which close closes"

	| contents |
	depth := 0.
	multi := false.
	hasPending := false.
	readStream class == ReadStream
		ifTrue: [
			contents := readStream originalContents.
			contents isString ifTrue: [ ^ self useSource: contents kind: #string ].
			contents class == ByteArray ifTrue: [ ^ self useSource: contents kind: #bytes ] ].
	contents := (readStream respondsTo: #upToEnd)
		ifTrue: [ readStream upToEnd ]
		ifFalse: [
			String streamContents: [ :stream |
				[ readStream atEnd ] whileFalse: [ stream nextPut: readStream next ] ] ].
	(contents isString or: [ contents class == ByteArray ])
		ifFalse: [ contents := String withAll: contents ].
	readStream := ReadStream on: contents.
	self useSource: contents kind: (contents isString ifTrue: [ #string ] ifFalse: [ #bytes ])

]

{ #category : 'initialize-release' }
SimdJSONReader >> close [
	"Close the stream given to on:, as NeoJSON does, also when I read it into a stream of
	my own"

	originalStream ifNotNil: [ originalStream close ].
	(readStream notNil and: [ readStream ~~ originalStream ]) ifTrue: [ readStream close ].
	originalStream := readStream := nil

]

{ #category : 'private' }
SimdJSONReader >> consumeWhitespace [
	"NeoJSON's; the plugin consumes the white space around a value itself"

]

{ #category : 'private' }
SimdJSONReader >> error: text [
	SimdJSONParseError new signal: text

]

{ #category : 'initialize-release' }
SimdJSONReader >> exactNumbers: aBoolean [
	"false: every number with a fraction or an exponent is a Float (1e2 is 100.0), faster"

	exactNumbers := aBoolean

]

{ #category : 'private' }
SimdJSONReader >> expectChar: character [
	"NeoJSON's; simdjson checks the structure of the whole value"

]

{ #category : 'parsing' }
SimdJSONReader >> failIfNotAtEnd [
	self atEnd
		ifFalse: [ self error: 'extraneous input detected' ]

]

{ #category : 'private' }
SimdJSONReader >> finish: r [
	"Intern the keys, turn the number texts into numbers, before anything else reads the
	value; answer the value"

	keyTable := (r at: 5) ifNotNil: [ :keys | keys collect: [ :each | each asSymbol ] ].
	(r at: 4) ifNotNil: [ :fixups |
		fixups pairsDo: [ :object :slot |
			object instVarAt: slot put: (self numberFromText: (object instVarAt: slot)) ].
		self class count: #numberTexts by: fixups size // 2 ].
	^ r at: 2

]

{ #category : 'private' }
SimdJSONReader >> flagsTree: wantTree [
	"The flags of primRead:: NEXT after a first value (the end of the next one is scanned
	for), EXACT_NUMBERS, and DICT unless wantTree (the caller checked useNativeDictionary),
	else SYMBOL_KEYS with propertyNamesAsSymbols"

	| class flags |
	class := self class.
	flags := multi ifTrue: [ class flagNext ] ifFalse: [ 0 ].
	exactNumbers ifTrue: [ flags := flags + class flagExact ].
	wantTree
		ifFalse: [ flags := flags + class flagDict ]
		ifTrue: [ propertyNamesAsSymbols == true ifTrue: [ flags := flags + class flagSymbolKeys ] ].
	^ flags

]

{ #category : 'private' }
SimdJSONReader >> grow: byteCount [
	self class count: #grows.
	Smalltalk growMemoryByAtLeast: byteCount

]

{ #category : 'initialize-release' }
SimdJSONReader >> initialize [
	super initialize.
	propertyNamesAsSymbols ifNil: [ propertyNamesAsSymbols := false ].
	depth := 0.
	multi := false.
	exactNumbers := true.
	nativeDictionaries := true.
	hasPending := false

]

{ #category : 'private' }
SimdJSONReader >> keyFrom: aKey [
	"A key of the tree: a String, or the index of a Symbol in keyTable"

	^ aKey isInteger
		ifTrue: [ keyTable at: aKey ]
		ifFalse: [ aKey ]

]

{ #category : 'accessing' }
SimdJSONReader >> listClass [
	^ listClass ifNil: [ Array ]

]

{ #category : 'initialize-release' }
SimdJSONReader >> listClass: aClass [
	listClass := aClass

]

{ #category : 'accessing' }
SimdJSONReader >> mapClass [
	^ mapClass ifNil: [ Dictionary ]

]

{ #category : 'initialize-release' }
SimdJSONReader >> mapClass: aClass [
	mapClass := aClass

]

{ #category : 'private' }
SimdJSONReader >> materialize: node [
	"A node of the tree as NeoJSON would have read it, with mapClass and listClass"

	^ self materialize: node map: self mapClass list: self listClass

]

{ #category : 'private' }
SimdJSONReader >> materialize: node map: aMapClass list: aListClass [
	"The children of an Array are materialized in place, then copied once into aListClass"

	| map |
	node class == SimdJSONFlatMap ifTrue: [
		map := aMapClass new.
		1 to: node size by: 2 do: [ :i |
			map
				at: (self keyFrom: (node at: i))
				put: (self materialize: (node at: i + 1) map: aMapClass list: aListClass) ].
		^ map ].
	node class == Array ifTrue: [
		1 to: node size do: [ :i |
			node at: i put: (self materialize: (node at: i) map: aMapClass list: aListClass) ].
		^ aListClass == Array
			ifTrue: [ node ]
			ifFalse: [ aListClass withAll: node ] ].
	^ node

]

{ #category : 'initialize-release' }
SimdJSONReader >> nativeDictionaries: aBoolean [
	"false: Dictionaries are built by the image, with NeoJSON's capacity and order"

	nativeDictionaries := aBoolean

]

{ #category : 'accessing' }
SimdJSONReader >> next [
	"One JSON value.  The white space after it is consumed; anything else after it is left"

	| r value native |
	depth > 0 ifTrue: [ ^ self materialize: self takeValue ].
	self syncIn.
	native := self useNativeDictionary.
	r := self read: native not.
	(r at: 1) = 2 ifTrue: [ ^ self signalError: (r at: 6) at: index ].
	value := self finish: r.
	native
		ifTrue: [ self class count: #nativeDictionaries ]
		ifFalse: [ value := self materialize: value ].
	self class count: #fastValues.
	index := r at: 3.
	multi := index <= stop.
	self syncOut: index.
	^ value

]

{ #category : 'accessing' }
SimdJSONReader >> nextAs: schema [
	| mapping |
	schema ifNil: [ ^ self next ].
	mapping := self mappingFor: schema.
	depth > 0 ifTrue: [ ^ mapping readFrom: self ].
	^ self topLevel: [ mapping readFrom: self ]

]

{ #category : 'accessing' }
SimdJSONReader >> nextListAs: schema [
	^ self listClass streamContents: [ :stream |
		self parseListDo: [ stream nextPut: (self nextAs: schema) ] ]

]

{ #category : 'private' }
SimdJSONReader >> numberFromText: aString [
	"With NeoJSON's rules, and its errors as SimdJSONParseErrors"

	^ SimdJSONNumberParser parse: aString

]

{ #category : 'initialize-release' }
SimdJSONReader >> on: aReadStream [
	readStream := originalStream := aReadStream.
	self classifyStream

]

{ #category : 'parsing' }
SimdJSONReader >> parseConstantDo: block [
	"Evaluate block with the value when it is true, false or null, else consume nothing"

	depth = 0 ifTrue: [ ^ self topLevel: [ self parseConstantDo: block ] ].
	(hasPending == true and: [ pending isNil or: [ pending == true or: [ pending == false ] ] ])
		ifTrue: [ block value: self takeValue ]

]

{ #category : 'parsing' }
SimdJSONReader >> parseList [
	| node |
	depth = 0 ifTrue: [ ^ self topLevel: [ self parseList ] ].
	node := self takeValue.
	node class == Array ifFalse: [ ^ self error: '[ expected' ].
	^ self materialize: node

]

{ #category : 'parsing' }
SimdJSONReader >> parseListDo: block [
	"Evaluate block for each element, armed for the reads of the block"

	| node |
	depth = 0 ifTrue: [ ^ self topLevel: [ self parseListDo: block ] ].
	node := self takeValue.
	node class == Array ifFalse: [ ^ self error: '[ expected' ].
	1 to: node size do: [ :i |
		pending := node at: i.
		hasPending := true.
		block value.
		hasPending := false ]

]

{ #category : 'parsing' }
SimdJSONReader >> parseListElementsDo: block [
	self parseListDo: [
		block value: self parseValue ]

]

{ #category : 'parsing' }
SimdJSONReader >> parseMap [
	| node |
	depth = 0 ifTrue: [ ^ self topLevel: [ self parseMap ] ].
	node := self takeValue.
	node class == SimdJSONFlatMap ifFalse: [ ^ self error: '{ expected' ].
	^ self materialize: node

]

{ #category : 'parsing' }
SimdJSONReader >> parseMapDo: block [
	"NeoJSON's per entry protocol: block reads the key with parsePropertyName, then the value"

	| node |
	depth = 0 ifTrue: [ ^ self topLevel: [ self parseMapDo: block ] ].
	node := self takeValue.
	node class == SimdJSONFlatMap ifFalse: [ ^ self error: '{ expected' ].
	1 to: node size by: 2 do: [ :i |
		pending := (node at: i) -> (node at: i + 1).
		hasPending := #entry.
		block value.
		hasPending := false ]

]

{ #category : 'parsing' }
SimdJSONReader >> parseMapKeysAndValuesDo: block [
	self parseMapKeysDo: [ :key |
		block value: key value: self parseValue ]

]

{ #category : 'parsing' }
SimdJSONReader >> parseMapKeysDo: block [
	"Evaluate block with each key, the value armed for the reads of the block; a value the
	block does not read is skipped"

	| node |
	depth = 0 ifTrue: [ ^ self topLevel: [ self parseMapKeysDo: block ] ].
	node := self takeValue.
	node class == SimdJSONFlatMap ifFalse: [ ^ self error: '{ expected' ].
	1 to: node size by: 2 do: [ :i |
		pending := node at: i + 1.
		hasPending := true.
		block value: (self keyFrom: (node at: i)).
		hasPending := false ]

]

{ #category : 'parsing' }
SimdJSONReader >> parseNumber [
	| node |
	depth = 0 ifTrue: [ ^ self topLevel: [ self parseNumber ] ].
	node := self takeValue.
	node isNumber ifFalse: [ ^ self error: 'Integer digit expected' ].
	^ node

]

{ #category : 'parsing' }
SimdJSONReader >> parsePropertyName [
	| entry |
	hasPending == #entry ifFalse: [ ^ self error: 'property name expected' ].
	entry := pending.
	pending := entry value.
	hasPending := true.
	^ self keyFrom: entry key

]

{ #category : 'parsing' }
SimdJSONReader >> parseString [
	| node |
	depth = 0 ifTrue: [ ^ self topLevel: [ self parseString ] ].
	node := self takeValue.
	node isString ifFalse: [ ^ self error: '" expected' ].
	^ node

]

{ #category : 'parsing' }
SimdJSONReader >> parseValue [
	depth = 0 ifTrue: [ ^ self topLevel: [ self parseValue ] ].
	^ self materialize: self takeValue

]

{ #category : 'private' }
SimdJSONReader >> pluginMissing [
	^ SimdJSONResourceError new
		code: #'not found';
		signal: 'SimdJSONPlugin not available'

]

{ #category : 'private' }
SimdJSONReader >> prim: flags budget: budget [
	| dict |
	(self class testHook: #pluginMissing) == true ifTrue: [ ^ SimdJSONFailure on: nil ].
	dict := flags anyMask: self class flagDict.
	self class count: #reads.
	^ self class
		primRead: source from: index to: stop flags: flags budget: budget
		maxUnits: (self class maxInputUnits ifNil: [ -1 ])
		objectClass: (dict ifTrue: [ Dictionary ] ifFalse: [ SimdJSONFlatMap ])
		associationClass: (dict ifTrue: [ Association ] ifFalse: [ nil ])
		wideStringClass: WideString
		hashSeed: ByteString hash
		dictLayout: (dict ifTrue: [ self class dictLayout ] ifFalse: [ 0 ])

]

{ #category : 'initialize-release' }
SimdJSONReader >> propertyNamesAsSymbols: aBoolean [
	propertyNamesAsSymbols := aBoolean

]

{ #category : 'private' }
SimdJSONReader >> read: wantTree [
	"One call of the primitive at index, as a tree or built in C (wantTree false: the caller
	checked useNativeDictionary), with status OK or ERROR.  Where budgetChecked, the budget is checked before anything is built: a refusal
	says how many bytes the value needs, and the memory is grown by that first"

	| flags budget r |
	flags := self flagsTree: wantTree.
	budget := (self class testHook: #budget) ifNil: [
		(stop - index + 1 > 65536 and: [ self class budgetChecked ])
			ifTrue: [ Smalltalk vm parameterAt: 54 ]
			ifFalse: [ -1 ] ].
	r := self prim: flags budget: budget.
	r class == SimdJSONFailure ifTrue: [ r := self recover: r flags: flags ].
	(r at: 1) = 3 ifTrue: [ ^ self tooLarge: (r at: 6) ].
	(r at: 1) = 1 ifTrue: [
		self class count: #overBudget.
		self grow: ((r at: 6) - (Smalltalk vm parameterAt: 54) + 1048576 max: 1048576).
		r := self prim: flags budget: (Smalltalk vm parameterAt: 54).
		r class == SimdJSONFailure ifTrue: [ r := self recover: r flags: flags ].
		(r at: 1) = 1 ifTrue: [ ^ OutOfMemory signal ] ].
	^ r

]

{ #category : 'private' }
SimdJSONReader >> recover: failure flags: flags [
	"The VM already retried 5 times, on the parse the plugin keeps.  A no-memory failure
	here means fragmentation: ask the exact need (budget 0, the same parse), grow by all
	of it, try once more"

	| measure r |
	failure isUnavailable ifTrue: [ ^ self pluginMissing ].
	failure isNoCMemory ifTrue: [ ^ self cMemoryFailure ].
	failure isNoMemory ifFalse: [ ^ self primitiveFailed ].
	measure := self prim: flags budget: 0.
	measure class == SimdJSONFailure ifTrue: [ ^ OutOfMemory signal ].
	(measure at: 1) = 1 ifFalse: [ ^ measure ].
	self grow: (measure at: 6) + 1048576.
	r := self prim: flags budget: -1.
	r class == SimdJSONFailure ifTrue: [ ^ OutOfMemory signal ].
	^ r

]

{ #category : 'private' }
SimdJSONReader >> signalError: code at: unitIndex [
	^ SimdJSONParseError new
		code: code;
		position: unitIndex;
		signal: 'simdjson: ', (self class errorMessageFor: code)

]

{ #category : 'parsing' }
SimdJSONReader >> skipValue [
	"Drop the next value without building it (the object mapping, for unknown keys)"

	depth = 0 ifTrue: [ ^ self next ].
	self takeValue

]

{ #category : 'private' }
SimdJSONReader >> syncIn [
	"The stream holds the position: someone else may have read it since"

	index := readStream position + 1

]

{ #category : 'private' }
SimdJSONReader >> syncOut: nextIndex [
	readStream position: nextIndex - 1

]

{ #category : 'private' }
SimdJSONReader >> takeValue [
	hasPending == true ifFalse: [ ^ self error: 'value expected' ].
	hasPending := false.
	^ pending

]

{ #category : 'private' }
SimdJSONReader >> tooLarge: units [
	"The plugin refused a value of units over the cap (maxInputUnits)"

	self class count: #tooLarge.
	^ SimdJSONResourceError new
		code: #tooLarge;
		signal: 'a value of ', units printString, ' units exceeds SimdJSONReader maxInputUnits; raise it', (self class platform = 'emscripten'
			ifTrue: [ ', and start the VM with PHARO_WASM_OLD_SPACE_BASE=0x40000000 for large documents' ]
			ifFalse: [ '' ])

]

{ #category : 'private' }
SimdJSONReader >> topLevel: cursorBlock [
	"Read the value at the position as a tree, then evaluate cursorBlock with it pending.
	When nothing took it, the stream goes back before it, as NeoJSON reads nothing.  An
	error of cursorBlock puts the reader and the stream back before the value before any
	handler runs, so that a handler can read it again (try nextAs:, else next); a handler
	that resumes the error gets the reader back where cursorBlock was"

	| r root restored |
	self syncIn.
	topStart := index.
	r := self read: true.
	(r at: 1) = 2 ifTrue: [ ^ self signalError: (r at: 6) at: index ].
	root := pending := self finish: r.
	hasPending := true.
	self class count: #fastValues.
	index := r at: 3.
	multi := index <= stop.
	depth := depth + 1.
	restored := false.
	^ [ [ cursorBlock value ]
			on: Error
			do: [ :error | | saved resumption |
				restored ifTrue: [ error pass ].
				saved := { pending. hasPending. index }.
				restored := true.
				depth := depth - 1.
				hasPending := false.
				pending := nil.
				index := topStart.
				self syncOut: index.
				resumption := error outer.
				restored := false.
				depth := depth + 1.
				pending := saved first.
				hasPending := saved second.
				index := saved third.
				error resume: resumption ] ]
		ensure: [
			restored ifFalse: [
				depth := depth - 1.
				(hasPending == true and: [ pending == root ]) ifTrue: [ index := topStart ].
				hasPending := false.
				pending := nil.
				self syncOut: index ] ]

]

{ #category : 'accessing' }
SimdJSONReader >> upToEnd [
	"Every value left, NDJSON or JSON Lines, in an Array"

	^ Array streamContents: [ :stream |
		[ self atEnd ] whileFalse: [ stream nextPut: self next ] ]

]

{ #category : 'private' }
SimdJSONReader >> useNativeDictionary [
	^ nativeDictionaries
		and: [ self mapClass == Dictionary
		and: [ self listClass == Array
		and: [ propertyNamesAsSymbols ~~ true
		and: [ self class nativeDictionariesWork ] ] ] ]

]

{ #category : 'private' }
SimdJSONReader >> useSource: aStringOrByteArray kind: aSymbol [
	source := aStringOrByteArray.
	streamKind := aSymbol.
	stop := readStream readLimit

]
