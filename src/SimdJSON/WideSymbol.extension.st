Extension { #name : 'WideSymbol' }

{ #category : '*SimdJSON' }
WideSymbol >> isSimdJSONPlain [
	"Exactly a WideSymbol"

	^ self class == WideSymbol
]
