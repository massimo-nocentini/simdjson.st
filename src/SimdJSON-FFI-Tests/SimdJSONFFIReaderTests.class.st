"
The tests of SimdJSONReaderTests, read through SimdJSON-FFI: the plugin is hidden by the test hook #pluginMissing, so that SimdJSONReader reads through SimdJSONLibrary, and the helpers of the primitive call SimdJSONLibrary instead.  Skipped when the library is not found.
"
Class {
	#name : 'SimdJSONFFIReaderTests',
	#superclass : 'SimdJSONReaderTests',
	#category : 'SimdJSON-FFI-Tests-Tests',
	#package : 'SimdJSON-FFI-Tests',
	#tag : 'Tests'
}

{ #category : 'testing' }
SimdJSONFFIReaderTests class >> shouldInheritSelectors [

	^ true
]

{ #category : 'helpers' }
SimdJSONFFIReaderTests >> prim: source from: start to: stop flags: flags budget: budget maxUnits: maxUnits [
	"The library has no budget"

	^ SimdJSONLibrary read: source from: start to: stop flags: flags maxUnits: maxUnits
]

{ #category : 'helpers' }
SimdJSONFFIReaderTests >> primDict: source budget: budget [

	^ SimdJSONLibrary read: source from: 1 to: source size flags: SimdJSONReader flagDict maxUnits: -1
]

{ #category : 'helpers' }
SimdJSONFFIReaderTests >> requirePlugin [
	"The tests of the primitive run against the library"
]

{ #category : 'running' }
SimdJSONFFIReaderTests >> setUp [

	super setUp.
	SimdJSONLibrary isAvailable ifFalse: [ self skip: 'libSimdJSONFFI not found' ].
	SimdJSONReader testHook: #pluginMissing value: true
]

{ #category : 'tests - errors' }
SimdJSONFFIReaderTests >> testErrorMessages [
	"The messages come from the library"

	self assert: ((SimdJSONReader errorMessageFor: 9) beginsWith: 'NUMBER_ERROR').
	self assert: ((SimdJSONReader errorMessageFor: 13) beginsWith: 'EMPTY').
	self assert: (SimdJSONReader errorMessageFor: 1001) notEmpty.
	self assert: (SimdJSONReader errorMessageFor: 1002) notEmpty.
	self assert: ((SimdJSONLibrary errorMessage: 0) beginsWith: 'SUCCESS').
	self assert: (SimdJSONLibrary errorMessage: 1001) equals: (SimdJSONReader errorMessageFor: 1001).
	self assert: (SimdJSONLibrary errorMessage: 100000) isNil.
	self assert: (SimdJSONLibrary errorMessage: -1) isNil
]

{ #category : 'tests - plugin' }
SimdJSONFFIReaderTests >> testPluginInfo [
	"Without the plugin, nothing of it is known; the library tells its own versions"

	self deny: SimdJSONReader pluginAvailable.
	self assert: SimdJSONReader pluginInfo isNil.
	self assert: SimdJSONReader backend equals: #ffi.
	self assert: SimdJSONReader fallback equals: SimdJSONLibrary.
	self assert: SimdJSONLibrary simdjsonVersion equals: '5.0.5'.
	self assert: SimdJSONLibrary implementationName notEmpty
]

{ #category : 'tests - primitive' }
SimdJSONFFIReaderTests >> testPrimitiveKeysAndNext [
	"With flagSymbolKeys the library answers the keys as Symbols, and no Array of keys"

	| result |
	result := self prim: '[{"a":1,"b":2},{"a":3}]' flags: 8 budget: -1.
	self assert: (result at: 5) isNil.
	self assert: ((result at: 2) first at: 1) identicalTo: #a.
	self assert: ((result at: 2) first at: 3) identicalTo: #b.
	self assert: ((result at: 2) second at: 1) identicalTo: #a.
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
SimdJSONFFIReaderTests >> testPrimitiveNextAfterRefusedBudget [

	self skip: 'the library has no budget'
]
