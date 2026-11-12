Extension { #name : 'ByteSymbol' }

{ #category : '*SimdJSON' }
ByteSymbol >> isSimdJSONPlain [
	"Exactly a ByteSymbol"

	^ self class == ByteSymbol
]
