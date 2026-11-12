Extension { #name : 'BoxedFloat64' }

{ #category : '*SimdJSON' }
BoxedFloat64 >> isSimdJSONPlain [
	"Exactly a BoxedFloat64"

	^ self class == BoxedFloat64
]
