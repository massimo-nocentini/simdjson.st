Class {
	#name : 'SimdJSONNativeTests',
	#superclass : 'SimdJSONTestCase',
	#category : 'SimdJSON-Tests-Tests',
	#package : 'SimdJSON-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
SimdJSONNativeTests >> setUp [

	super setUp.
	self requirePlugin
]

{ #category : 'tests' }
SimdJSONNativeTests >> testKillSwitch [

	| value |
	SimdJSONReader nativeDictionaries: false.
	self deny: SimdJSONReader nativeDictionariesWork.
	self
		assert: (self count: #nativeDictionaries during: [ value := self read: self probeJSON ])
		equals: 0.
	self assert: value equals: (self tree: self probeJSON).
	SimdJSONReader nativeDictionaries: true.
	self assert: SimdJSONReader nativeDictionariesWork.
	self assert: (self count: #nativeDictionaries during: [ self read: '{}' ]) > 0
]

{ #category : 'tests' }
SimdJSONNativeTests >> testNativeEqualsTree [

	| native tree |
	native := self read: self probeJSON.
	tree := self tree: self probeJSON.
	self assert: native class equals: Dictionary.
	self assert: native equals: tree.
	self assert: native size equals: 7.
	self assert: (native at: 'a') equals: 4.
	self assert: (native at: 'n') equals: 100.
	tree keysAndValuesDo: [ :key :value |
		self assert: (native includesKey: key).
		self assert: (native at: key) equals: value ].
	self assert: (native at: 'o') size equals: 300.
	0 to: 299 do: [ :i |
		self assert: ((native at: 'o') at: 'k' , i printString) equals: i ]
]

{ #category : 'tests' }
SimdJSONNativeTests >> testNativeIsUsed [

	self assert: (self count: #nativeDictionaries during: [ self read: '{"a":1}' ]) > 0.
	self assert: (self count: #nativeDictionaries during: [ self tree: '{"a":1}' ]) equals: 0
]

{ #category : 'tests' }
SimdJSONNativeTests >> testNativeKeys [

	| native euro astral |
	euro := self string: #( 16r20AC ).
	astral := self string: #( 16r1D11E ).
	native := self read: '{"\u20ac":1,"\ud834\udd1e":2,"\u00e9":3,"a":4}'.
	self assert: (native at: euro) equals: 1.
	self assert: (native at: astral) equals: 2.
	self assert: (native at: (self string: #( 16rE9 ))) equals: 3.
	self assert: (native includesKey: euro).
	self assert: (native keys detect: [ :each | each = 'a' ]) class equals: ByteString.
	self assert: (native keys detect: [ :each | each = euro ]) class equals: WideString.
	self assert: native equals: (self tree: '{"\u20ac":1,"\ud834\udd1e":2,"\u00e9":3,"a":4}')
]

{ #category : 'tests' }
SimdJSONNativeTests >> testNativeLarge [

	| json |
	json := String streamContents: [ :stream |
		stream nextPut: $[.
		1 to: 2000 do: [ :i |
			i > 1 ifTrue: [ stream nextPut: $, ].
			stream nextPut: ${.
			1 to: 20 do: [ :k |
				k > 1 ifTrue: [ stream nextPut: $, ].
				stream nextPutAll: '"key'; print: k; nextPutAll: '":'; print: i * k ].
			stream nextPut: $} ].
		stream nextPut: $] ].
	self assert: (self read: json) equals: (self tree: json)
]

{ #category : 'tests' }
SimdJSONNativeTests >> testNativeMutation [
	"A native Dictionary grows, removes and sorts as any other (step 3 of the self-test)"

	| native tree empty |
	native := self read: self probeJSON.
	tree := self tree: self probeJSON.
	1 to: 50 do: [ :i |
		native at: 'new' , i printString put: i.
		tree at: 'new' , i printString put: i ].
	self assert: native equals: tree.
	native removeKey: 'a'.
	tree removeKey: 'a'.
	self assert: native equals: tree.
	self deny: (native includesKey: 'a').
	self assert: native keys asSet equals: tree keys asSet.
	self assert: native keysSortedSafely equals: tree keysSortedSafely.
	(native at: 'o') removeKey: 'k7'.
	(native at: 'o') at: 'k7' put: 7.
	self assert: (native at: 'o') equals: (tree at: 'o').
	empty := self read: '{}'.
	empty at: 'x' put: 1.
	self assert: (empty at: 'x') equals: 1.
	(native at: 'e') at: 'x' put: 1.
	self assert: ((native at: 'e') at: 'x') equals: 1
]

{ #category : 'tests' }
SimdJSONNativeTests >> testOnlyForDictionaryAndArray [
	"Other classes, Symbol keys, and a reader that said no take the tree path"

	{ [ :reader | reader mapClass: OrderedDictionary; yourself ].
	  [ :reader | reader listClass: OrderedCollection; yourself ].
	  [ :reader | reader propertyNamesAsSymbols: true; yourself ].
	  [ :reader | reader nativeDictionaries: false; yourself ] } do: [ :configure |
		self
			assert: (self count: #nativeDictionaries during: [
				(configure value: (self reader: '{"a":[1]}')) next ])
			equals: 0 ]
]

{ #category : 'tests' }
SimdJSONNativeTests >> testSelfTestFailure [
	"A failed self-test turns the native path off for the session; the results stay equal"

	| native |
	SimdJSONReader testHook: #nativeSelfTestFails value: true.
	self assert: SimdJSONReader runNativeSelfTest notNil.
	self deny: SimdJSONReader nativeDictionariesWork.
	self
		assert: (self count: #nativeDictionaries during: [ native := self read: self probeJSON ])
		equals: 0.
	self assert: native equals: (self tree: self probeJSON).
	SimdJSONReader testHook: #nativeSelfTestFails value: nil.
	self assert: SimdJSONReader nativeDictionariesWork
]

{ #category : 'tests' }
SimdJSONNativeTests >> testSelfTestPasses [

	self assert: SimdJSONReader runNativeSelfTest isNil.
	self assert: SimdJSONReader nativeDictionariesWork
]

{ #category : 'helpers' }
SimdJSONNativeTests >> tree: aString [

	^ (self reader: aString) nativeDictionaries: false; next
]
