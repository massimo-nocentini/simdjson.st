Extension { #name : 'ByteArray' }

{ #category : '*SimdJSON' }
ByteArray >> simdJSONSourceKind [
	"In bytes of UTF-8, exactly a ByteArray: CompiledMethod, ExternalAddress and the other
	subclasses are what my superclass makes of them"

	self class == ByteArray ifFalse: [ ^ super simdJSONSourceKind ].
	^ #bytes
]
