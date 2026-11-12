Class {
	#name : 'SimdJSONWriterTests',
	#superclass : 'SimdJSONTestCase',
	#category : 'SimdJSON-Tests-Tests',
	#package : 'SimdJSON-Tests',
	#tag : 'Tests'
}

{ #category : 'helpers' }
SimdJSONWriterTests >> float: hi low: lo [
	"A BoxedFloat64 of the bits hi (the sign, the exponent and the top of the mantissa) and lo"

	^ (Float new: 2)
		basicAt: 1 put: hi;
		basicAt: 2 put: lo;
		yourself
]

{ #category : 'helpers' }
SimdJSONWriterTests >> mapOf: aDictionary [
	"The JSON of a Dictionary of String keys and Integer values, in the order of
	 keysAndValuesDo:, as NeoJSONWriter writes it"

	^ String streamContents: [ :stream |
		| first |
		first := true.
		stream nextPut: ${.
		aDictionary keysAndValuesDo: [ :key :value |
			first ifFalse: [ stream nextPut: $, ].
			first := false.
			stream nextPut: $"; nextPutAll: key; nextPutAll: '":'; print: value ].
		stream nextPut: $} ]
]

{ #category : 'tests - strings' }
SimdJSONWriterTests >> testAsciiOnly [

	| writer |
	writer := SimdJSONWriter new asciiOnly: true; yourself.
	self
		assert: (writer stringFor: (self string: #( 97 126 127 233 8364 16r1D11E 16rD800 34 10 )))
		equals: '"a~\u007F\u00E9\u20AC\uD834\uDD1E\uD800\"\n"'.
	self assert: (writer stringFor: (self string: #( 233 ))) class equals: ByteString
]

{ #category : 'tests - output' }
SimdJSONWriterTests >> testBytes [

	| value |
	value := { 'a'. self string: #( 233 8364 16r1D11E ). 1.5 }.
	self assert: (SimdJSONWriter toBytes: value) class equals: ByteArray.
	self assert: (SimdJSONWriter toBytes: value) equals: (self write: value) utf8Encoded.
	self assert: (SimdJSONWriter toBytes: #()) equals: '[]' asByteArray
]

{ #category : 'tests - strings' }
SimdJSONWriterTests >> testCodePointOutOfRange [

	| string error |
	string := self string: #( 97 16r10FFFF ).
	self assert: (self write: string) equals: '"' , string , '"'.
	string := WideString new: 1.
	string at: 1 put: (Character value: 16r110000).
	error := self writeError: [ self write: { string } ].
	self assert: error code equals: 4.
	self assert: error culprit equals: string.
	self assert: error messageText equals: 'Character Unicode code point outside encoder range'
]

{ #category : 'tests - objects' }
SimdJSONWriterTests >> testCustomMappings [

	| stream writer |
	stream := WriteStream on: String new.
	writer := SimdJSONWriter on: stream.
	writer for: #Pair customDo: [ :mapping | mapping encoder: [ :point | { point x. point y } ] ].
	writer for: #Pairs customDo: [ :mapping | mapping listOfElementSchema: #Pair ].
	writer for: #Counts customDo: [ :mapping | mapping mapWithValueSchema: #Pair ].
	writer nextPut: (3 @ 4) as: #Pair.
	writer nextPut: { 1 @ 2. 5 @ 6 } as: #Pairs.
	writer nextPut: (Dictionary new at: 'p' put: 7 @ 8; yourself) as: #Counts.
	writer nextPut: nil as: #Pair.
	self assert: stream contents equals: '[3,4][[1,2],[5,6]]{"p":[7,8]}null'
]

{ #category : 'tests - structures' }
SimdJSONWriterTests >> testDictionaryOrder [
	"The order of keysAndValuesDo:, through growth and removals"

	| dictionary |
	dictionary := Dictionary new.
	1 to: 300 do: [ :i | dictionary at: 'k' , i printString put: i ].
	1 to: 300 by: 7 do: [ :i | dictionary removeKey: 'k' , i printString ].
	self assert: (self write: dictionary) equals: (self mapOf: dictionary).
	dictionary := Dictionary new.
	dictionary at: #sym put: 1; at: (self string: #( 8364 )) put: 2.
	self assert: (SimdJSONReader fromString: (self write: dictionary)) equals:
		(Dictionary new at: 'sym' put: 1; at: (self string: #( 8364 )) put: 2; yourself)
]

{ #category : 'tests - errors' }
SimdJSONWriterTests >> testErrors [

	| error cycle |
	error := self writeError: [ self write: (Dictionary new at: 1 put: 2; yourself) ].
	self assert: error code equals: 1.
	self assert: error culprit equals: 1.
	self assert: error messageText equals: 'JSON key names in objects must be strings'.
	cycle := Array new: 1.
	cycle at: 1 put: cycle.
	error := self writeError: [ self write: cycle ].
	self assert: error code equals: 3.
	self assert: (error messageText includesSubstring: 'a cycle')
]

{ #category : 'tests - errors' }
SimdJSONWriterTests >> testErrorsInTheImage [
	"The errors of the objects that the image writes, as those of the plugin"

	| cycle error |
	error := self writeError: [ self write: (OrderedDictionary new at: 1 put: 2; yourself) ].
	self assert: error code equals: 1.
	self assert: error messageText equals: 'JSON key names in objects must be strings'.
	error := self writeError: [ self write: (Set with: Float nan) ].
	self assert: error code equals: 2.
	self assert: (SimdJSONWriter new nonFiniteAsNull: true; stringFor: (Set with: Float infinity)) equals: '[null]'.
	cycle := IdentitySet new.
	cycle add: cycle.
	error := self writeError: [ self write: cycle ].
	self assert: error code equals: 3.
	cycle := OrderedCollection new.
	cycle add: (Set with: cycle).
	error := self writeError: [ self write: cycle ].
	self assert: error code equals: 3
]

{ #category : 'tests - objects' }
SimdJSONWriterTests >> testFloatPrinter [

	| writer |
	writer := SimdJSONWriter new floatPrinter: SimdJSONTestFloatPrinter new; yourself.
	self assert: (writer stringFor: { 1.0. 2.5. 1 / 3. 7. 'x' }) equals: '[1.00,2.50,0.33,7,"x"]'.
	self assert: (writer stringFor: 0.125) equals: '0.13'
]

{ #category : 'tests - values' }
SimdJSONWriterTests >> testFloats [
	"Float>>printOn:, as NeoJSONWriter writes them"

	{ 0.0. -0.0. 1.0. -1.0. 100.0. 0.1. 1.5. 123456.789. 1.0e15. 1.0e16. 1.0e20. 1.0e22. 123456789012345.0.
	  1234567890123456.0. 1.0e-4. 1.0e-5. 1.0e-7. 2.5e-3. Float fminDenormalized. Float fmin. Float fmax.
	  Float pi. Float e negated. 1.0e100. 1.0e-100. 1.7976931348623157e308. 4.9e-324 }
		do: [ :each | self assert: (self write: each) equals: each printString ]
]

{ #category : 'tests - structures' }
SimdJSONWriterTests >> testForwarders [
	"A ByteString that gets a wide character becomes a WideString through a forwarder"

	| string dictionary |
	string := 'abc' copy.
	string at: 2 put: (Character value: 8364).
	self assert: (self write: { string }) equals: '["' , string , '"]'.
	string := 'key' copy.
	dictionary := Dictionary new.
	dictionary at: string put: 1.
	string at: 1 put: (Character value: 8364).
	self assert: (self write: dictionary) equals: '{"' , string , '":1}'
]

{ #category : 'tests - objects' }
SimdJSONWriterTests >> testHolesLikePlainValues [
	"An object the image writes in the middle of the plugin's output gives the same text as
	its plain equivalent, at every level, in every configuration and in bytes"

	| wide holed plain |
	wide := self string: #( 233 8364 16r1D11E ).
	holed := Dictionary new
		at: 'a' put: (Set with: (Dictionary new at: 'b' put: 1 / 2; at: wide put: (OrderedDictionary new at: 'c' put: { 3 / 4 }; yourself); yourself));
		at: 'd' put: { wide. 1 / 8. #( 1 2 ) asOrderedCollection. (1 to: 2) };
		yourself.
	plain := Dictionary new
		at: 'a' put: { Dictionary new at: 'b' put: 0.5; at: wide put: (Dictionary new at: 'c' put: #( 0.75 ); yourself); yourself };
		at: 'd' put: { wide. 0.125. #( 1 2 ) asOrderedCollection. #( 1 2 ) };
		yourself.
	{ [ :w | w ]. [ :w | w prettyPrint: true; newLine: (String with: Character lf) ]. [ :w | w asciiOnly: true ].
	  [ :w | w prettyPrint: true; asciiOnly: true; newLine: (String with: Character cr with: Character lf) ] } do: [ :configure |
		| writer |
		writer := SimdJSONWriter new.
		configure value: writer.
		self assert: (writer stringFor: holed) equals: (writer stringFor: plain).
		self assert: (writer bytesFor: holed) equals: (writer bytesFor: plain).
		self assert: (writer bytesFor: holed) equals: (writer stringFor: plain) utf8Encoded ].
	self assert: (SimdJSONReader fromString: (self write: holed)) equals: (SimdJSONReader fromString: (self write: plain))
]

{ #category : 'tests - values' }
SimdJSONWriterTests >> testLiterals [

	self assert: (self write: nil) equals: 'null'.
	self assert: (self write: true) equals: 'true'.
	self assert: (self write: false) equals: 'false'.
	{ 0. 1. -1. 42. SmallInteger maxVal. SmallInteger minVal. SmallInteger maxVal + 1. SmallInteger minVal - 1.
	  2 raisedTo: 63. (2 raisedTo: 63) negated. (2 raisedTo: 64) - 1. 2 raisedTo: 64. (2 raisedTo: 64) negated.
	  (2 raisedTo: 200) - 1. (10 raisedTo: 50) negated. 10 raisedTo: 18. 10 raisedTo: 27. (10 raisedTo: 36) + 1 }
		do: [ :each | self assert: (self write: each) equals: each printString ]
]

{ #category : 'tests - objects' }
SimdJSONWriterTests >> testMappings [

	| writer object |
	writer := SimdJSONWriter new.
	writer mapInstVarsFor: Point.
	self assert: (writer stringFor: 1 @ 2) equals: '{"x":1,"y":2}'.
	self assert: (writer stringFor: { 1 @ 2. nil }) equals: '[{"x":1,"y":2},null]'.
	object := SimdJSONReader
		fromString: '{"id":7,"name":"seven","points":[{"x":1,"y":2},{"x":3,"y":4}],"created-at":"1234","tags":["a","b"]}'
		as: SimdJSONTestObject.
	self
		assert: (SimdJSONWriter toString: object)
		equals: '{"id":7,"name":"seven","points":[{"x":1,"y":2},{"x":3,"y":4}],"created-at":1234,"tags":["a","b"]}'.
	object name: nil.
	self assert: ((SimdJSONWriter toString: object) includesSubstring: '"name"') not.
	self assert: ((SimdJSONWriter new writeNil: true; stringFor: object) includesSubstring: '"name":null').
	self
		should: [ SimdJSONWriter toString: { 1 @ 2 } ]
		raise: SimdJSONMappingNotFound
		withExceptionDo: [ :error | self assert: error messageText equals: 'No mapping found for Point in SimdJSONWriter' ]
]

{ #category : 'tests - output' }
SimdJSONWriterTests >> testMaxOutputBytes [

	SimdJSONWriter maxOutputBytes: 16.
	self assert: (self write: #( 1 2 3 )) equals: '[1,2,3]'.
	self
		should: [ self write: (String new: 20 withAll: $a) ]
		raise: SimdJSONResourceError
		withExceptionDo: [ :error | self assert: error code equals: #tooLarge ].
	SimdJSONWriter maxOutputBytes: nil.
	self assert: (self write: (String new: 20 withAll: $a)) size equals: 22
]

{ #category : 'tests - values' }
SimdJSONWriterTests >> testNonFinite [
	"JSON has no NaN or infinity: an error, or null with nonFiniteAsNull:"

	{ Float nan. Float infinity. Float negativeInfinity } do: [ :each |
		| error |
		error := self writeError: [ self write: { 1. each } ].
		self assert: error notNil.
		self assert: error code equals: 2.
		self assert: error culprit isNaN equals: each isNaN.
		self assert: (SimdJSONWriter new nonFiniteAsNull: true; stringFor: { 1. each }) equals: '[1,null]' ]
]

{ #category : 'tests - objects' }
SimdJSONWriterTests >> testOtherObjectsByClass [
	"The class of a value chooses how the image writes it, as NeoJSON's neoJsonOn:, not its
	isDictionary or isCollection"

	| duck |
	duck := SimdJSONTestDuckDictionary new.
	self should: [ self write: duck ] raise: SimdJSONMappingNotFound.
	self should: [ self write: { 1. duck } ] raise: SimdJSONMappingNotFound.
	self
		should: [ SimdJSONWriter toString: (Dictionary new at: 'd' put: duck; yourself) ]
		raise: SimdJSONMappingNotFound
		withExceptionDo: [ :error |
			self assert: error messageText equals: 'No mapping found for SimdJSONTestDuckDictionary in SimdJSONWriter' ]
]

{ #category : 'tests - objects' }
SimdJSONWriterTests >> testOtherObjects [
	"What the plugin leaves to the image, written as NeoJSONWriter writes it"

	self assert: (self write: 1 / 4) equals: '0.25'.
	self assert: (self write: { 1 / 3. 3 / 2. 2 }) equals: '[0.3333333333333333,1.5,2]'.
	self assert: (self write: (3 / 2 asScaledDecimal: 2)) equals: '1.5'.
	self assert: (self write: (Set with: 7)) equals: '[7]'.
	self assert: (self write: (1 to: 3)) equals: '[1,2,3]'.
	self assert: (self write: #[ 1 2 ]) equals: '[1,2]'.
	self assert: (self write: (Bag with: 'x')) equals: '["x"]'.
	self
		assert: (self write: (OrderedDictionary new at: 'b' put: 1; at: 'a' put: 2; yourself))
		equals: '{"b":1,"a":2}'.
	self assert: (self write: (IdentityDictionary new at: #k put: 1 / 2; yourself)) equals: '{"k":0.5}'.
	self assert: (self write: (SmallDictionary new at: 'k' put: nil; yourself)) equals: '{"k":null}'.
	{ $a. Object new. 1 @ 2 } do: [ :each |
		self should: [ self write: { 1. each } ] raise: SimdJSONMappingNotFound ]
]

{ #category : 'tests - objects' }
SimdJSONWriterTests >> testOwnWriters [
	"A class that writes itself with neoJsonOn:, NeoJSON's protocol"

	| own |
	own := SimdJSONTestOwnWriter new value: 3.
	self assert: (self write: own) equals: '{"own":3}'.
	self assert: (self write: { own. own }) equals: '[{"own":3},{"own":3}]'.
	self
		assert: (SimdJSONWriter new prettyPrint: true; newLine: (String with: Character lf); stringFor: { own })
		equals: '[' , (String with: Character lf with: Character tab) , '{' , (String with: Character lf) , (String new: 2 withAll: Character tab)
			, '"own" : 3' , (String with: Character lf with: Character tab) , '}' , (String with: Character lf) , ']'
]

{ #category : 'tests - errors' }
SimdJSONWriterTests >> testPluginMissing [
	"Without the module, and without the fallback of SimdJSON-FFI"

	SimdJSONReader
		testHook: #pluginMissing value: true;
		testHook: #fallbackMissing value: true.
	self should: [ self write: #( 1 ) ] raise: SimdJSONResourceError
]

{ #category : 'tests - structures' }
SimdJSONWriterTests >> testPretty [

	| writer tab lf |
	tab := String with: Character tab.
	lf := String with: Character lf.
	writer := SimdJSONWriter new prettyPrint: true; newLine: lf; yourself.
	self assert: (writer stringFor: #()) equals: '[ ]'.
	self assert: (writer stringFor: Dictionary new) equals: '{ }'.
	self assert: (writer stringFor: 1) equals: '1'.
	self
		assert: (writer stringFor: { 1. Dictionary new at: 'a' put: #( 2 ); yourself. #() })
		equals: '[' , lf , tab , '1,' , lf , tab , '{' , lf , tab , tab , '"a" : [' , lf , tab , tab , tab , '2'
			, lf , tab , tab , ']' , lf , tab , '},' , lf , tab , '[ ]' , lf , ']'.
	writer newLine: (String with: Character cr with: Character lf).
	self
		assert: (writer stringFor: #( 1 ))
		equals: '[' , (String with: Character cr with: Character lf) , tab , '1' , (String with: Character cr with: Character lf) , ']'.
	self
		assert: (SimdJSONWriter toStringPretty: #( 1 ))
		equals: '[' , OSPlatform current lineEnding , tab , '1' , OSPlatform current lineEnding , ']'
]

{ #category : 'tests - objects' }
SimdJSONWriterTests >> testPrettyHoles [

	| writer tab lf |
	tab := String with: Character tab.
	lf := String with: Character lf.
	writer := SimdJSONWriter new prettyPrint: true; newLine: lf; yourself.
	self
		assert: (writer stringFor: (Dictionary new at: 'a' put: (Set with: (1 / 2)); yourself))
		equals: '{' , lf , tab , '"a" : [' , lf , tab , tab , '0.5' , lf , tab , ']' , lf , '}'.
	self assert: (writer stringFor: Set new) equals: '[ ]'.
	self assert: (writer stringFor: { OrderedDictionary new }) equals: '[' , lf , tab , '{ }' , lf , ']'
]

{ #category : 'tests - objects' }
SimdJSONWriterTests >> testProxies [
	"A proxy is a hole, written as the class of the object it stands for chooses, but with
	 the mapping of its own class, nil, true and false among them"

	| proxy |
	proxy := [ :each | SimdJSONTestProxy on: each ].
	self
		assert: (self write: {
			proxy value: 'a'. proxy value: #b. proxy value: 2. proxy value: 2 ** 70. proxy value: 1 / 2.
			proxy value: #( 1 ). proxy value: (OrderedCollection with: (proxy value: 3)).
			proxy value: (Dictionary new at: 'k' put: 1; yourself) })
		equals: '["a","b",2,1180591620717411303424,0.5,[1],[3],{"k":1}]'.
	{ nil. true. false. 3 @ 4. $c } do: [ :each |
		self
			should: [ self write: { 1. proxy value: each } ]
			raise: SimdJSONMappingNotFound
			withExceptionDo: [ :error |
				self assert: error messageText equals: 'No mapping found for SimdJSONTestProxy in SimdJSONWriter' ] ]
]

{ #category : 'tests - output' }
SimdJSONWriterTests >> testProxyStreams [
	"A proxy of a stream gets the JSON itself; a proxy of a ZnCharacterWriteStream of UTF-8
	gives its binary stream, as the stream would; a ZnCharacterWriteStream with a proxy of
	an encoder gets the characters, which it encodes with the proxy"

	| stream proxy writer bytes |
	stream := WriteStream on: String new.
	proxy := SimdJSONTestProxy on: stream.
	writer := SimdJSONWriter on: proxy.
	self assert: (writer instVarNamed: 'sink') == proxy.
	writer nextPut: #( 1 'a' ).
	self assert: stream contents equals: '[1,"a"]'.
	bytes := WriteStream on: ByteArray new.
	writer := SimdJSONWriter on: (SimdJSONTestProxy on: (ZnCharacterWriteStream on: bytes)).
	self assert: (writer instVarNamed: 'sink') == bytes.
	writer nextPut: { self string: #( 233 ) }.
	self assert: bytes contents equals: #[ 91 34 195 169 34 93 ].
	bytes := WriteStream on: ByteArray new.
	stream := (ZnCharacterWriteStream on: bytes) encoder: (SimdJSONTestProxy on: ZnUTF8Encoder new); yourself.
	writer := SimdJSONWriter on: stream.
	self assert: (writer instVarNamed: 'sink') == stream.
	writer nextPut: { self string: #( 233 ) }.
	self assert: bytes contents equals: #[ 91 34 195 169 34 93 ]
]

{ #category : 'tests - values' }
SimdJSONWriterTests >> testRandomFloats [
	"20000 doubles of random bits, boxed and as the VM normalizes them, and 20000 decimals"

	| random float |
	random := Random seed: 20261027.
	20000 timesRepeat: [
		float := self float: (random nextInteger: 16r100000000) - 1 low: (random nextInteger: 16r100000000) - 1.
		float isFinite ifTrue: [
			self assert: (self write: float) equals: float printString.
			self assert: (self write: { float * 1 }) equals: '[' , float printString , ']' ] ].
	20000 timesRepeat: [
		float := (random nextInteger: 100000000) / ((10 raisedTo: (random nextInteger: 12)) / 1.0).
		self assert: (self write: float) equals: float printString ]
]

{ #category : 'tests - output' }
SimdJSONWriterTests >> testRoundTrip [

	| value |
	value := SimdJSONReader fromString: self probeJSON.
	self assert: (SimdJSONReader fromString: (self write: value)) equals: value.
	self assert: (SimdJSONReader fromString: (SimdJSONWriter toStringPretty: value)) equals: value.
	self assert: (SimdJSONReader fromBytes: (SimdJSONWriter toBytes: value)) equals: value.
	value := { (2 raisedTo: 100) negated. 0.1. -0.0. 'a"\' , (self string: #( 0 31 233 8364 16r1D11E )). nil. true }.
	self assert: (SimdJSONReader fromString: (self write: value)) equals: value.
	self assert: (SimdJSONReader fromString: (SimdJSONWriter new asciiOnly: true; stringFor: value)) equals: value
]

{ #category : 'tests - output' }
SimdJSONWriterTests >> testStreamingProtocol [

	| stream writer lf |
	lf := String with: Character lf.
	stream := WriteStream on: String new.
	writer := SimdJSONWriter on: stream.
	writer writeMapStreamingDo: [ :map |
		map writeKey: 'a' value: 1.
		map writeKey: #b value: #( 1 2 ).
		map writeKey: 'c' value: (1 / 2) ].
	writer writeListStreamingDo: [ :list |
		list writeElement: 'x'.
		list writeElement: (Set with: true) ].
	writer writeNull; writeBoolean: false; writeInteger: (2 raisedTo: 70); writeFloat: 0.5; writeString: #sym.
	self assert: stream contents equals: '{"a":1,"b":[1,2],"c":0.5}["x",[true]]nullfalse11805916207174113034240.5"sym"'.
	stream := WriteStream on: String new.
	(SimdJSONWriter on: stream) newLine: lf; nextPutAll: { 1. 'x'. Set new. Dictionary new }.
	self assert: stream contents equals: '1' , lf , '"x"' , lf , '[]' , lf , '{}' , lf.
	stream := WriteStream on: ByteArray new.
	(SimdJSONWriter on: stream) nextPut: { 1 / 2. self string: #( 233 8364 ) }.
	self assert: stream contents equals: ('[0.5,"' , (self string: #( 233 8364 )) , '"]') utf8Encoded
]

{ #category : 'tests - output' }
SimdJSONWriterTests >> testStreams [

	| stream writer |
	stream := WriteStream on: String new.
	writer := SimdJSONWriter on: stream.
	writer nextPut: #( 1 2 ).
	writer nextPut: (self string: #( 8364 )).
	self assert: stream contents equals: '[1,2]"' , (self string: #( 8364 )) , '"'.
	stream := WriteStream on: ByteArray new.
	(SimdJSONWriter on: stream) nextPut: { self string: #( 233 ) }.
	self assert: stream contents equals: ('["' , (self string: #( 233 )) , '"]') utf8Encoded
]

{ #category : 'tests - strings' }
SimdJSONWriterTests >> testStrings [

	| controls |
	self assert: (self write: '') equals: '""'.
	self assert: (self write: 'abc') equals: '"abc"'.
	self assert: (self write: 'a"b\c/d') equals: '"a\"b\\c/d"'.
	self assert: (self write: #foo) equals: '"foo"'.
	controls := String new: 32.
	1 to: 32 do: [ :i | controls at: i put: (Character value: i - 1) ].
	self
		assert: (self write: controls)
		equals: '"\u0000\u0001\u0002\u0003\u0004\u0005\u0006\u0007\b\t\n\u000B\f\r\u000E\u000F\u0010\u0011\u0012\u0013\u0014\u0015\u0016\u0017\u0018\u0019\u001A\u001B\u001C\u001D\u001E\u001F"'.
	self
		assert: (self write: (self string: #( 127 233 255 )))
		equals: '"' , (self string: #( 127 233 255 )) , '"'.
	self
		assert: (self write: (self string: #( 97 8364 16r1D11E 16rD800 )))
		equals: '"' , (self string: #( 97 8364 16r1D11E 16rD800 )) , '"'.
	self assert: (self write: (self string: #( 8364 ))) class equals: WideString.
	self assert: (self write: (self string: #( 8364 )) asSymbol) equals: '"' , (self string: #( 8364 )) , '"'
]

{ #category : 'tests - structures' }
SimdJSONWriterTests >> testStructures [

	| collection |
	self assert: (self write: #()) equals: '[]'.
	self assert: (self write: Dictionary new) equals: '{}'.
	self assert: (self write: OrderedCollection new) equals: '[]'.
	self assert: (self write: #( 1 #( 2 #() ) 'x' #y nil )) equals: '[1,[2,[]],"x","y",null]'.
	collection := OrderedCollection withAll: #( 1 2 3 ).
	collection removeFirst.
	self assert: (self write: collection) equals: '[2,3]'.
	collection := OrderedCollection new.
	1 to: 20 do: [ :i | collection addFirst: i ].
	self assert: (self write: collection) equals: '[20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1]'.
	self
		assert: (self write: { Dictionary new at: 'a' put: (OrderedCollection with: #( 1 ) with: Dictionary new); yourself })
		equals: '[{"a":[[1],{}]}]'
]

{ #category : 'tests - output' }
SimdJSONWriterTests >> testZincStreams [
	"A ZnCharacterWriteStream of UTF-8 gets the bytes on its binary stream; another
	encoding gets the characters, which it encodes"

	| bytes stream value inner |
	value := { self string: #( 233 8364 16r1D11E ). 1 / 2. #( 1 ) }.
	bytes := WriteStream on: ByteArray new.
	stream := ZnCharacterWriteStream on: bytes.
	(SimdJSONWriter on: stream) nextPut: value; prettyPrint: true; nextPut: (Set with: 'x').
	self
		assert: bytes contents
		equals: ((self write: value) , (SimdJSONWriter toStringPretty: (Set with: 'x'))) utf8Encoded.
	bytes := WriteStream on: ByteArray new.
	stream := ZnCharacterWriteStream on: bytes encoding: 'latin1'.
	(SimdJSONWriter on: stream) nextPut: { self string: #( 233 ) }.
	self assert: bytes contents equals: #[ 91 34 233 34 93 ].
	inner := SimdJSONTestStream on: ''.
	(SimdJSONWriter on: (ZnCharacterWriteStream on: inner)) close.
	self assert: inner isClosed
]

{ #category : 'helpers' }
SimdJSONWriterTests >> write: anObject [

	^ SimdJSONWriter toString: anObject
]

{ #category : 'helpers' }
SimdJSONWriterTests >> writeError: aBlock [
	"The SimdJSONWriteError that aBlock signals, or nil"

	^ [ aBlock value. nil ]
		on: SimdJSONWriteError
		do: [ :error | error return: error ]
]
