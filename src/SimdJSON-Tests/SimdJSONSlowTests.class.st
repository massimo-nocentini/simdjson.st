Class {
	#name : 'SimdJSONSlowTests',
	#superclass : 'SimdJSONTestCase',
	#category : 'SimdJSON-Tests-Tests',
	#package : 'SimdJSON-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
SimdJSONSlowTests >> defaultTimeLimit [

	^ 10 minutes
]

{ #category : 'helpers' }
SimdJSONSlowTests >> floatsJSON: count [
	"[1.5e300,...]: 8 bytes, and one BoxedFloat64 of 16 bytes, an element"

	^ String new: count * 8 + 1 streamContents: [ :stream |
		stream nextPut: $[.
		1 to: count do: [ :i |
			i > 1 ifTrue: [ stream nextPut: $, ].
			stream nextPutAll: '1.5e300' ].
		stream nextPut: $] ]
]

{ #category : 'running' }
SimdJSONSlowTests >> setUp [

	super setUp.
	(OSEnvironment current at: 'SJ_SLOW' ifAbsent: [ nil ]) ifNil: [ self skip: 'set SJ_SLOW to run' ]
]

{ #category : 'tests' }
SimdJSONSlowTests >> testManyBoxedFloats [
	"2M boxes (48 MB of objects): the plugin allocates them where the image grew old space,
	 never in eden only"

	| value |
	value := (self reader: (self floatsJSON: 2000000)) exactNumbers: false; next.
	self assert: value size equals: 2000000.
	self assert: value first equals: 1.5e300.
	self assert: value first class equals: BoxedFloat64.
	self assert: value last equals: 1.5e300.
	value := self read: (self floatsJSON: 200000).
	self assert: value size equals: 200000.
	self assert: value last equals: 1.5e300
]

{ #category : 'tests' }
SimdJSONSlowTests >> testOutOfMemoryAtCap [
	"Old space capped 8 MB above its size: a clean OutOfMemory, and the VM goes on"

	| json cap result |
	json := self floatsJSON: 2000000.
	Smalltalk garbageCollect.
	cap := Smalltalk vm parameterAt: 67.
	[ Smalltalk vm parameterAt: 67 put: (Smalltalk vm parameterAt: 1) + (8 * 1024 * 1024).
	  result := [ (self reader: json) exactNumbers: false; next ]
		on: OutOfMemory
		do: [ :error | error return: #outOfMemory ] ]
		ensure: [ Smalltalk vm parameterAt: 67 put: cap ].
	self assert: result equals: #outOfMemory.
	json := result := nil.
	SimdJSONReader releaseParser.
	Smalltalk garbageCollect.
	self assert: (self read: '{"a":[1,2.5,"x",null,true]}') size equals: 1
]

{ #category : 'tests' }
SimdJSONSlowTests >> testWriteOutOfMemoryAtCap [
	"An output of 2 million Floats that old space, capped, cannot hold: the primitive answers
	 what it needs, growing fails, and the writer signals OutOfMemory; uncapped, it writes"

	| floats cap result |
	floats := (1 to: 2000000) collect: [ :i | i / 7.0 ].
	Smalltalk garbageCollect.
	cap := Smalltalk vm parameterAt: 67.
	[ Smalltalk vm parameterAt: 67 put: (Smalltalk vm parameterAt: 1) + (8 * 1024 * 1024).
	  result := [ SimdJSONWriter toBytes: floats ]
		on: OutOfMemory
		do: [ :error | error return: #outOfMemory ] ]
		ensure: [ Smalltalk vm parameterAt: 67 put: cap ].
	self assert: result equals: #outOfMemory.
	result := SimdJSONWriter toBytes: floats.
	self assert: (result copyFrom: 1 to: 21) asString equals: '[0.14285714285714285,'.
	self assert: (SimdJSONReader fromBytes: result) size equals: 2000000
]
