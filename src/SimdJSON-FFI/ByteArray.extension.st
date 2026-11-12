Extension { #name : 'ByteArray' }

{ #category : '*SimdJSON-FFI' }
ByteArray >> simdJSONEncoding [
	"SJ_ENC_UTF8, exactly a ByteArray: CompiledMethod, ExternalAddress and the other
	subclasses are what my superclass makes of them"

	self class == ByteArray ifFalse: [ ^ super simdJSONEncoding ].
	^ SimdJSONLibrary encodingUTF8
]
