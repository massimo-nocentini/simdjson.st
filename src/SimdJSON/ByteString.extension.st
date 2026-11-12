Extension { #name : 'ByteString' }

{ #category : '*SimdJSON' }
ByteString >> isSimdJSONPlain [
	"Exactly a ByteString"

	^ self class == ByteString
]
