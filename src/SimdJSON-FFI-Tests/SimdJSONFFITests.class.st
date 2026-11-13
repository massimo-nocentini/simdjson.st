"
The tests of SimdJSONLibrary, SimdJSONTapeDecoder and SimdJSONTapeEncoder themselves: the tags of the tapes, the tape copied by sj_ffi_take and the output by sj_ffi_take_output, the number texts, the holes and the culprits, the fallback of SimdJSONReader and SimdJSONWriter, and the same values and texts as the plugin's when the VM has it.  Skipped when the library is not found.
"
Class {
	#name : 'SimdJSONFFITests',
	#superclass : 'SimdJSONTestCase',
	#category : 'SimdJSON-FFI-Tests-Tests',
	#package : 'SimdJSON-FFI-Tests',
	#tag : 'Tests'
}

{ #category : 'helpers' }
SimdJSONFFITests >> library: source flags: flags [
	"One read of all of source by the library"

	^ SimdJSONLibrary read: source from: 1 to: source size flags: flags maxUnits: -1
]

{ #category : 'helpers' }
SimdJSONFFITests >> plain: result [
	"The value of primRead:'s answer result as the reader answers it: the number texts
	 converted, SimdJSONFlatMaps as Dictionaries"

	| reader |
	reader := SimdJSONReader new.
	^ reader materialize: (reader finish: result)
]

{ #category : 'helpers' }
SimdJSONFFITests >> readFFI: aString [
	"aString read through the library, the plugin hidden"

	| hooked |
	hooked := SimdJSONReader testHook: #pluginMissing.
	SimdJSONReader testHook: #pluginMissing value: true.
	^ [ self read: aString ] ensure: [ SimdJSONReader testHook: #pluginMissing value: hooked ]
]

{ #category : 'running' }
SimdJSONFFITests >> setUp [

	super setUp.
	SimdJSONLibrary isAvailable ifFalse: [ self skip: 'libSimdJSONFFI not found' ]
]

{ #category : 'tests' }
SimdJSONFFITests >> testAvailable [

	self assert: SimdJSONLibrary isAvailable.
	self assert: SimdJSONLibrary uniqueInstance primProtocol equals: SimdJSONLibrary protocol.
	self assert: SimdJSONLibrary simdjsonVersion equals: '5.0.5'.
	self assert: SimdJSONLibrary implementationName notEmpty
]

{ #category : 'tests' }
SimdJSONFFITests >> testBackend [
	"The plugin when the VM has it, else the library, else nothing"

	SimdJSONReader pluginAvailable ifTrue: [ self assert: SimdJSONReader backend equals: #plugin ].
	SimdJSONReader testHook: #pluginMissing value: true.
	self assert: SimdJSONReader backend equals: #ffi.
	self assert: (self read: '[1]') equals: #( 1 ).
	SimdJSONReader testHook: #fallbackMissing value: true.
	self assert: SimdJSONReader backend isNil.
	self should: [ self read: '[1]' ] raise: SimdJSONResourceError
]

{ #category : 'tests' }
SimdJSONFFITests >> testEveryTag [
	"Every tag of sjFFI.h, in a tree and in Dictionaries"

	| json tree dictionary |
	json := '[1, -7, "abc", 1.5, [], {}, null, true, false, 9007199254740992, 18446744073709551615, "'
		, (self string: #( 16r20AC 16r41 )) , '", 1e2, {"k": [null]}]'.
	tree := self library: json flags: SimdJSONReader flagExact.
	self assert: tree first equals: 0.
	self assert: ((tree at: 2) first: 5) equals: { 1. -7. 'abc'. 1.5. #() }.
	self assert: ((tree at: 2) at: 6) class equals: SimdJSONFlatMap.
	self assert: ((tree at: 2) at: 6) size equals: 0.
	self assert: ((tree at: 2) copyFrom: 7 to: 9) equals: #( nil true false ).
	self assert: ((tree at: 2) at: 10) equals: 9007199254740992.
	self assert: ((tree at: 2) at: 11) equals: 18446744073709551615.
	self assert: ((tree at: 2) at: 12) equals: (self string: #( 16r20AC 16r41 )).
	self assert: ((tree at: 2) at: 12) class equals: WideString.
	self assert: ((tree at: 2) at: 13) equals: '1e2'.
	self assert: (tree at: 4) equals: { tree at: 2. 13 }.
	self assert: ((tree at: 2) at: 14) class equals: SimdJSONFlatMap.
	dictionary := self readFFI: json.
	self assert: (dictionary at: 13) equals: 100.
	self assert: ((dictionary at: 14) at: 'k') equals: #( nil ).
	self assert: (dictionary at: 6) class equals: Dictionary
]

{ #category : 'tests' }
SimdJSONFFITests >> testFloats [

	"With exactNumbers (the default) a number with an exponent is converted with NeoJSON's
	 rules, 1e-2 is 1/100; without, it is simdjson's double (the compiler reads the literal
	 5e-324 as 0.0: Float fminDenormalized)"

	self assert: (self readFFI: '[0.0, -0.5, 2.5, 1e-2]') equals: { 0.0. -0.5. 2.5. 1/100 }.
	self assert: (self readFFI: '-0.0') signBit equals: 1.
	SimdJSONReader testHook: #pluginMissing value: true.
	self
		assert: ((SimdJSONReader on: '[1.7976931348623157e308, 5e-324, 2.5e-3]' readStream)
			exactNumbers: false;
			next)
		equals: { Float fmax. Float fminDenormalized. 2.5e-3 }
]

{ #category : 'tests' }
SimdJSONFFITests >> testIntegers [
	"Around the limit of the small integers of the tape (2^52), of int64 and of uint64"

	| limits |
	limits := { 1 << 52 - 1. 1 << 52. (1 << 52 - 1) negated. (1 << 52) negated. SmallInteger maxVal. SmallInteger minVal.
		1 << 63 - 1. (1 << 63) negated. 1 << 64 - 1. 1 << 64. (1 << 63 + 1) negated }.
	self
		assert: (self readFFI: '[' , (String streamContents: [ :stream |
			limits do: [ :each | stream print: each ] separatedBy: [ stream nextPut: $, ] ]) , ']')
		equals: limits
]

{ #category : 'tests' }
SimdJSONFFITests >> testLargeTape [
	"A tape larger than the scratch buffer is copied by sj_ffi_take"

	| json value |
	json := String streamContents: [ :stream |
		stream nextPut: $[.
		1 to: 20000 do: [ :i | stream nextPutAll: '"s'; print: i; nextPutAll: '",' ].
		stream nextPutAll: '{"x":1e2}]' ].
	self assert: json size * 2 > SimdJSONLibrary scratchSize.
	value := self readFFI: json.
	self assert: value size equals: 20001.
	self assert: value first equals: 's1'.
	self assert: (value at: 20000) equals: 's20000'.
	self assert: value last equals: (Dictionary new at: 'x' put: 100; yourself)
]

{ #category : 'tests' }
SimdJSONFFITests >> testMessages [

	self assert: (SimdJSONLibrary errorMessage: 1) notEmpty.
	self assert: (SimdJSONLibrary errorMessage: 1001) equals: 'byte order mark (U+FEFF) at the start of a value'.
	self assert: (SimdJSONLibrary errorMessage: 99999) isNil.
	SimdJSONReader testHook: #pluginMissing value: true.
	self
		should: [ self read: '[1,' ]
		raise: SimdJSONParseError
		withExceptionDo: [ :error | self assert: (error messageText beginsWith: 'simdjson: TAPE_ERROR') ]
]

{ #category : 'tests' }
SimdJSONFFITests >> testNumberTexts [
	"The text of a number is a fixup where it stays: at the root, in an Array, a
	 SimdJSONFlatMap, a Dictionary; not where a later duplicate key replaced it"

	| result |
	result := self library: '1e2' flags: SimdJSONReader flagExact.
	self assert: (result at: 2) equals: '1e2'.
	self assert: (result at: 4) equals: { result. 2 }.
	result := self library: '{"a":1e2,"b":[3,1e3]}' flags: SimdJSONReader flagExact.
	self assert: (result at: 4) size equals: 4.
	self assert: (result at: 4) first identicalTo: (result at: 2).
	self assert: (result at: 4) second equals: 2.
	result := self library: '{"a":1e2,"a":3}' flags: SimdJSONReader flagExact + SimdJSONReader flagDict.
	self assert: (result at: 4) isNil.
	self assert: ((result at: 2) at: 'a') equals: 3.
	result := self library: '{"a":3,"a":1e2}' flags: SimdJSONReader flagExact + SimdJSONReader flagDict.
	self assert: (result at: 4) first identicalTo: ((result at: 2) associationAt: 'a').
	self assert: (self readFFI: '{"a":1e2,"b":{"a":3,"a":1e-1},"c":[2e0]}')
		equals: (Dictionary new
			at: 'a' put: 100;
			at: 'b' put: (Dictionary new at: 'a' put: 1/10; yourself);
			at: 'c' put: #( 2 );
			yourself)
]

{ #category : 'tests' }
SimdJSONFFITests >> testSameAsThePlugin [
	"The library answers what the plugin answers, in each mode"

	| documents |
	SimdJSONReader pluginAvailable ifFalse: [ ^ self skip: 'no SimdJSONPlugin to compare with' ].
	documents := {
		'{"a":[1,2.5,"x",null,true,false,{"b":{}}],"c":1e2,"d":12345678901234567890123,"a":7}'.
		'["' , (self string: #( 16rE9 16r20AC 16r1F600 )) , '", "\u0000", "\ud83d\ude00"]'.
		'"' , (String new: 300 withAll: $z) , '"'.
		self probeJSON }.
	documents do: [ :json |
		#( 0 2 4 6 8 10 ) do: [ :flags | | plugin library |
			plugin := self prim: json from: 1 to: json size flags: flags budget: -1 maxUnits: -1.
			(flags anyMask: 4) ifTrue: [
				plugin := SimdJSONReader
					primRead: json from: 1 to: json size flags: flags budget: -1 maxUnits: -1
					objectClass: Dictionary associationClass: Association wideStringClass: WideString
					hashSeed: ByteString hash dictLayout: SimdJSONReader dictLayout ].
			library := self library: json flags: flags.
			self assert: library first equals: plugin first.
			self assert: (library at: 3) equals: (plugin at: 3).
			(flags anyMask: 8) ifFalse: [
				self assert: (library at: 4) isNil equals: (plugin at: 4) isNil.
				self assert: (self plain: library) equals: (self plain: plugin) ] ] ]
]

{ #category : 'tests' }
SimdJSONFFITests >> testSources [
	"A ByteString (Latin-1), a WideString (UTF-32) and a ByteArray (UTF-8), read in place"

	| euro |
	euro := self string: #( 16r20AC ).
	self assert: (self readFFI: '["', (self string: #( 16rE9 )), '"]') equals: { self string: #( 16rE9 ) }.
	self assert: (self readFFI: '["', euro, '", 1]') equals: { euro. 1 }.
	SimdJSONReader testHook: #pluginMissing value: true.
	self assert: (SimdJSONReader fromBytes: ('["', euro, '"]') utf8Encoded) equals: { euro }
]

{ #category : 'tests' }
SimdJSONFFITests >> testSourcesAsThePlugin [
	"The library reads, refuses and decodes every source as primitiveRead: exactly a
	 ByteArray as UTF-8, any other byte object as Latin-1, any 32-bit word object as UTF-32,
	 copied by its format rather than passed by its own tfPointerAddress, of a class rooted
	 at ProtoObject too; and refuses the numbers beyond the SmallIntegers, and the proxies of
	 SmallIntegers, as it does"

	| eacute euro integer sources plugin library large |
	SimdJSONReader pluginAvailable ifFalse: [ ^ self skip: 'no SimdJSONPlugin to compare with' ].
	eacute := self string: #( 16rE9 ).
	euro := self string: #( 16r20AC ).
	integer := self integerOfBytes: '[1]      '.
	sources := {
		('["', euro, '"]') utf8Encoded. '["', eacute, '"]'. ('["', eacute, '"]') asSymbol.
		('["', euro, '"]') asSymbol. self externalAddress: #[ 91 34 16rC3 16rA9 34 93 32 32 ].
		ExternalAddress new. integer. integer negated. self words: '{"a":"', euro, '"} [2]'.
		WordArray withAll: #( 34 16rD800 34 ). WordArray new. Bitmap withAll: #( 91 49 93 ).
		IntegerArray withAll: #( 34 -1 34 ). 1.0e300. DoubleWordArray new: 2. DoubleByteArray new: 2.
		Object >> #printString. Object new. nil. 42. '[1]' asText.
		self outsideObject: SimdJSONTestProtoBytes of: '["', eacute, '"]'.
		self outsideObject: SimdJSONTestProtoWords of: '["', euro, '"]'.
		SimdJSONTestProxy on: '[1]'. SimdJSONTestProxy on: '[1]' utf8Encoded }.
	sources do: [ :source | | units |
		units := thisContext objectSize: source.
		{ 1 -> units. 1 -> 0. 2 -> units. (units + 2) -> units } do: [ :range |
			#( 0 1 2 4 8 ) do: [ :flags |
				plugin := (flags anyMask: 4)
					ifTrue: [
						SimdJSONReader
							primRead: source from: range key to: range value flags: flags budget: -1 maxUnits: -1
							objectClass: Dictionary associationClass: Association wideStringClass: WideString
							hashSeed: ByteString hash dictLayout: SimdJSONReader dictLayout ]
					ifFalse: [ self prim: source from: range key to: range value flags: flags budget: -1 maxUnits: -1 ].
				library := SimdJSONLibrary read: source from: range key to: range value flags: flags maxUnits: -1.
				self assert: library isSimdJSONFailure equals: plugin isSimdJSONFailure.
				library isSimdJSONFailure
					ifTrue: [ self assert: library ec equals: plugin ec ]
					ifFalse: [
						self assert: library first equals: plugin first.
						self assert: (library at: 3) equals: (plugin at: 3).
						self assert: (library at: 6) equals: (plugin at: 6).
						(library first = 0 and: [ (flags anyMask: 8) not ]) ifTrue: [
							self assert: (self plain: library) equals: (self plain: plugin) ] ] ] ] ].
	large := 2 raisedTo: 70.
	{ { large. large. 0. -1 }. { large negated. 3. 0. -1 }. { 1. large. 0. -1 }.
	  { 1. 3. 0. SmallInteger maxVal + 1 }. { 1. 3. 0. large }. { 1. 3. large. -1 }.
	  { SimdJSONTestProxy on: 1. 3. 0. -1 }. { 1. SimdJSONTestProxy on: 3. 0. -1 }.
	  { 1. 3. SimdJSONTestProxy on: 0. -1 }. { 1. 3. 0. SimdJSONTestProxy on: -1 } } do: [ :each |
		plugin := self prim: '[1]' from: each first to: each second flags: each third budget: -1 maxUnits: each fourth.
		library := SimdJSONLibrary read: '[1]' from: each first to: each second flags: each third maxUnits: each fourth.
		self assert: plugin isSimdJSONFailure.
		self assert: library isSimdJSONFailure.
		self assert: library ec equals: plugin ec ]
]

{ #category : 'tests' }
SimdJSONFFITests >> testTicket [
	"What a read keeps for sj_ffi_take, a tape larger than the buffer and the words of the
	 WideStrings, is lost to a read that comes in between"

	| library buffer ticket size tape words |
	library := SimdJSONLibrary uniqueInstance.
	buffer := ByteArray new: 64.
	self assert: (library primRead: '[1,2]' encoding: 1 units: 5 start0: 0 stop0: 5 flags: 0 maxUnits: -1 buffer: buffer capacity: 64) equals: 0.
	self assert: (buffer int64AtOffset: 40) equals: 0.
	self assert: (buffer int64AtOffset: 48) equals: 0.
	size := buffer int64AtOffset: 24.
	ticket := buffer int64AtOffset: 32.
	self assert: (library primRead: '[3]' encoding: 1 units: 3 start0: 0 stop0: 3 flags: 0 maxUnits: -1 buffer: buffer capacity: 64) equals: 0.
	tape := ByteArray new: size.
	self assert: (library primTake: tape size: size words: tape count: 0 ticket: ticket) equals: -1.
	tape := ByteArray new: (buffer int64AtOffset: 24).
	self assert: (library primTake: tape size: tape size words: tape count: 0 ticket: (buffer int64AtOffset: 32)) equals: 0.
	self assert: (SimdJSONTapeDecoder new decode: tape at: 0 words: nil flags: 0) equals: #( 3 ).
	"an inline tape, and words"
	buffer := ByteArray new: 1024.
	self assert: (library primRead: '["\u20ac!"]' encoding: 1 units: 11 start0: 0 stop0: 11 flags: 0 maxUnits: -1 buffer: buffer capacity: 1024) equals: 0.
	self assert: (buffer int64AtOffset: 40) equals: 1.
	self assert: (buffer int64AtOffset: 48) equals: 2.
	words := WordArray new: 2.
	self assert: (library primTake: buffer size: 0 words: words count: 2 ticket: (buffer int64AtOffset: 32)) equals: 0.
	self assert: words asArray equals: #( 16r20AC 33 ).
	self
		assert: (SimdJSONTapeDecoder new decode: buffer at: 64 words: words flags: 0)
		equals: { self string: #( 16r20AC 33 ) }.
	self assert: (library primTake: buffer size: 0 words: words count: 2 ticket: (buffer int64AtOffset: 32)) equals: -1.
	self assert: (library primRead: '[1]' encoding: 1 units: 3 start0: 0 stop0: 3 flags: 0 maxUnits: -1 buffer: buffer capacity: 63) equals: -1
]

{ #category : 'tests' }
SimdJSONFFITests >> testWideStrings [
	"Many WideStrings, inline and in a tape copied by sj_ffi_take, among ByteStrings"

	| wide json value |
	wide := self string: #( 16r20AC 16r41 16r1F600 ).
	#( 10 5000 ) do: [ :n |
		json := String streamContents: [ :stream |
			stream nextPut: $[.
			1 to: n do: [ :i | stream nextPut: $"; nextPutAll: wide; print: i; nextPutAll: '","b' ; print: i; nextPutAll: '",' ].
			stream nextPutAll: '{"' , wide , '":"' , wide , '"}]' ].
		value := self readFFI: json.
		self assert: value size equals: 2 * n + 1.
		self assert: (value at: 2 * n - 1) equals: wide , n printString.
		self assert: (value at: 2 * n - 1) class equals: WideString.
		self assert: (value at: 2 * n) equals: 'b' , n printString.
		self assert: (value at: 2 * n) class equals: ByteString.
		self assert: (value last at: wide) equals: wide ]
]

{ #category : 'helpers' }
SimdJSONFFITests >> write: anObject flags: flags maxDepth: depth [
	"The answer of the library for anObject, at level 0; when the VM has the plugin, checked
	 against primitiveWrite's: the same status, output, code and holes, the culprit and the
	 objects of the holes identical"

	| library plugin |
	library := SimdJSONLibrary write: anObject flags: flags newLine: String lf level: 0 maxDepth: depth maxBytes: -1.
	SimdJSONReader pluginAvailable ifFalse: [ ^ library ].
	plugin := SimdJSONWriter
		primWrite: anObject flags: flags newLine: String lf level: 0 maxDepth: depth maxBytes: -1
		classes: SimdJSONWriter writeClasses layout: SimdJSONWriter writeLayout.
	self assert: library first equals: plugin first.
	self assert: (library at: 2) equals: (plugin at: 2).
	self assert: (library at: 2) class equals: (plugin at: 2) class.
	self assert: (library at: 3) isNil equals: (plugin at: 3) isNil.
	(plugin at: 3) ifNotNil: [ :holes |
		self assert: (library at: 3) size equals: holes size.
		1 to: holes size do: [ :i | self assert: ((library at: 3) at: i) identicalTo: (holes at: i) ] ].
	self assert: (library at: 4) equals: (plugin at: 4).
	self assert: (library at: 5) identicalTo: (plugin at: 5).
	^ library
]

{ #category : 'helpers' }
SimdJSONFFITests >> writeValues [
	"Values of every kind the walk writes, holes among them (which the writer writes as
	NeoJSON does: instances of subclasses of the classes the walk knows too), and nested"

	| wide dictionary |
	wide := self string: #( 16r20AC 16r41 16r1F600 9 34 ).
	dictionary := Dictionary new.
	dictionary at: 'a' put: 1; at: wide put: #( 2 3 ); at: #sym put: nil; at: 'f' put: 0.1; at: 'e' put: Dictionary new.
	^ {
		nil. true. false. 0. -7. 4503599627370495. 4503599627370496. -4503599627370496. SmallInteger maxVal. SmallInteger minVal.
		1 << 64. (1 << 100) negated. 123456789012345678901234567890.
		0.0. -0.0. 0.1. 100.0. 1.0e6. 1.0e-5. Float fmax. Float fminDenormalized.
		''. 'abc'. 'a"b\c/d' , (String with: Character tab with: (Character value: 1) with: (Character value: 127)). (self string: #( 16rE9 16rFF )). wide. #sym. #wide.
		#(). #( 1 #( 2 #( 3 ) ) ). OrderedCollection new. (OrderedCollection withAll: #( 1 2 3 )) removeFirst; yourself.
		Dictionary new. dictionary.
		{ 1/2. Set with: 1. 2 ** 0.5. 3.25s2. Bag with: 'b'. OrderedDictionary new at: 'o' put: 1; yourself.
			IdentityDictionary new at: 'i' put: 1; yourself. SortedCollection withAll: #( 2 1 ). WeakArray with: 3.
			WeakOrderedCollection with: 4. SimdJSONTestOwnList withAll: #( 5 ) }.
		{ 1. { 2. 1/3 }. dictionary. 1 to: 3 } }
]

{ #category : 'tests - writing' }
SimdJSONFFITests >> testWriteCulprits [
	"The errors of primitiveWrite, with their culprits"

	| library deep key |
	library := SimdJSONLibrary uniqueInstance.
	key := 3 @ 4.
	(library write: (Dictionary new at: key put: 1; yourself) flags: 0 newLine: String lf level: 0 maxDepth: 1024 maxBytes: -1)
		in: [ :r | self assert: r first equals: 2. self assert: (r at: 4) equals: 1. self assert: (r at: 5) identicalTo: key ].
	(library write: { 1. Float nan } flags: 0 newLine: String lf level: 0 maxDepth: 1024 maxBytes: -1)
		in: [ :r | self assert: r first equals: 2. self assert: (r at: 4) equals: 2. self assert: (r at: 5) isNaN ].
	self
		assert: ((library write: { Float infinity } flags: 8 newLine: String lf level: 0 maxDepth: 1024 maxBytes: -1) at: 2)
		equals: '[null]'.
	deep := #( 1 ).
	5 timesRepeat: [ deep := { deep } ].
	(library write: deep flags: 0 newLine: String lf level: 0 maxDepth: 3 maxBytes: -1)
		in: [ :r | self assert: r first equals: 2. self assert: (r at: 4) equals: 3. self assert: (r at: 5) size equals: 1 ].
	(library write: { 'ok'. WideString with: (Character value: 16r110000) } flags: 0 newLine: String lf level: 0 maxDepth: 1024 maxBytes: -1)
		in: [ :r | self assert: r first equals: 2. self assert: (r at: 4) equals: 4. self assert: (r at: 5) class equals: WideString ].
	(library write: (String new: 100 withAll: $a) flags: 0 newLine: String lf level: 0 maxDepth: 1024 maxBytes: 50)
		in: [ :r | self assert: r first equals: 3 ]
]

{ #category : 'tests - writing' }
SimdJSONFFITests >> testWriteArguments [
	"The library refuses the arguments that primitiveWrite refuses, with #'bad argument',
	and accepts the ones at the limits: flags 0 to 31, level and maxDepth 0 to 100000,
	maxBytes from -1, SmallIntegers (not their proxies), a newLine that is exactly a
	ByteString"

	| refused accepted call |
	call := [ :args :prim |
		prim
			ifTrue: [
				SimdJSONWriter
					primWrite: #( 1 ) flags: (args at: 1) newLine: (args at: 2) level: (args at: 3)
					maxDepth: (args at: 4) maxBytes: (args at: 5)
					classes: SimdJSONWriter writeClasses layout: SimdJSONWriter writeLayout ]
			ifFalse: [
				SimdJSONLibrary
					write: #( 1 ) flags: (args at: 1) newLine: (args at: 2) level: (args at: 3)
					maxDepth: (args at: 4) maxBytes: (args at: 5) ] ].
	refused := {
		{ 32. String lf. 0. 1024. -1 }. { -1. String lf. 0. 1024. -1 }. { nil. String lf. 0. 1024. -1 }.
		{ 0. String lf. -1. 1024. -1 }. { 0. String lf. 100001. 1024. -1 }. { 0. String lf. 1 << 70. 1024. -1 }.
		{ 0. String lf. 0. -1. -1 }. { 0. String lf. 0. 100001. -1 }. { 0. String lf. 0. 1.5. -1 }.
		{ 0. String lf. 0. 1024. -2 }. { 0. String lf. 0. 1024. 1 << 70 }.
		{ 0. #lf. 0. 1024. -1 }. { 0. String lf asWideString. 0. 1024. -1 }. { 0. nil. 0. 1024. -1 }.
		{ SimdJSONTestProxy on: 0. String lf. 0. 1024. -1 }. { 0. SimdJSONTestProxy on: String lf. 0. 1024. -1 }.
		{ 0. String lf. SimdJSONTestProxy on: 0. 1024. -1 }. { 0. String lf. 0. SimdJSONTestProxy on: 1024. -1 }.
		{ 0. String lf. 0. 1024. SimdJSONTestProxy on: -1 } }.
	accepted := {
		{ 0. String lf. 0. 0. -1 }. { 31. String lf. 0. 1024. -1 }. { 0. String lf. 100000. 100000. -1 }.
		{ 0. ''. 0. 1024. 0 }. { 0. String crlf. 0. 1024. SmallInteger maxVal } }.
	refused do: [ :args |
		self assert: ((call value: args value: false) in: [ :r | r isSimdJSONFailure and: [ r ec = #'bad argument' ] ]).
		SimdJSONReader pluginAvailable ifTrue: [
			self assert: ((call value: args value: true) in: [ :r | r isSimdJSONFailure and: [ r ec = #'bad argument' ] ]) ] ].
	accepted do: [ :args | | library |
		library := call value: args value: false.
		self deny: library isSimdJSONFailure.
		SimdJSONReader pluginAvailable ifTrue: [ | plugin |
			plugin := call value: args value: true.
			self deny: plugin isSimdJSONFailure.
			self assert: library first equals: plugin first.
			self assert: (library at: 2) equals: (plugin at: 2).
			self assert: (library at: 4) equals: (plugin at: 4) ] ]
]

{ #category : 'tests - writing' }
SimdJSONFFITests >> testWriteExactClasses [
	"An instance of a subclass of a class that primitiveWrite knows, or of the class of nil,
	 true or false, is a hole, as for the plugin; as a key, it is not a string"

	| values r key |
	values := { IdentityDictionary new. SortedCollection new. WeakArray new: 1. True basicNew. UndefinedObject basicNew }.
	r := self write: values flags: 4 maxDepth: 1024.
	self assert: r first equals: 0.
	self assert: (r at: 2) equals: '[,,,,]' asByteArray.
	self assert: (r at: 3) size equals: 15.
	values doWithIndex: [ :each :i |
		self assert: ((r at: 3) at: 3 * i - 2) equals: i.
		self assert: ((r at: 3) at: 3 * i - 1) identicalTo: each.
		self assert: ((r at: 3) at: 3 * i) equals: 1 ].
	key := KeyedTree new.
	r := self write: (Dictionary new at: key put: 1; yourself) flags: 0 maxDepth: 1024.
	self assert: r first equals: 2.
	self assert: (r at: 4) equals: 1.
	self assert: (r at: 5) identicalTo: key.
	SimdJSONReader testHook: #pluginMissing value: true.
	self
		assert: (SimdJSONWriter toString: {
			IdentityDictionary new at: 'i' put: 1; yourself. SortedCollection withAll: #( 2 1 ).
			WeakArray with: 3. SimdJSONTestOwnList withAll: #( 5 ) })
		equals: '[{"i":1},[1,2],[3],{"own":[5]}]'
]

{ #category : 'tests - writing' }
SimdJSONFFITests >> testWriteDictionaryEntries [
	"A Dictionary with an entry that is not exactly an Association (an instance of a
	 subclass, added with add:) is a hole, as for the plugin, its keys and values not walked,
	 also when the entries before it hold holes, NaNs and WideStrings: the hole before it is
	 numbered first, and the writer writes it as a map"

	| entryClass bad nan big entry r |
	entryClass := Association newAnonymousSubclass.
	bad := Dictionary new add: (entryClass key: 5 value: 1); yourself.
	r := self write: { $x. bad } flags: 4 maxDepth: 1024.
	self assert: r first equals: 0.
	self assert: (r at: 2) equals: '[,]' asByteArray.
	self assert: (r at: 3) size equals: 6.
	self assert: ((r at: 3) at: 2) identicalTo: $x.
	self assert: ((r at: 3) at: 5) identicalTo: bad.
	nan := Dictionary new add: (entryClass key: 'a' value: Float nan); at: 'b' put: { 2 }; yourself.
	r := self write: { 3 @ 4. nan } flags: 0 maxDepth: 1024.
	self assert: r first equals: 0.
	self assert: (r at: 3) size equals: 6.
	self assert: ((r at: 3) at: 5) identicalTo: nan.
	r := self write: { bad } flags: 0 maxDepth: 0.
	self assert: r first equals: 2.
	self assert: (r at: 5) identicalTo: bad.
	big := Dictionary new.
	1 to: 50 do: [ :i |
		big at: i printString put: { 3 @ i. self string: #( 16r20AC ). String new: 3000 withAll: $a. Float nan } ].
	entry := entryClass key: 'z' value: 1.
	big add: entry.
	self assert: (big array indexOf: entry) > (big array findFirst: [ :each | each notNil ]).
	r := self write: { big. 1 / 2 } flags: 0 maxDepth: 1024.
	self assert: r first equals: 0.
	self assert: (r at: 2) equals: '[,]'.
	self assert: (r at: 3) size equals: 6.
	self assert: ((r at: 3) at: 2) identicalTo: big.
	self assert: ((r at: 3) at: 5) equals: 1 / 2.
	SimdJSONReader testHook: #pluginMissing value: true.
	self
		assert: (SimdJSONWriter toString: { Dictionary new add: (entryClass key: 'a' value: { 1 }); yourself })
		equals: '[{"a":[1]}]'.
	self
		should: [ SimdJSONWriter toString: { $x. bad } ]
		raise: SimdJSONMappingNotFound
		withExceptionDo: [ :error |
			self assert: error messageText equals: 'No mapping found for Character in SimdJSONWriter' ]
]

{ #category : 'tests - writing' }
SimdJSONFFITests >> testWriteHoles [
	"The objects the walk does not write are holes, at their position and level"

	| point r |
	point := 3 @ 4.
	r := SimdJSONLibrary write: { 1. point. (self string: #( 16r20AC )). point } flags: 1 newLine: String lf level: 2 maxDepth: 1024 maxBytes: -1.
	self assert: r first equals: 0.
	self assert: (r at: 2) class equals: WideString.
	self assert: (r at: 3) size equals: 6.
	self assert: (r at: 3) second identicalTo: point.
	self assert: (r at: 3) third equals: 3.
	self assert: ((r at: 2) first: (r at: 3) first) equals: '[' , String lf , (String new: 3 withAll: Character tab) , '1,' , String lf , (String new: 3 withAll: Character tab).
	r := SimdJSONLibrary write: { 1. point } flags: 4 newLine: String lf level: 0 maxDepth: 1024 maxBytes: -1.
	self assert: (r at: 2) equals: '[1,]' asByteArray.
	self assert: (r at: 3) equals: { 3. point. 1 }.
	self
		assert: (((SimdJSONLibrary write: { 1.5 } flags: 16 newLine: String lf level: 0 maxDepth: 1024 maxBytes: -1) at: 3) collect: [ :each | each ])
		equals: #( 1 1.5 1 )
]

{ #category : 'tests - writing' }
SimdJSONFFITests >> testWriteLarge [
	"An output larger than the scratch buffer is copied by sj_ffi_take_output, with its holes"

	| value json |
	value := (1 to: 20000) collect: [ :i | i odd ifTrue: [ 'value' , i printString ] ifFalse: [ i / 3 ] ].
	SimdJSONReader testHook: #pluginMissing value: true.
	json := SimdJSONWriter toString: value.
	self assert: json size > SimdJSONLibrary scratchSize.
	self assert: (json beginsWith: '["value1",0.6666666666666666,"value3",').
	self assert: (SimdJSONWriter toBytes: value) equals: json utf8Encoded.
	value := (1 to: 5000) collect: [ :i | self string: #( 16r20AC 16r41 ) ].
	json := SimdJSONWriter toString: value.
	self assert: json class equals: WideString.
	self assert: (self readFFI: json) equals: value
]

{ #category : 'tests - writing' }
SimdJSONFFITests >> testWriteNumbering [
	"The immediates but SmallIntegers, and the Floats with floatHoles, are holes without the
	 check of the depth; ByteSymbols and WideSymbols are strings, as keys too; the holes, the
	 culprits, the NaNs and the WideStrings are numbered in the order of the walk, by which
	 the library names the culprit"

	| wide half point nan deep key r |
	r := self write: { $a. 7. 1.0e300 } flags: 4 maxDepth: 0.
	self assert: r first equals: 0.
	self assert: (r at: 2) equals: '[,7,1.0e300]' asByteArray.
	self assert: (r at: 3) asArray equals: { 1. $a. 1 }.
	r := self write: { 1.5. 2.0e300 } flags: 16 maxDepth: 0.
	self assert: r first equals: 0.
	self assert: (r at: 3) asArray equals: #( 1 1.5 1 2 2.0e300 1 ).
	half := 1 / 2.
	r := self write: { half } flags: 4 maxDepth: 0.
	self assert: r first equals: 2.
	self assert: (r at: 4) equals: 3.
	self assert: (r at: 5) identicalTo: half.
	wide := self string: #( 16r20AC ).
	self assert: wide asSymbol class equals: WideSymbol.
	r := self write: { #b. wide asSymbol. Dictionary new at: #b put: 1; at: wide asSymbol put: 2; yourself } flags: 0 maxDepth: 1024.
	self assert: r first equals: 0.
	self assert: (r at: 3) isNil.
	self assert: (((r at: 2) beginsWith: '["b","' , wide , '",{"') and: [ ((r at: 2) includesSubstring: '"b":1') and: [ (r at: 2) includesSubstring: '"' , wide , '":2' ] ]).
	point := 3 @ 4.
	r := self write: { half. wide. point. $c } flags: 4 maxDepth: 1024.
	self assert: (r at: 2) equals: ('[,"' , wide , '",,]') utf8Encoded.
	self assert: (r at: 3) size equals: 9.
	{ half. point. $c } doWithIndex: [ :each :i | self assert: ((r at: 3) at: 3 * i - 1) identicalTo: each ].
	nan := Float nan.
	r := self write: { half. wide. point. $c. nan } flags: 0 maxDepth: 1024.
	self assert: r first equals: 2.
	self assert: (r at: 4) equals: 2.
	self assert: (r at: 5) identicalTo: nan.
	deep := { 'x' }.
	r := self write: { half. wide. point. $c. { deep }. nan } flags: 0 maxDepth: 2.
	self assert: r first equals: 2.
	self assert: (r at: 4) equals: 3.
	self assert: (r at: 5) identicalTo: deep first.
	key := 4 @ 5.
	r := self write: { half. wide. Dictionary new at: 'k' put: point; at: key put: 1; yourself } flags: 0 maxDepth: 1024.
	self assert: r first equals: 2.
	self assert: (r at: 4) equals: 1.
	self assert: (r at: 5) identicalTo: key
]

{ #category : 'tests - writing' }
SimdJSONFFITests >> testWriteSameAsThePlugin [
	"The library writes what the plugin writes, character for character, in each mode"

	| plain |
	SimdJSONReader pluginAvailable ifFalse: [ ^ self skip: 'no SimdJSONPlugin to compare with' ].
	plain := SimdJSONWriter new.
	self writeValues , { self writeValues } do: [ :value |
		#( #( false false ) #( true false ) #( false true ) #( true true ) ) do: [ :modes |
			{ [ :writer | writer stringFor: value ]. [ :writer | writer bytesFor: value ] } do: [ :block | | make plugin library |
				make := [ (SimdJSONWriter new) prettyPrint: modes first; asciiOnly: modes second; newLine: String crlf; yourself ].
				SimdJSONReader testHook: #pluginMissing value: nil.
				plugin := block value: make value.
				SimdJSONReader testHook: #pluginMissing value: true.
				library := block value: make value.
				self assert: library equals: plugin.
				self assert: library class equals: plugin class ] ] ]
]

{ #category : 'tests - writing' }
SimdJSONFFITests >> testWriterBackend [
	"Without the plugin the writer writes through the library; without either it signals"

	SimdJSONReader testHook: #pluginMissing value: true.
	self assert: (SimdJSONWriter toString: #( 1 'a' nil )) equals: '[1,"a",null]'.
	self assert: (SimdJSONWriter toStringPretty: (Dictionary new at: 'k' put: #(); yourself)) equals: '{' , OSPlatform current lineEnding , (String with: Character tab) , '"k" : [ ]' , OSPlatform current lineEnding , '}'.
	SimdJSONReader testHook: #fallbackMissing value: true.
	self should: [ SimdJSONWriter toString: #( 1 ) ] raise: SimdJSONResourceError
]

