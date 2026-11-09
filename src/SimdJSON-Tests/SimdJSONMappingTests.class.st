Class {
	#name : 'SimdJSONMappingTests',
	#superclass : 'SimdJSONTestCase',
	#category : 'SimdJSON-Tests-Tests',
	#package : 'SimdJSON-Tests',
	#tag : 'Tests'
}

{ #category : 'helpers' }
SimdJSONMappingTests >> pointJSON [

	^ '{"x":1,"y":2}'
]

{ #category : 'tests' }
SimdJSONMappingTests >> testAccessorsAndNames [

	| object |
	object := (self reader: '{"id":7,"name":"n"}')
		for: SimdJSONTestObject do: [ :mapping | mapping mapAccessors: #( #id #name ) ];
		nextAs: SimdJSONTestObject.
	self assert: object id equals: 7.
	self assert: object name equals: 'n'.
	self
		assert: ((self reader: '{"X":1,"Y":2}')
			for: Point do: [ :mapping | mapping mapInstVar: #x to: 'X'; mapInstVar: #y to: 'Y' ];
			nextAs: Point)
		equals: 1 @ 2.
	self
		assert: ((self reader: '{"both":5}')
			for: Point do: [ :mapping |
				mapping mapProperty: 'both' getter: [ :point | point x ] setter: [ :point :value | point setX: value setY: value ] ];
			nextAs: Point)
		equals: 5 @ 5
]

{ #category : 'tests' }
SimdJSONMappingTests >> testAllowNil [

	| reader |
	reader := self reader: 'null [{"x":1,"y":2},null] true'.
	reader mapInstVarsFor: Point.
	reader for: Point do: [ :mapping | mapping allowNil ].
	self assert: (reader nextAs: Point) isNil.
	self assert: (reader nextListAs: Point) equals: { 1 @ 2. nil }.
	self
		should: [ reader nextAs: Point ]
		raise: SimdJSONParseError
		withExceptionDo: [ :error | self assert: error messageText equals: 'Unexpected boolean constant' ].
	self
		should: [ (self reader: 'null') mapInstVarsFor: Point; nextAs: Point ]
		raise: SimdJSONParseError
		withExceptionDo: [ :error | self assert: error messageText equals: '{ expected' ]
]

{ #category : 'tests' }
SimdJSONMappingTests >> testClassSideMapping [
	"SimdJSONTestObject class>>neoJsonMapping:, through fromString:as: and fromBytes:as:"

	| json object |
	json := '{"id":7,"name":"seven","points":[{"x":1,"y":2},{"x":3,"y":4}],"created-at":"1234","tags":["a","b"],"extra":[1]}'.
	{ SimdJSONReader fromString: json as: SimdJSONTestObject.
	  SimdJSONReader fromBytes: json asByteArray as: SimdJSONTestObject } do: [ :each |
		object := each.
		self assert: object class equals: SimdJSONTestObject.
		self assert: object id equals: 7.
		self assert: object name equals: 'seven'.
		self assert: object points equals: { 1 @ 2. 3 @ 4 }.
		self assert: object stamp equals: 1234.
		self assert: object tags equals: (OrderedCollection withAll: #( 'a' 'b' )) ]
]

{ #category : 'tests' }
SimdJSONMappingTests >> testDecoder [

	self
		assert: ((self reader: '"42"') for: #Number customDo: [ :mapping | mapping decoder: [ :string | string asNumber ] ]; nextAs: #Number)
		equals: 42.
	self
		assert: ((self reader: '[1,2,3]') for: #Sum customDo: [ :mapping | mapping decoder: [ :list | list sum ] ]; nextAs: #Sum)
		equals: 6.
	self
		assert: ((self reader: '[1,{"a":2}]') for: #Plain customDo: [ :mapping | ]; nextAs: #Plain)
		equals: { 1. Dictionary new at: 'a' put: 2; yourself }
]

{ #category : 'tests' }
SimdJSONMappingTests >> testLists [

	| reader |
	reader := self reader: '[{"x":1,"y":2}] [1,2,3] [{"x":3,"y":4}]'.
	reader mapInstVarsFor: Point.
	reader for: #Points customDo: [ :mapping | mapping listOfElementSchema: Point ].
	reader for: #Numbers customDo: [ :mapping | mapping listOfType: OrderedCollection ].
	reader for: #OrderedPoints customDo: [ :mapping | mapping listOfType: OrderedCollection andElementSchema: Point ].
	self assert: (reader nextAs: #Points) equals: { 1 @ 2 }.
	self assert: (reader nextAs: #Numbers) equals: (OrderedCollection withAll: #( 1 2 3 )).
	self assert: (reader nextAs: #OrderedPoints) equals: (OrderedCollection with: 3 @ 4)
]

{ #category : 'tests' }
SimdJSONMappingTests >> testMapWithValueSchema [

	| json value |
	json := '{"b":{"x":1,"y":2},"a":{"x":3,"y":4}}'.
	value := (self reader: json)
		mapInstVarsFor: Point;
		for: #PointMap customDo: [ :mapping | mapping mapWithValueSchema: Point ];
		nextAs: #PointMap.
	self assert: value class equals: Dictionary.
	self assert: (value at: 'b') equals: 1 @ 2.
	self assert: (value at: 'a') equals: 3 @ 4.
	value := (self reader: json)
		mapClass: OrderedDictionary;
		mapInstVarsFor: Point;
		for: #PointMap customDo: [ :mapping | mapping mapWithValueSchema: Point ];
		nextAs: #PointMap.
	self assert: value class equals: OrderedDictionary.
	self assert: value keys asArray equals: #( 'b' 'a' )
]

{ #category : 'tests' }
SimdJSONMappingTests >> testMappingLenientInput [

	| reader |
	reader := (self reader: '{"x":01,"y":2}') mapInstVarsFor: Point; yourself.
	self should: [ reader nextAs: Point ] raise: SimdJSONParseError
]

{ #category : 'tests' }
SimdJSONMappingTests >> testMappingNotFound [
	"The mapping is looked up before anything is parsed"

	self
		should: [ (self reader: self pointJSON) nextAs: Point ]
		raise: SimdJSONMappingNotFound
		withExceptionDo: [ :error |
			self assert: error messageText equals: 'No mapping found for Point in SimdJSONReader' ].
	self should: [ (self reader: self pointJSON) nextAs: #Unknown ] raise: SimdJSONMappingNotFound.
	self should: [ SimdJSONReader fromString: '[1,' as: #Unknown ] raise: SimdJSONMappingNotFound.
	self
		should: [ (self reader: '{}') for: Point do: [ :mapping | mapping mapInstVar: #zz ] ]
		raise: Error
]

{ #category : 'tests' }
SimdJSONMappingTests >> testNestedSchemas [

	| reader |
	reader := self reader: '{"origin":{"x":1,"y":2},"corner":{"x":3,"y":4}}'.
	reader mapInstVarsFor: Point.
	reader for: Rectangle do: [ :mapping |
		(mapping mapInstVar: #origin) valueSchema: Point.
		(mapping mapInstVar: #corner) valueSchema: Point ].
	self assert: (reader nextAs: Rectangle) equals: (1 @ 2 corner: 3 @ 4)
]

{ #category : 'tests' }
SimdJSONMappingTests >> testNextListAs [

	| value |
	value := (self reader: '[{"x":1,"y":2},{"x":3,"y":4}]') mapInstVarsFor: Point; nextListAs: Point.
	self assert: value equals: { 1 @ 2. 3 @ 4 }.
	self assert: value class equals: Array.
	value := (self reader: '[{"x":1,"y":2}]') listClass: OrderedCollection; mapInstVarsFor: Point; nextListAs: Point.
	self assert: value class equals: OrderedCollection.
	self assert: value first equals: 1 @ 2
]

{ #category : 'tests' }
SimdJSONMappingTests >> testPoint [

	self assert: ((self reader: self pointJSON) mapInstVarsFor: Point; nextAs: Point) equals: 1 @ 2.
	self
		assert: ((self reader: '{"x":1e2,"y":-1e-1}') mapInstVarsFor: Point; nextAs: Point)
		equals: 100 @ (-1 / 10).
	self
		assert: ((self reader: self pointJSON) propertyNamesAsSymbols: true; mapInstVarsFor: Point; nextAs: Point)
		equals: 1 @ 2
]

{ #category : 'tests' }
SimdJSONMappingTests >> testReaderBlocks [
	"User reader blocks with the parse protocol of NeoJSONReader"

	| pairs constants |
	pairs := (self reader: '{"b":1,"a":[2],"c":{"x":3,"y":4}}')
		mapInstVarsFor: Point;
		for: #Pairs customDo: [ :mapping |
			mapping reader: [ :reader |
				| out |
				out := OrderedCollection new.
				reader parseMapKeysDo: [ :key |
					out add: key -> (key = 'c' ifTrue: [ reader nextAs: Point ] ifFalse: [ reader next ]) ].
				out asArray ] ];
		nextAs: #Pairs.
	self assert: pairs equals: { 'b' -> 1. 'a' -> #( 2 ). 'c' -> (3 @ 4) }.
	constants := (self reader: '[true,1,null,"x",false]')
		for: #Constants customDo: [ :mapping |
			mapping reader: [ :reader |
				| out |
				out := OrderedCollection new.
				reader parseListDo: [
					| value |
					value := #none.
					reader parseConstantDo: [ :constant | value := constant ].
					value == #none ifTrue: [ value := reader next ].
					out add: value ].
				out asArray ] ];
		nextAs: #Constants.
	self assert: constants equals: { true. 1. nil. 'x'. false }
]

{ #category : 'tests' }
SimdJSONMappingTests >> testRetryAfterError [
	"An error of a typed read leaves the reader and the stream before the value, before the
	 handler runs: try the mapping, else read the value as it is"

	| reader value |
	reader := (self reader: '[1,2] 3') mapInstVarsFor: Point; yourself.
	value := [ reader nextAs: Point ] on: Error do: [ :error | reader next ].
	self assert: value equals: #( 1 2 ).
	self assert: reader next equals: 3.
	reader := (self reader: '[1,2] 3') mapInstVarsFor: Point; yourself.
	value := [ reader nextAs: Point ] on: Error do: [ :error | error return: nil ].
	self assert: value isNil.
	self assert: reader next equals: #( 1 2 ).
	reader := (self reader: '{"a":1} 3') mapInstVarsFor: Point; yourself.
	value := [ reader nextListAs: Point ] on: Error do: [ :error | reader next ].
	self assert: (value at: 'a') equals: 1.
	self assert: reader next equals: 3.
	self assert: reader atEnd
]

{ #category : 'tests' }
SimdJSONMappingTests >> testSeveralValues [

	| reader |
	reader := self reader: '{"x":1,"y":2} {"x":3,"y":4}'.
	reader mapInstVarsFor: Point.
	self assert: (reader nextAs: Point) equals: 1 @ 2.
	self deny: reader atEnd.
	self assert: (reader nextAs: Point) equals: 3 @ 4.
	self assert: reader atEnd
]

{ #category : 'tests' }
SimdJSONMappingTests >> testUnknownKeys [
	"An unknown key is skipped, whatever its value, and the stream goes on after the object"

	| reader |
	reader := self reader: '{"x":1,"z":{"deep":[1,2,{"a":3}],"n":1e5},"y":2} [3]'.
	reader mapInstVarsFor: Point.
	self assert: (reader nextAs: Point) equals: 1 @ 2.
	self assert: reader next equals: #( 3 ).
	self assert: reader atEnd
]
