Class {
	#name : 'SimdJSONWriterTests',
	#superclass : 'SimdJSONTestCase',
	#category : 'SimdJSON-Tests-Tests',
	#package : 'SimdJSON-Tests',
	#tag : 'Tests'
}

{ #category : 'helpers' }
SimdJSONWriterTests >> assertCap: bytes of: aBlock answers: anObject [
	"aBlock answers anObject with maxOutputBytes bytes, and signals #tooLarge with a byte
	 less"

	SimdJSONWriter maxOutputBytes: bytes.
	self assert: aBlock value equals: anObject.
	SimdJSONWriter maxOutputBytes: bytes - 1.
	self
		should: aBlock
		raise: SimdJSONResourceError
		withExceptionDo: [ :error | self assert: error code equals: #tooLarge ]
]

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

{ #category : 'tests - output' }
SimdJSONWriterTests >> testMaxOutputBytesHandlers [
	"A handler outside a write that writes again on the same writer makes a write of its own,
	 with the whole cap, after an error as after #tooLarge; one that resumes gives the write
	 back what it had left"

	| stream writer |
	SimdJSONWriter maxOutputBytes: 12.
	stream := WriteStream on: String new.
	writer := SimdJSONWriter on: stream.
	self
		assert: ([ writer nextPut: { 'abcd'. Set with: Float nan } ]
			on: SimdJSONWriteError
			do: [ :error | writer nextPut: 'xyz'. #handled ])
		equals: #handled.
	self assert: stream contents equals: '["abcd",["xyz"'.
	SimdJSONWriter maxOutputBytes: 5.
	stream := WriteStream on: String new.
	writer := SimdJSONWriter on: stream.
	self
		assert: ([ writer nextPut: (1 to: 10) ]
			on: SimdJSONResourceError
			do: [ :error | writer writeNull. #handled ])
		equals: #handled.
	self assert: stream contents equals: '[1,2,null'.
	"16 bytes of the primitive leave 4 to the hole, after the handler wrote 5 of its own"
	SimdJSONWriter maxOutputBytes: 20.
	{ 'pq' -> '["abcd","xyz""pq","efgh"]'. 'pqr' -> '["abcd","xyz"' } do: [ :each |
		stream := WriteStream on: String new.
		writer := SimdJSONWriter on: stream.
		writer for: Point customDo: [ :mapping |
			mapping writer: [ :json :point | json nextPut: (Warning signal: 'a hole') ] ].
		[ [ writer nextPut: { 'abcd'. 1 @ 2. 'efgh' } ]
			on: Warning
			do: [ :warning |
				writer nextPut: 'xyz'.
				warning resume: each key ] ]
			on: SimdJSONResourceError
			do: [ :error | self assert: error code equals: #tooLarge ].
		self assert: stream contents equals: each value ].
	"so does one that goes straight back to the signal, past the handler of the write: 2 bytes
	 of the primitive and 33 of the hole leave 5, too few for the second string"
	SimdJSONWriter maxOutputBytes: 40.
	{ [ :error | error resumeUnchecked: nil ]. [ :error | error resignalAs: Warning new ] } do: [ :back |
		stream := WriteStream on: String new.
		writer := SimdJSONWriter on: stream.
		writer for: Point customDo: [ :mapping |
			mapping writer: [ :json :point |
				Error signal: 'a hole'.
				json
					writeString: (String new: 30 withAll: $a);
					listElementSeparator;
					writeString: (String new: 30 withAll: $b) ] ].
		self
			assert: ([ writer nextPut: { 1 @ 2 } ]
				on: Error, Warning
				do: [ :exception |
					exception class == Error ifTrue: [ back value: exception ].
					exception class == Warning ifTrue: [ exception resume: nil ].
					exception code ])
			equals: #tooLarge.
		self assert: stream contents equals: '["', (String new: 30 withAll: $a), '",' ]
]

{ #category : 'tests - output' }
SimdJSONWriterTests >> testMaxOutputBytesHoles [
	"The cap counts the whole write: the output of each call of the primitive, the holes it
	 leaves, at any depth, and the text the writer writes itself, in bytes of UTF-8"

	| hole latin1 wide |
	hole := { Set with: 1. 'ab' }.
	self assertCap: 10 of: [ SimdJSONWriter toString: hole ] answers: '[[1],"ab"]'.
	self assertCap: 10 of: [ SimdJSONWriter toBytes: hole ] answers: '[[1],"ab"]' asByteArray.
	"written by the image alone"
	self
		assertCap: 7
		of: [ SimdJSONWriter toString: (1 to: 3) asOrderedCollection asSet ]
		answers: '[1,2,3]'.
	self
		assertCap: 39
		of: [ SimdJSONWriter toString: { 1/3. 1/3 } ]
		answers: '[0.3333333333333333,0.3333333333333333]'.
	"6 characters, 7 bytes; 5 characters, 8 bytes"
	latin1 := self string: #( 16rE9 97 ).
	self
		assertCap: 7
		of: [ SimdJSONWriter toString: (Set with: latin1) ]
		answers: '["', latin1, '"]'.
	wide := self string: #( 16r1F600 ).
	self
		assertCap: 8
		of: [ SimdJSONWriter toString: (Set with: wide) ]
		answers: '["', wide, '"]'.
	self
		assertCap: 11
		of: [ SimdJSONWriter new floatPrinter: SimdJSONTestFloatPrinter new; stringFor: #( 1.5 2.5 ) ]
		answers: '[1.50,2.50]'
]

{ #category : 'tests - output' }
SimdJSONWriterTests >> testMaxOutputBytesNone [
	"nil, or a negative number as the -1 of primitiveWrite, is no cap, on every path; a cap
	 beyond the SmallIntegers is the largest of them"

	| text |
	text := String new: 20 withAll: $a.
	#( -1 -5 ) do: [ :each |
		SimdJSONWriter maxOutputBytes: each.
		self assert: SimdJSONWriter maxOutputBytes isNil.
		self assert: (SimdJSONWriter toString: text) size equals: 22.
		self assert: (SimdJSONWriter toString: { Set new. text }) size equals: 27.
		self assert: (String streamContents: [ :stream | (SimdJSONWriter on: stream) nextPut: text ]) size equals: 22 ].
	SimdJSONWriter maxOutputBytes: (2 raisedTo: 70).
	self assert: SimdJSONWriter maxOutputBytes equals: SmallInteger maxVal.
	self assert: (SimdJSONWriter toString: { Set new. text }) size equals: 27
]

{ #category : 'tests - output' }
SimdJSONWriterTests >> testMaxOutputBytesPretty [

	| pretty text |
	pretty := [ SimdJSONWriter new newLine: self lf; prettyPrint: true; stringFor: { Set with: 1. 'ab' } ].
	text := pretty value.
	self assert: text size equals: 20.
	self assertCap: 20 of: pretty answers: text
]

{ #category : 'tests - output' }
SimdJSONWriterTests >> testMaxOutputBytesPrefix [
	"The error comes before the bytes that would pass the cap: a stream holds at most the cap"

	| write |
	write := [ | stream |
		stream := WriteStream on: String new.
		[ (SimdJSONWriter on: stream) nextPut: { Set with: 1. 'abcdefgh' } ]
			on: SimdJSONResourceError
			do: [ :error | self assert: error code equals: #tooLarge ].
		stream contents ].
	{ 16 -> '[[1],"abcdefgh"]'. 15 -> '[[1'. 14 -> '[['. 9 -> '' } do: [ :each |
		SimdJSONWriter maxOutputBytes: each key.
		self assert: write value equals: each value ]
]

{ #category : 'tests - output' }
SimdJSONWriterTests >> testMaxOutputBytesReuse [
	"A refused write leaves the writer to the next one, with the whole cap"

	| stream writer |
	SimdJSONWriter maxOutputBytes: 5.
	stream := WriteStream on: String new.
	writer := SimdJSONWriter on: stream.
	self should: [ writer nextPut: (1 to: 10) ] raise: SimdJSONResourceError.
	writer nextPut: #( 1 2 ).
	self assert: stream contents equals: '[1,2,[1,2]'
]

{ #category : 'tests - output' }
SimdJSONWriterTests >> testMaxOutputBytesStreams [
	"On a stream, a write is one nextPut:, writeMapStreamingDo:, writeInteger:...; each element
	 of nextPutAll:, without its line end"

	| hole |
	hole := { Set with: 1. 'ab' }.
	self
		assertCap: 10
		of: [ String streamContents: [ :stream | (SimdJSONWriter on: stream) nextPut: hole ] ]
		answers: '[[1],"ab"]'.
	self
		assertCap: 10
		of: [ ByteArray streamContents: [ :stream | (SimdJSONWriter on: stream) nextPut: hole ] ]
		answers: '[[1],"ab"]' asByteArray.
	self
		assertCap: 15
		of: [
			String streamContents: [ :stream |
				(SimdJSONWriter on: stream) writeMapStreamingDo: [ :map |
					map writeKey: 'a' value: 1; writeKey: 'b' value: (Set with: 2) ] ] ]
		answers: '{"a":1,"b":[2]}'.
	self
		assertCap: 3
		of: [
			String streamContents: [ :stream |
				(SimdJSONWriter on: stream) newLine: self lf; nextPutAll: { 123. 'a'. #( 1 ) } ] ]
		answers: '123', self lf, '"a"', self lf, '[1]', self lf.
	self
		assertCap: 5
		of: [ String streamContents: [ :stream | (SimdJSONWriter on: stream) writeInteger: 12345 ] ]
		answers: '12345'
]

{ #category : 'tests - output' }
SimdJSONWriterTests >> testMaxOutputBytesUTF8Size [
	"The bytes the cap counts of an output, as primitiveWrite counts them: a surrogate in 3"

	| latin1 wide |
	latin1 := self string: #( 97 16rE9 ).
	wide := self string: #( 16r1F600 97 16rD800 16r800 16r7FF ).
	self assert: latin1 simdJSONUTF8Size equals: 3.
	self assert: wide simdJSONUTF8Size equals: 13.
	self assert: (self string: #( 16rE9 97 16rFF 16r80 16r7F )) simdJSONUTF8Size equals: 8.
	{ latin1. wide } do: [ :each |
		self assert: each simdJSONUTF8Size equals: (SimdJSONWriter toBytes: each) size - 2 ].
	self assert: latin1 utf8Encoded simdJSONUTF8Size equals: 3.
	"a long one counts the rest in a loop, once 64 are found at more than one in 8: here the
	 64th is found at 511, then at 512 where the 65th, at 513, starts the loop"
	self
		assert: ((String new: 200 withAll: (Character value: 16rE9)) , 'abc') simdJSONUTF8Size
		equals: 403.
	#( 511 512 ) do: [ :at |
		latin1 := String new: at + 10 withAll: $a.
		(1 to: 63) , { at. at + 1. at + 5. at + 10 } do: [ :each |
			latin1 at: each put: (Character value: 16rE9) ].
		self assert: latin1 simdJSONUTF8Size equals: at + 10 + 67.
		self assert: latin1 simdJSONUTF8Size equals: latin1 utf8Encoded size ].
	"one in 9: never the loop"
	latin1 := String new: 4096 withAll: $a.
	9 to: 4096 by: 9 do: [ :each | latin1 at: each put: (Character value: 16rFF) ].
	self assert: latin1 simdJSONUTF8Size equals: 4096 + 455
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
