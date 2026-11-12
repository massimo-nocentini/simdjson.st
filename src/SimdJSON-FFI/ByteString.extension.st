Extension { #name : 'ByteString' }

{ #category : '*SimdJSON-FFI' }
ByteString >> simdJSONEncoding [
	"SJ_ENC_LATIN1, exactly a ByteString: an instance of a subclass is what my superclass
	makes of it"

	self class == ByteString ifFalse: [ ^ super simdJSONEncoding ].
	^ SimdJSONLibrary encodingLatin1
]

{ #category : '*SimdJSON-FFI' }
ByteString >> simdJSONTapeKeyOn: anEncoder [
	"Exactly a ByteString, as primitiveWrite: an instance of a subclass is what my superclass
	makes of it"

	self class == ByteString ifFalse: [ ^ super simdJSONTapeKeyOn: anEncoder ].
	^ anEncoder byteString: self
]

{ #category : '*SimdJSON-FFI' }
ByteString >> simdJSONTapeOn: anEncoder level: level [
	"Exactly a ByteString, as primitiveWrite: an instance of a subclass is what my superclass
	makes of it"

	self class == ByteString ifFalse: [ ^ super simdJSONTapeOn: anEncoder level: level ].
	^ anEncoder byteString: self level: level
]
