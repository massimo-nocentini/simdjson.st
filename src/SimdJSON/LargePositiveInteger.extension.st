Extension { #name : 'LargePositiveInteger' }

{ #category : '*SimdJSON' }
LargePositiveInteger >> isSimdJSONPlain [
	"Exactly a LargePositiveInteger"

	^ self class == LargePositiveInteger
]
