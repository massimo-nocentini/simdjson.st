Extension { #name : 'WideString' }

{ #category : '*SimdJSON' }
WideString >> isSimdJSONPlain [
	"Exactly a WideString"

	^ self class == WideString
]
