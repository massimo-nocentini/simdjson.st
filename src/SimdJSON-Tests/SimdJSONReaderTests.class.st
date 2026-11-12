Class {
	#name : 'SimdJSONReaderTests',
	#superclass : 'SimdJSONTestCase',
	#category : 'SimdJSON-Tests-Tests',
	#package : 'SimdJSON-Tests',
	#tag : 'Tests'
}

{ #category : 'tests - streams' }
SimdJSONReaderTests >> testAtEnd [
	"Nothing is skipped before the first value, as in NeoJSON"

	| reader |
	reader := self reader: '[1]   '.
	self deny: reader atEnd.
	reader next.
	self assert: reader atEnd.
	self deny: (self reader: '   ') atEnd.
	self assert: (self reader: '') atEnd.
	reader := self reader: '1 2'.
	self assert: reader next equals: 1.
	self deny: reader atEnd.
	self assert: reader next equals: 2.
	self assert: reader atEnd
]

{ #category : 'tests - streams' }
SimdJSONReaderTests >> testCloseClosesTheStream [
	"close closes the stream given to on:, also when the reader read it into a stream of
	 its own"

	| stream reader |
	stream := SimdJSONTestStream on: '[1,2] 3'.
	reader := SimdJSONReader on: stream.
	self assert: reader next equals: #( 1 2 ).
	self deny: stream isClosed.
	reader close.
	self assert: stream isClosed
]

{ #category : 'tests - values' }
SimdJSONReaderTests >> testDeepNesting [

	| depth value |
	depth := 1000.
	value := self read: (String new: depth withAll: $[) , (String new: depth withAll: $]).
	depth - 1 timesRepeat: [
		self assert: value size equals: 1.
		value := value first ].
	self assert: value equals: #()
]

{ #category : 'tests - values' }
SimdJSONReaderTests >> testDuplicateKeys [
	"The last value wins, as with at:put:, and keeps the place of the first in an
	 OrderedDictionary"

	| value |
	value := self read: '{"a":1,"a":2}'.
	self assert: value size equals: 1.
	self assert: (value at: 'a') equals: 2.
	value := (self reader: '{"a":1,"a":2}') nativeDictionaries: false; next.
	self assert: value size equals: 1.
	self assert: (value at: 'a') equals: 2.
	value := (self reader: '{"a":1,"b":2,"a":3}') mapClass: OrderedDictionary; next.
	self assert: value keys asArray equals: #( 'a' 'b' ).
	self assert: (value at: 'a') equals: 3
]

{ #category : 'tests - values' }
SimdJSONReaderTests >> testEmptyContainers [

	| value |
	self assert: (self read: '{}') equals: Dictionary new.
	self assert: (self read: '{}') class equals: Dictionary.
	self assert: (self read: '[]') equals: #().
	self assert: (self read: '[]') class equals: Array.
	value := self read: '[{},[],{"a":[]},[{}]]'.
	self assert: value first class equals: Dictionary.
	self assert: value second equals: #().
	self assert: ((value at: 3) at: 'a') equals: #().
	self assert: (value at: 4) first class equals: Dictionary.
	value := (self reader: '[{},[]]')
		mapClass: OrderedDictionary;
		listClass: OrderedCollection;
		next.
	self assert: value class equals: OrderedCollection.
	self assert: value first class equals: OrderedDictionary.
	self assert: value second class equals: OrderedCollection
]

{ #category : 'tests - errors' }
SimdJSONReaderTests >> testErrorCodes [

	self assert: (self strictErrorOf: '[1,') code isInteger.
	self assert: (self strictErrorOf: '   ') code equals: 13.
	self assert: (self strictErrorOf: '') code equals: 13.
	self assert: (self strictErrorOf: (self string: #( 16rFEFF )) , '[1]') code equals: 1001.
	self
		assert: ([ (SimdJSONReader on: (#[ 16rEF 16rBB 16rBF ] , '[1]' asByteArray) readStream) next. nil ]
			on: SimdJSONParseError
			do: [ :error | error return: error code ])
		equals: 1001.
	self
		assert: (self strictErrorOf: (String new: 1025 withAll: $[) , (String new: 1025 withAll: $])) code
		equals: 4.
	self assert: (self strictErrorOf: (String new: 1024 withAll: $[) , (String new: 1024 withAll: $])) isNil
]

{ #category : 'tests - errors' }
SimdJSONReaderTests >> testErrorMessages [

	self requirePlugin.
	self assert: ((SimdJSONReader errorMessageFor: 9) beginsWith: 'NUMBER_ERROR').
	self assert: ((SimdJSONReader errorMessageFor: 13) beginsWith: 'EMPTY').
	self assert: (SimdJSONReader errorMessageFor: 1001) notEmpty.
	self assert: (SimdJSONReader errorMessageFor: 1002) notEmpty.
	self assert: ((SimdJSONReader primErrorMessage: 0) beginsWith: 'SUCCESS').
	self assert: (SimdJSONReader primErrorMessage: 1001) equals: (SimdJSONReader errorMessageFor: 1001).
	self assert: (SimdJSONReader primErrorMessage: 100000) isNil.
	self assert: (SimdJSONReader primErrorMessage: -1) isNil
]

{ #category : 'tests - errors' }
SimdJSONReaderTests >> testErrors [

	#( '[1,' '[1,2' '{"a":1' '{"a" 1}' '[1 2]' '{1:2}' '[1,]' '[,1]' '{"a":1,}' 'nul' 'tru'
	   '"open' '{a:1}' '.5' '+1' '-' '' '   ' '[}' '"\x"' '"\uD83D"' ) do: [ :each |
		self should: [ self read: each ] raise: SimdJSONParseError ]
]

{ #category : 'tests - numbers' }
SimdJSONReaderTests >> testExactNumbersOff [
	"Every number with an exponent is a Float, built by the plugin"

	| value |
	value := (self reader: '[1e2,1e-2,1.5e300,7,1.5]') exactNumbers: false; next.
	self assert: value first equals: 100.0.
	self assert: value first class equals: SmallFloat64.
	self assert: value second equals: 0.01.
	self assert: (value at: 3) equals: 1.5e300.
	self assert: (value at: 3) class equals: BoxedFloat64.
	self assert: (value at: 4) equals: 7.
	self assert: (value at: 5) equals: 1.5.
	self assert: ((self reader: '1e2') exactNumbers: false; next) equals: 100.0.
	self
		assert: (self count: #numberTexts during: [
			(self reader: '{"a":[1e2,2E-1]}') exactNumbers: false; next ])
		equals: 0
]

{ #category : 'tests - numbers' }
SimdJSONReaderTests >> testExponents [
	"Exact numbers, as NeoJSON reads them: an exponent without a fraction gives an Integer
	 or a Fraction"

	{ '1e2' -> 100. '1E2' -> 100. '1e+2' -> 100. '1E+2' -> 100. '-1e2' -> -100. '0e0' -> 0.
	  '1e-2' -> (1 / 100). '-25e-1' -> (-5 / 2). '1e308' -> (10 raisedTo: 308).
	  '1.5e2' -> 150.0. '2.5E-3' -> 0.0025. '1.0e-400' -> 0.0. '1.5e300' -> 1.5e300.
	  '1.7976931348623157e308' -> Float fmax.
	  '2.2250738585072014e-308' -> 2.2250738585072014e-308 } do: [ :each |
		| value |
		value := self read: each key.
		self assert: value equals: each value.
		self assert: value class equals: each value class ].
	self
		should: [ self read: '1e-1074' ]
		raise: SimdJSONParseError
		withExceptionDo: [ :error |
			self assert: error messageText equals: 'number exponent too small' ]
]

{ #category : 'tests - sources' }
SimdJSONReaderTests >> testExternalReadsBetweenCalls [
	"The reader takes the position of the stream before each value"

	| stream reader |
	stream := '[1] [2] [3]' readStream.
	reader := SimdJSONReader on: stream.
	self assert: reader next equals: #( 1 ).
	self assert: stream position equals: 4.
	self assert: (stream next: 4) equals: '[2] '.
	self assert: reader next equals: #( 3 ).
	self assert: reader atEnd.
	stream position: 0.
	self deny: reader atEnd.
	self assert: reader next equals: #( 1 )
]

{ #category : 'tests - streams' }
SimdJSONReaderTests >> testFailIfNotAtEnd [

	| reader |
	reader := self reader: '[1] x'.
	self assert: reader next equals: #( 1 ).
	self
		should: [ reader failIfNotAtEnd ]
		raise: SimdJSONParseError
		withExceptionDo: [ :error | self assert: error messageText equals: 'extraneous input detected' ].
	reader := self reader: '[1]  '.
	reader next.
	self shouldnt: [ reader failIfNotAtEnd ] raise: Error
]

{ #category : 'tests - numbers' }
SimdJSONReaderTests >> testFloats [

	{ '1.5' -> 1.5. '0.1' -> 0.1. '-2.25' -> -2.25. '123456.789' -> 123456.789.
	  '0.30000000000000004' -> 0.30000000000000004.
	  '3.141592653589793238462643383279' -> Float pi } do: [ :each |
		| value |
		value := self read: each key.
		self assert: value equals: each value.
		self assert: value class equals: each value class ].
	self assert: (self read: '-0.0') equals: Float negativeZero.
	self assert: (self read: '-0.0') signBit equals: 1.
	self assert: (self read: '0.0') signBit equals: 0
]

{ #category : 'tests - streams' }
SimdJSONReaderTests >> testFormFeed [
	"Form feed separates values, before, between and after them"

	self assert: (self read: self ff , '[1]' , self ff) equals: #( 1 ).
	self assert: (self reader: '[1]' , self ff , '[2]') upToEnd equals: #( #( 1 ) #( 2 ) ).
	self assert: ((self reader: '[1]' , self ff) next; atEnd)
]

{ #category : 'tests - numbers' }
SimdJSONReaderTests >> testIntegers [
	"SmallIntegers up to 2^60, LargeIntegers beyond, of any size"

	{ 0. 123. -123. SmallInteger maxVal. SmallInteger maxVal + 1. SmallInteger minVal.
	  SmallInteger minVal - 1. (2 raisedTo: 63) - 1. (2 raisedTo: 63) negated.
	  2 raisedTo: 63. (2 raisedTo: 64) - 1. 2 raisedTo: 64. ((2 raisedTo: 63) + 1) negated.
	  123456789012345678901234567890. -123456789012345678901234567890 } do: [ :each |
		| value |
		value := self read: each printString.
		self assert: value equals: each.
		self assert: value class equals: each class ].
	self assert: (self read: '-0') equals: 0.
	self assert: (self read: '-0') class equals: SmallInteger.
	self
		assert: (self read: '[18446744073709551616,-9223372036854775809,1]')
		equals: { 2 raisedTo: 64. ((2 raisedTo: 63) + 1) negated. 1 }
]

{ #category : 'tests - strings' }
SimdJSONReaderTests >> testKeys [

	| value |
	value := self read: '{"a":1,"\u00e9":2,"\u20ac":3}'.
	self assert: (value at: 'a') equals: 1.
	self assert: (value at: (self string: #( 16rE9 ))) equals: 2.
	self assert: (value at: (self string: #( 16r20AC ))) equals: 3.
	self assert: (value keys detect: [ :each | each = 'a' ]) class equals: ByteString.
	self
		assert: (value keys detect: [ :each | each = (self string: #( 16r20AC )) ]) class
		equals: WideString
]

{ #category : 'tests - errors' }
SimdJSONReaderTests >> testLenientInputs [
	"NeoJSON accepts these, simdjson does not: the reader is strict RFC 8259"

	#( '01' '-01' '00' '1.' '[1.]' '"\uDE00"' '123abc' '0x10' '1e400' '1.0e309' ) ,
	{ '"a' , self lf , 'b"'. '[' , self ff , '1]' } do: [ :each |
		self should: [ self read: each ] raise: SimdJSONParseError ]
]

{ #category : 'tests - classes' }
SimdJSONReaderTests >> testListClassOrderedCollection [

	| value |
	value := (self reader: '[1,[2,[3]],{"a":[4]}]') listClass: OrderedCollection; next.
	self assert: value class equals: OrderedCollection.
	self assert: value second class equals: OrderedCollection.
	self assert: value second second class equals: OrderedCollection.
	self assert: ((value at: 3) at: 'a') class equals: OrderedCollection.
	self assert: value asArray first equals: 1.
	self assert: ((value at: 3) at: 'a') asArray equals: #( 4 )
]

{ #category : 'tests - numbers' }
SimdJSONReaderTests >> testManyDuplicateKeys [
	"Many number texts, then many duplicates of a key whose value is a String: every number
	 text is converted once, the last value wins"

	| n json value |
	n := 2000.
	json := String streamContents: [ :stream |
		stream nextPut: $[.
		n timesRepeat: [ stream nextPutAll: '1e1,' ].
		stream nextPut: ${.
		1 to: n do: [ :i |
			i > 1 ifTrue: [ stream nextPut: $, ].
			stream nextPutAll: '"a":"1"' ].
		stream nextPutAll: ',"b":2e1,"b":"x","c":3e1}]' ].
	#( true false ) do: [ :native |
		value := (self reader: json) nativeDictionaries: native; next.
		self assert: value size equals: n + 1.
		self assert: ((1 to: n) allSatisfy: [ :i | (value at: i) = 10 ]).
		self assert: (value last at: 'a') equals: '1'.
		self assert: (value last at: 'b') equals: 'x'.
		self assert: (value last at: 'c') equals: 30 ]
]

{ #category : 'tests - classes' }
SimdJSONReaderTests >> testMapClassOrderedDictionary [

	| value |
	value := (self reader: '{"b":1,"a":{"y":2,"x":3},"c":[{"z":4}]}') mapClass: OrderedDictionary; next.
	self assert: value class equals: OrderedDictionary.
	self assert: value keys asArray equals: #( 'b' 'a' 'c' ).
	self assert: (value at: 'a') class equals: OrderedDictionary.
	self assert: (value at: 'a') keys asArray equals: #( 'y' 'x' ).
	self assert: (value at: 'c') class equals: Array.
	self assert: (value at: 'c') first class equals: OrderedDictionary
]

{ #category : 'tests - classes' }
SimdJSONReaderTests >> testMapClassSmallDictionary [

	| value |
	value := (self reader: '{"b":1,"a":{"c":2}}') mapClass: SmallDictionary; next.
	self assert: value class equals: SmallDictionary.
	self assert: (value at: 'b') equals: 1.
	self assert: (value at: 'a') class equals: SmallDictionary.
	self assert: ((value at: 'a') at: 'c') equals: 2
]

{ #category : 'tests - errors' }
SimdJSONReaderTests >> testMaxInputUnits [
	"Above the cap, the reader refuses the value"

	SimdJSONReader maxInputUnits: 8.
	self assert: (self read: '[1]') equals: #( 1 ).
	self
		assert: (self count: #tooLarge during: [
			self should: [ self read: '[1,2,3,4,5]' ] raise: SimdJSONResourceError ])
		equals: 1.
	SimdJSONReader maxInputUnits: nil.
	self assert: (self read: '[1,2,3,4,5]') equals: #( 1 2 3 4 5 )
]

{ #category : 'tests - errors' }
SimdJSONReaderTests >> testMaxInputUnitsPerValue [
	"The cap applies to each value: a sequence of small values longer than the cap is read
	 by the plugin"

	| json reader |
	json := String streamContents: [ :stream |
		1 to: 100 do: [ :i | stream print: i; nextPut: Character lf ] ].
	SimdJSONReader maxInputUnits: 8.
	self
		assert: (self count: #tooLarge during: [
			self assert: (self reader: json) upToEnd equals: (1 to: 100) asArray ])
		equals: 0.
	reader := self reader: '[1,2] [1,2,3,4,5] [3]'.
	self assert: reader next equals: #( 1 2 ).
	self should: [ reader next ] raise: SimdJSONResourceError
]

{ #category : 'tests - streams' }
SimdJSONReaderTests >> testMultipleValues [
	"NeoJSONExamplesTests>>testMultiInstances"

	| json reader |
	json := '{"a":1}' , self lf , '{"a":2}'.
	reader := self reader: json.
	self assert: (reader next at: 'a') equals: 1.
	self deny: reader atEnd.
	self assert: (reader next at: 'a') equals: 2.
	self assert: reader atEnd
]

{ #category : 'tests - streams' }
SimdJSONReaderTests >> testNextAsNilAndClose [

	| reader |
	reader := self reader: '[1] [2]'.
	self assert: (reader nextAs: nil) equals: #( 1 ).
	self assert: reader next equals: #( 2 ).
	reader close
]

{ #category : 'tests - streams' }
SimdJSONReaderTests >> testNextLoop [

	| json reader values |
	json := String streamContents: [ :stream |
		1 to: 200 do: [ :i |
			stream nextPutAll: '{"id":'; print: i; nextPutAll: ',"v":['; print: i; nextPutAll: ',1e1]}'; nextPut: Character lf ] ].
	reader := self reader: json.
	values := OrderedCollection new.
	[ reader atEnd ] whileFalse: [ values add: reader next ].
	self assert: values size equals: 200.
	self assert: (values last at: 'id') equals: 200.
	self assert: (values last at: 'v') equals: #( 200 10 ).
	self assert: (self reader: json) upToEnd equals: values asArray
]

{ #category : 'tests - numbers' }
SimdJSONReaderTests >> testNumberTextAndDuplicateKeys [
	"The number text of a value that a duplicate key replaced is not converted"

	#( true false ) do: [ :native |
		| reader |
		reader := [ :json | (self reader: json) nativeDictionaries: native; next ].
		self assert: ((reader value: '{"a":1e5,"a":"1e5"}') at: 'a') equals: '1e5'.
		self assert: ((reader value: '{"a":"1e5","a":1e5}') at: 'a') equals: 100000.
		self assert: ((reader value: '{"a":1e5,"b":2,"a":3}') at: 'a') equals: 3.
		self assert: ((reader value: '{"a":1e5,"b":2,"a":3}') at: 'b') equals: 2 ]
]

{ #category : 'tests - numbers' }
SimdJSONReaderTests >> testNumberTextInContainers [
	"Number text in an Array, a map (native or tree), a nested map and at the root"

	| json check |
	json := '{"a":1e2,"b":[1e-2,{"c":1E1}],"d":-2E+1}'.
	check := [ :map |
		self assert: (map at: 'a') equals: 100.
		self assert: (map at: 'b') first equals: 1 / 100.
		self assert: ((map at: 'b') second at: 'c') equals: 10.
		self assert: (map at: 'd') equals: -20 ].
	check value: (self read: json).
	check value: ((self reader: json) nativeDictionaries: false; next).
	check value: ((self reader: json) mapClass: OrderedDictionary; next).
	check value: ((self reader: json) propertyNamesAsSymbols: true; next).
	self assert: (self read: '[[1e2]]') equals: #( #( 100 ) ).
	self assert: (self count: #numberTexts during: [ self read: json ]) equals: 4
]

{ #category : 'tests - sources' }
SimdJSONReaderTests >> testOtherStreams [
	"Streams that are not exactly a ReadStream on a String or a ByteArray, a proxy of one
	 among them or a ReadStream on a proxy, are read to their end first"

	| stream reader |
	stream := ReadWriteStream on: String new.
	stream nextPutAll: '[1] {"a":2} 3'; reset.
	reader := SimdJSONReader on: stream.
	self assert: reader next equals: #( 1 ).
	self assert: (reader next at: 'a') equals: 2.
	self assert: reader next equals: 3.
	self assert: reader atEnd.
	stream := ZnCharacterReadStream on: ('["' , (self string: #( 16r20AC )) , '"]') utf8Encoded readStream.
	self assert: (SimdJSONReader on: stream) next equals: { self string: #( 16r20AC ) }.
	stream := '1 [2]' readStream.
	reader := SimdJSONReader on: (SimdJSONTestProxy on: stream).
	self assert: reader next equals: 1.
	self assert: stream atEnd.
	self assert: reader next equals: #( 2 ).
	self assert: reader atEnd.
	self
		assert: (SimdJSONReader on: (ReadStream on: (SimdJSONTestProxy on: '[1,2]' utf8Encoded))) next
		equals: #( 1 2 ).
	self assert: (SimdJSONReader on: (ReadStream on: (SimdJSONTestProxy on: '[1,2]'))) next equals: #( 1 2 ).
	self
		assert: (SimdJSONReader on: (ReadStream on: (SimdJSONTestProxy on: '["' , (self string: #( 16r20AC )) , '"]'))) next
		equals: { self string: #( 16r20AC ) }
]

{ #category : 'tests - plugin' }
SimdJSONReaderTests >> testPluginInfo [

	| info |
	self requirePlugin.
	self assert: SimdJSONReader pluginAvailable.
	info := SimdJSONReader primInfo.
	self assert: info size equals: 8.
	self assert: info first equals: SimdJSONReader protocol.
	self assert: (info at: 2) equals: 'SimdJSONPlugin 1.0'.
	self assert: (info at: 3) equals: '5.0.5'.
	self assert: ((info at: 6) isInteger and: [ (info at: 7) isInteger ]).
	self assert: (info at: 8) size equals: SimdJSONReader pluginStatisticsKeys size.
	self assert: ((info at: 8) allSatisfy: [ :each | each isInteger ]).
	self assert: SimdJSONReader simdjsonVersion equals: '5.0.5'.
	self assert: (#( 'native' 'emscripten' ) includes: SimdJSONReader platform).
	self assert: SimdJSONReader implementationName notEmpty.
	SimdJSONReader platform = 'emscripten'
		ifTrue: [
			self assert: SimdJSONReader implementationName equals: 'fallback'.
			self assert: savedMaxInputUnits equals: 16 * 1024 * 1024 ]
		ifFalse: [ self assert: savedMaxInputUnits isNil ]
]

{ #category : 'tests - plugin' }
SimdJSONReaderTests >> testPluginMissing [
	"Without the module, and without the fallback of SimdJSON-FFI, reading signals
	 SimdJSONResourceError"

	SimdJSONReader
		testHook: #pluginMissing value: true;
		testHook: #fallbackMissing value: true.
	self assert: SimdJSONReader backend isNil.
	self
		should: [ self read: '[1]' ]
		raise: SimdJSONResourceError
		withExceptionDo: [ :error | self assert: error messageText equals: 'SimdJSONPlugin not available' ]
]

{ #category : 'tests - streams' }
SimdJSONReaderTests >> testPositions [
	"After a value, the stream is after the white space that follows it"

	| stream reader euro |
	stream := '[1]  [2] tail' readStream.
	reader := SimdJSONReader on: stream.
	self assert: reader next equals: #( 1 ).
	self assert: stream position equals: 5.
	self assert: reader next equals: #( 2 ).
	self assert: stream position equals: 9.
	self assert: stream upToEnd equals: 'tail'.
	euro := self string: #( 16r20AC ).
	{ euro. self string: #( 16rE9 ) } do: [ :char |
		stream := ('"' , char , '"  [2] tail') readStream.
		reader := SimdJSONReader on: stream.
		self assert: reader next equals: char.
		self assert: stream position equals: 5.
		self assert: reader next equals: #( 2 ).
		self assert: stream upToEnd equals: 'tail' ].
	stream := ('"' , euro , '"  [2] tail') utf8Encoded readStream.
	reader := SimdJSONReader on: stream.
	self assert: reader next equals: euro.
	self assert: stream position equals: 7
]

{ #category : 'tests - primitive' }
SimdJSONReaderTests >> testPrimitiveErrorsAndFailures [
	"A parse error is a status; only bad arguments fail the primitive"

	| result |
	self requirePlugin.
	result := self prim: '[1,' flags: 0 budget: -1.
	self assert: result first equals: 2.
	self assert: (result at: 2) isNil.
	self assert: (result at: 3) equals: 1.
	self assert: (result at: 6) > 0.
	result := self prim: '{}' flags: 12 budget: -1.
	self assert: result isSimdJSONFailure.
	self assert: result ec equals: #'bad argument'.
	result := self prim: '[1]' from: 10 to: 3 flags: 0 budget: -1 maxUnits: -1.
	self assert: result isSimdJSONFailure.
	self assert: result ec equals: #'bad index'.
	result := self prim: Object new from: 1 to: 0 flags: 0 budget: -1 maxUnits: -1.
	self assert: result isSimdJSONFailure.
	self assert: result ec equals: #'bad argument'.
	result := self prim: '[1]' from: 1 to: 3 flags: 0 budget: -1 maxUnits: -2.
	self assert: result isSimdJSONFailure.
	self assert: result ec equals: #'bad argument'.
	"isBytes is true of a CompiledMethod, whose bytecodes the VM gives no pointer to"
	result := self prim: Object >> #printString from: 1 to: 5 flags: 0 budget: -1 maxUnits: -1.
	self assert: result isSimdJSONFailure.
	self assert: result ec equals: #'bad argument'
]

{ #category : 'tests - primitive' }
SimdJSONReaderTests >> testPrimitiveKeysAndNext [

	| result |
	self requirePlugin.
	result := self prim: '[{"a":1,"b":2},{"a":3}]' flags: 8 budget: -1.
	self assert: (result at: 5) equals: #( 'a' 'b' ).
	self assert: ((result at: 2) first at: 1) equals: 1.
	self assert: ((result at: 2) first at: 3) equals: 2.
	self assert: ((result at: 2) second at: 1) equals: 1.
	self assert: ((result at: 2) second at: 2) equals: 3.
	result := self prim: '[1] [2]' from: 1 to: 7 flags: 1 budget: -1 maxUnits: -1.
	self assert: (result at: 2) equals: #( 1 ).
	self assert: (result at: 3) equals: 5.
	result := self prim: '[1] [2]' from: 5 to: 7 flags: 1 budget: -1 maxUnits: -1.
	self assert: (result at: 2) equals: #( 2 ).
	self assert: (result at: 3) equals: 8.
	result := self primDict: '{"k":[1,{"j":null}]}' budget: -1.
	self assert: (result at: 2) class equals: Dictionary.
	self assert: (((result at: 2) at: 'k') second at: 'j') isNil
]

{ #category : 'tests - primitive' }
SimdJSONReaderTests >> testPrimitiveMaxUnits [
	"A whole rest over maxUnits gives way to the value, and a value over it is a status"

	| result |
	self requirePlugin.
	result := self prim: '[1,2] [3,4]' from: 1 to: 11 flags: 0 budget: -1 maxUnits: 5.
	self assert: result first equals: 0.
	self assert: (result at: 2) equals: #( 1 2 ).
	self assert: (result at: 3) equals: 7.
	result := self prim: '[1,2] [3,4]' from: 7 to: 11 flags: 1 budget: -1 maxUnits: 5.
	self assert: (result at: 2) equals: #( 3 4 ).
	self assert: (result at: 3) equals: 12.
	#( 0 1 ) do: [ :flags |
		result := self prim: '[1,2] [3,4]' from: 1 to: 11 flags: flags budget: -1 maxUnits: 4.
		self assert: result first equals: 3.
		self assert: (result at: 2) isNil.
		self assert: (result at: 3) equals: 1.
		self assert: (result at: 6) equals: 5 ]
]

{ #category : 'tests - primitive' }
SimdJSONReaderTests >> testPrimitiveNextAfterRefusedBudget [
	"A refused budget keeps the parse of [1] for the retry: a read of more text in NEXT mode
	 that reuses it still answers the index of the next value"

	| result |
	self requirePlugin.
	result := self prim: '[1] [2]' from: 1 to: 3 flags: 0 budget: 0 maxUnits: -1.
	self assert: result first equals: 1.
	result := self prim: '[1] [2]' from: 1 to: 7 flags: 1 budget: -1 maxUnits: -1.
	self assert: (result at: 2) equals: #( 1 ).
	self assert: (result at: 3) equals: 5
]

{ #category : 'tests - primitive' }
SimdJSONReaderTests >> testPrimitiveResult [
	"The 6 slots: status, value, nextIndex, fixups, keys, code"

	| result value |
	self requirePlugin.
	result := self prim: '[1e2,{"k":"v"}]' flags: 2 budget: -1.
	self assert: result size equals: 6.
	self assert: result first equals: 0.
	value := result at: 2.
	self assert: value first equals: '1e2'.
	self assert: value second class equals: SimdJSONFlatMap.
	self assert: value second size equals: 2.
	self assert: (value second at: 1) equals: 'k'.
	self assert: (value second at: 2) equals: 'v'.
	self assert: (result at: 3) equals: 16.
	self assert: (result at: 4) size equals: 2.
	self assert: (result at: 4) first == value.
	self assert: (result at: 4) second equals: 1.
	self assert: (result at: 5) isNil.
	self assert: (result at: 6) equals: 0.
	result := self prim: '1e2' flags: 2 budget: -1.
	self assert: (result at: 2) equals: '1e2'.
	self assert: (result at: 4) first == result.
	self assert: (result at: 4) second equals: 2.
	result := self prim: '1e2' flags: 0 budget: -1.
	self assert: (result at: 2) equals: 100.0.
	self assert: (result at: 4) isNil
]

{ #category : 'tests - classes' }
SimdJSONReaderTests >> testPropertyNamesAsSymbols [

	| value nonAscii |
	value := (self reader: '{"abc":1,"n":{"abc":2},"l":[{"abc":3}],"abc":4}')
		propertyNamesAsSymbols: true;
		next.
	self assert: (value keys allSatisfy: [ :each | each isSymbol ]).
	self assert: (value keys detect: [ :each | each = #abc ]) == #abc.
	self assert: (value at: #abc) equals: 4.
	self assert: ((value at: #n) keys detect: [ :each | each = #abc ]) == #abc.
	self assert: (((value at: #l) first) keys detect: [ :each | each = #abc ]) == #abc.
	nonAscii := (self reader: '{"\u00e9t\u00e9":1,"\u20ac":2}') propertyNamesAsSymbols: true; next.
	self assert: (nonAscii keys allSatisfy: [ :each | each isSymbol ]).
	self assert: (nonAscii at: (self string: #( 16rE9 116 16rE9 )) asSymbol) equals: 1.
	self assert: (nonAscii at: (self string: #( 16r20AC )) asSymbol) equals: 2.
	value := (self reader: '{"b":1,"a":2,"b":3}')
		propertyNamesAsSymbols: true;
		mapClass: OrderedDictionary;
		next.
	self assert: value keys asArray equals: #( #b #a ).
	self assert: (value keys allSatisfy: [ :each | each isSymbol ]).
	self assert: (value at: #b) equals: 3
]

{ #category : 'tests - values' }
SimdJSONReaderTests >> testShapes [

	| value |
	value := self read: '{"a":[1,2.5,"x",null,true,false],"b":{}}'.
	self assert: value class equals: Dictionary.
	self assert: value size equals: 2.
	self assert: (value at: 'a') class equals: Array.
	self assert: (value at: 'a') equals: { 1. 2.5. 'x'. nil. true. false }.
	self assert: (value at: 'b') class equals: Dictionary.
	self assert: (value at: 'b') isEmpty
]

{ #category : 'tests - sources' }
SimdJSONReaderTests >> testSources [

	| stream reader |
	self
		assert: (self read: '[1,"' , (self string: #( 16r20AC )) , '"]')
		equals: { 1. self string: #( 16r20AC ) }.
	self assert: (SimdJSONReader on: #'[1,2]' readStream) next equals: #( 1 2 ).
	self assert: (SimdJSONReader fromBytes: '{"a":[1,2]}' asByteArray) equals: (Dictionary new at: 'a' put: #( 1 2 ); yourself).
	reader := SimdJSONReader onBytes: '[1] [2]' asByteArray.
	self assert: reader next equals: #( 1 ).
	self assert: reader next equals: #( 2 ).
	self assert: reader atEnd.
	stream := ReadStream on: 'xx[1,2]yy' from: 3 to: 7.
	reader := SimdJSONReader on: stream.
	self assert: reader next equals: #( 1 2 ).
	self assert: reader atEnd.
	self assert: stream position equals: 7
]

{ #category : 'tests - plugin' }
SimdJSONReaderTests >> testStandalone [
	"No NeoJSON class in the hierarchy of the reader and of its errors, and none named by a
	 method of the package SimdJSON, whether NeoJSON is in the image or not"

	| names |
	self assert: SimdJSONReader superclass equals: SimdJSONMapper.
	self assert: SimdJSONMapper superclass equals: Object.
	self assert: SimdJSONParseError superclass equals: Error.
	self assert: SimdJSONMappingNotFound superclass equals: Error.
	names := Set new.
	SimdJSONReader package definedClasses do: [ :class |
		class methods , class class methods do: [ :method |
			method literals do: [ :literal |
				(literal isVariableBinding and: [ literal key beginsWith: 'Neo' ])
					ifTrue: [ names add: literal key ].
				(literal isSymbol and: [ literal beginsWith: 'NeoJSON' ])
					ifTrue: [ names add: literal ] ] ] ].
	self assert: names isEmpty description: [ 'NeoJSON named: ' , names asArray printString ]
]

{ #category : 'tests - statistics' }
SimdJSONReaderTests >> testStatistics [

	SimdJSONReader resetStatistics.
	self assert: SimdJSONReader statistics keys asSet equals: SimdJSONReader statisticsKeys asSet.
	#( #reads #fastValues #overBudget #grows #numberTexts #nativeDictionaries #tooLarge ) do: [ :each |
		self assert: (self statistic: each) equals: 0 ].
	self read: '[1e2,{"a":1}]'.
	self assert: (self statistic: #reads) >= 1.
	self assert: (self statistic: #fastValues) >= 1.
	self assert: (self statistic: #numberTexts) equals: 1
]

{ #category : 'tests - errors' }
SimdJSONReaderTests >> testStrict [
	"simdjson's error is a SimdJSONParseError, with its code, the position of the value and
	 its message"

	| error |
	error := self strictErrorOf: '01'.
	self assert: error notNil.
	self assert: error code equals: 9.
	self assert: error position equals: 1.
	self assert: error messageText equals: 'simdjson: ' , (SimdJSONReader errorMessageFor: 9).
	self assert: (error messageText beginsWith: 'simdjson: NUMBER_ERROR').
	self assert: (self read: '[1]') equals: #( 1 ).
	self assert: (self reader: '1 2') next equals: 1
]

{ #category : 'tests - strings' }
SimdJSONReaderTests >> testStrings [

	| value |
	self assert: (self read: '"abc"') class equals: ByteString.
	value := self read: '"\u00e9"'.
	self assert: value equals: (self string: #( 16rE9 )).
	self assert: value class equals: ByteString.
	value := self read: '"\u20ac"'.
	self assert: value equals: (self string: #( 16r20AC )).
	self assert: value class equals: WideString.
	value := self read: '"\ud834\udd1e"'.
	self assert: value size equals: 1.
	self assert: value first asInteger equals: 16r1D11E.
	value := self read: '"a\u0000b"'.
	self assert: value size equals: 3.
	self assert: value second asInteger equals: 0.
	self
		assert: (self read: '"a\"b\\c\/d\b\f\n\r\t"')
		equals: 'a"b\c/d' , (self string: #( 8 12 10 13 9 )).
	value := self read: '["a","\u20ac","b","\u00e9\u20ac"]'.
	self assert: (value collect: [ :each | each class ]) equals: { ByteString. WideString. ByteString. WideString }.
	self assert: value last equals: (self string: #( 16rE9 16r20AC ))
]

{ #category : 'tests - strings' }
SimdJSONReaderTests >> testStringsInSources [
	"Characters that are not ASCII in a ByteString (Latin-1), a WideString and UTF-8 bytes"

	| value |
	value := self read: '"' , (self string: #( 16rE9 )) , '"'.
	self assert: value equals: (self string: #( 16rE9 )).
	self assert: value class equals: ByteString.
	value := self read: '"' , (self string: #( 16r20AC 16r1D11E )) , '"'.
	self assert: value equals: (self string: #( 16r20AC 16r1D11E )).
	value := SimdJSONReader fromBytes: ('{"' , (self string: #( 16rE9 )) , '":"' , (self string: #( 16r20AC )) , '"}') utf8Encoded.
	self assert: (value at: (self string: #( 16rE9 ))) equals: (self string: #( 16r20AC ))
]

{ #category : 'tests - values' }
SimdJSONReaderTests >> testTopLevelScalars [

	self assert: (self read: '123') equals: 123.
	self assert: (self read: '"abc"') equals: 'abc'.
	self assert: (self read: 'true') equals: true.
	self assert: (self read: 'false') equals: false.
	self assert: (self read: 'null') isNil.
	self assert: (self read: '  7  ') equals: 7
]

{ #category : 'tests - streams' }
SimdJSONReaderTests >> testTrailingContent [
	"next reads one value and leaves what follows, as NeoJSON"

	self assert: (self read: '1 2') equals: 1.
	self assert: (self read: '[1] x') equals: #( 1 ).
	self assert: (self read: '[1]x') equals: #( 1 ).
	self assert: ((self read: '{"a":1} {"b":2}') at: 'a') equals: 1.
	self assert: (self read: '"a" "b"') equals: 'a'.
	self assert: (self read: 'true false') equals: true
]

{ #category : 'tests - streams' }
SimdJSONReaderTests >> testUpToEnd [

	| values reader |
	values := (self reader: '{"a":1}' , self lf , '{"a":2}' , self lf , '3') upToEnd.
	self assert: values class equals: Array.
	self assert: values size equals: 3.
	self assert: (values first at: 'a') equals: 1.
	self assert: (values second at: 'a') equals: 2.
	self assert: values third equals: 3.
	values := (self reader: '[1] [2]') listClass: OrderedCollection; upToEnd.
	self assert: values class equals: Array.
	self assert: values first class equals: OrderedCollection.
	reader := self reader: '1 2 3'.
	self assert: reader next equals: 1.
	self assert: reader upToEnd equals: #( 2 3 ).
	self assert: (self reader: '') upToEnd equals: #()
]
