Extension { #name : 'LargeNegativeInteger' }

{ #category : '*SimdJSON' }
LargeNegativeInteger >> isSimdJSONPlain [
	"Exactly a LargeNegativeInteger"

	^ self class == LargeNegativeInteger
]
