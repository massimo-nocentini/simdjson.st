"
The tests of SimdJSONMappingTests, read through SimdJSON-FFI (see SimdJSONFFIReaderTests).
"
Class {
	#name : 'SimdJSONFFIMappingTests',
	#superclass : 'SimdJSONMappingTests',
	#category : 'SimdJSON-FFI-Tests-Tests',
	#package : 'SimdJSON-FFI-Tests',
	#tag : 'Tests'
}

{ #category : 'testing' }
SimdJSONFFIMappingTests class >> shouldInheritSelectors [

	^ true
]

{ #category : 'running' }
SimdJSONFFIMappingTests >> setUp [

	super setUp.
	SimdJSONLibrary isAvailable ifFalse: [ self skip: 'libSimdJSONFFI not found' ].
	SimdJSONReader testHook: #pluginMissing value: true
]
