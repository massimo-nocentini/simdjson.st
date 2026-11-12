"
The tests of SimdJSONWriterTests, written through SimdJSON-FFI (see SimdJSONFFIReaderTests).
"
Class {
	#name : 'SimdJSONFFIWriterTests',
	#superclass : 'SimdJSONWriterTests',
	#category : 'SimdJSON-FFI-Tests-Tests',
	#package : 'SimdJSON-FFI-Tests',
	#tag : 'Tests'
}

{ #category : 'testing' }
SimdJSONFFIWriterTests class >> shouldInheritSelectors [

	^ true
]

{ #category : 'running' }
SimdJSONFFIWriterTests >> setUp [

	super setUp.
	SimdJSONLibrary isAvailable ifFalse: [ self skip: 'libSimdJSONFFI not found' ].
	SimdJSONReader testHook: #pluginMissing value: true
]
