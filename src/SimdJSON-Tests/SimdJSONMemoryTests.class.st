Class {
	#name : 'SimdJSONMemoryTests',
	#superclass : 'SimdJSONTestCase',
	#category : 'SimdJSON-Tests-Tests',
	#package : 'SimdJSON-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
SimdJSONMemoryTests >> setUp [

	super setUp.
	self requirePlugin
]

{ #category : 'helpers' }
SimdJSONMemoryTests >> heapBytesOf: anObject [
	"The bytes of anObject and of everything it holds that primitiveRead allocates: the
	 need that the plugin measures against the byte bound 32 x B + 4096 (docs/SimdJSON.md,
	 Memory and limits), counted by the image"

	| bytes |
	(anObject isNil or: [ anObject == true or: [ anObject == false ] ]) ifTrue: [ ^ 0 ].
	anObject class isImmediateClass ifTrue: [ ^ 0 ].
	bytes := anObject sizeInMemory.
	anObject class == Dictionary ifTrue: [
		bytes := bytes + (anObject instVarNamed: #array) sizeInMemory.
		anObject associationsDo: [ :each |
			bytes := bytes + each sizeInMemory + (self heapBytesOf: each key) + (self heapBytesOf: each value) ].
		^ bytes ].
	(anObject class == Array or: [ anObject class == SimdJSONFlatMap ]) ifTrue: [
		1 to: anObject basicSize do: [ :i | bytes := bytes + (self heapBytesOf: (anObject basicAt: i)) ] ].
	^ bytes
]

{ #category : 'helpers' }
SimdJSONMemoryTests >> needOf: aBlock [
	"aBlock answers a result of primitiveRead for a budget: the need it reports with budget 0,
	 and the bytes of the result it builds without a budget"

	| refused built |
	refused := aBlock value: 0.
	self assert: refused first equals: 1.
	built := aBlock value: -1.
	self assert: built first equals: 0.
	^ { refused at: 6.
		built sizeInMemory + (self heapBytesOf: (built at: 2))
			+ ((built at: 4) ifNil: [ 0 ] ifNotNil: [ :fixups | fixups sizeInMemory ])
			+ ((built at: 5) ifNil: [ 0 ] ifNotNil: [ :keys | self heapBytesOf: keys ]) }
]

{ #category : 'tests' }
SimdJSONMemoryTests >> testLargeInput [
	"Above 64 Ki units the budget is the free old space where it is checked
	 (budgetChecked); natively the build runs without one.  Either way no build fails"

	| json before value |
	json := String streamContents: [ :stream |
		stream nextPut: $[.
		1 to: 10000 do: [ :i |
			i > 1 ifTrue: [ stream nextPut: $, ].
			stream nextPutAll: '{"k":'; print: i; nextPutAll: ',"s":"abcdefgh","f":1.5e300}' ].
		stream nextPut: $] ].
	self assert: json size > 65536.
	before := SimdJSONReader primInfo last.
	value := self read: json.
	self assert: value size equals: 10000.
	self assert: (value last at: 'k') equals: 10000.
	self assert: (value last at: 'f') equals: 1.5e300.
	self assert: (SimdJSONReader primInfo last at: 5) equals: (before at: 5)
]

{ #category : 'tests' }
SimdJSONMemoryTests >> testNeedIsExact [
	"Tree, Symbol keys and number text, then Dictionaries.  A Dictionary allocates the key
	 and the value of a duplicate key too, which the last value replaces: its need is more
	 than what stays reachable"

	| pair |
	{ '[1,2.5,"x",null,true,[],{}]'. '{"a":{"b":[1e2,"\u20ac",-1.5e300]},"a":7}'.
	  '[18446744073709551616,9223372036854775808,-2E-2]'. self probeJSON } do: [ :json |
		#( 0 2 8 10 ) do: [ :flags |
			pair := self needOf: [ :budget | self prim: json flags: flags budget: budget ].
			self assert: pair first equals: pair last ] ].
	{ '{"a":{"b":[1e2,"\u20ac",-1.5e300]},"c":7}'. '[{},{"x":{"y":[]}},"\u00e9"]'.
	  self probeJSON copyReplaceAll: '"a":4' with: '"d":4' } do: [ :json |
		pair := self needOf: [ :budget | self primDict: json budget: budget ].
		self assert: pair first equals: pair last ].
	pair := self needOf: [ :budget | self primDict: self probeJSON budget: budget ].
	self assert: pair first > pair last
]

{ #category : 'tests' }
SimdJSONMemoryTests >> testOverBudgetThenGrow [
	"With a budget of 0 the plugin refuses, the reader grows old space and reads again: no
	 build ever fails"

	| before after value |
	SimdJSONReader nativeDictionariesWork; resetStatistics.
	before := SimdJSONReader primInfo last.
	SimdJSONReader testHook: #budget value: 0.
	value := self read: '{"a":[1,2,3],"b":"x"}'.
	after := SimdJSONReader primInfo last.
	self assert: (value at: 'a') equals: #( 1 2 3 ).
	self assert: (value at: 'b') equals: 'x'.
	self assert: (self statistic: #overBudget) >= 1.
	self assert: (self statistic: #grows) >= 1.
	self assert: (after at: 6) - (before at: 6) >= 1.
	self assert: (after at: 5) equals: (before at: 5)
]

{ #category : 'tests' }
SimdJSONMemoryTests >> testPrimitiveBudget [
	"A budget below the need is refused before anything is allocated, and the need is
	 exact"

	| result need |
	result := self prim: '[1,2,3]' flags: 0 budget: 0.
	self assert: result first equals: 1.
	self assert: (result at: 2) isNil.
	self assert: (result at: 3) equals: 1.
	need := result at: 6.
	result := self prim: '[1,2,3]' flags: 0 budget: need - 1.
	self assert: result first equals: 1.
	self assert: (result at: 6) equals: need.
	result := self prim: '[1,2,3]' flags: 0 budget: need.
	self assert: result first equals: 0.
	self assert: (result at: 2) equals: #( 1 2 3 ).
	self assert: need equals: result sizeInMemory + (result at: 2) sizeInMemory
]

{ #category : 'tests' }
SimdJSONMemoryTests >> testReleaseParser [

	| info |
	SimdJSONReader releaseParser.
	info := SimdJSONReader primInfo.
	self assert: (info at: 6) equals: 0.
	self assert: (info at: 7) equals: 0.
	self assert: (self read: '{"a":[1,2]}') equals: (Dictionary new at: 'a' put: #( 1 2 ); yourself).
	self assert: (SimdJSONReader primInfo at: 6) > 0
]
