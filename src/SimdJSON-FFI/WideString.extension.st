Extension { #name : 'WideString' }

{ #category : '*SimdJSON-FFI' }
WideString >> simdJSONEncoding [
	"SJ_ENC_UTF32, exactly a WideString: an instance of a subclass is what my superclass
	makes of it"

	self class == WideString ifFalse: [ ^ super simdJSONEncoding ].
	^ SimdJSONLibrary encodingUTF32
]

{ #category : '*SimdJSON-FFI' }
WideString >> simdJSONTapeKeyOn: anEncoder [
	"Exactly a WideString, as primitiveWrite: an instance of a subclass is what my superclass
	makes of it"

	self class == WideString ifFalse: [ ^ super simdJSONTapeKeyOn: anEncoder ].
	^ anEncoder wideString: self
]

{ #category : '*SimdJSON-FFI' }
WideString >> simdJSONTapeOn: anEncoder level: level [
	"Exactly a WideString, as primitiveWrite: an instance of a subclass is what my superclass
	makes of it"

	self class == WideString ifFalse: [ ^ super simdJSONTapeOn: anEncoder level: level ].
	^ anEncoder wideString: self level: level
]

{ #category : '*SimdJSON-FFI' }
WideString >> tfPointerAddress [
	"As ByteString's: the FFI passes the address of my code points (SimdJSONLibrary reads a
	WideString source in place, as UTF-32)"

	self pinInMemory.
	^ PointerUtils oopForObject: self
]
