Extension { #name : 'String' }

{ #category : '*SimdJSON-FFI' }
String >> simdJSONPassableCopy [
	"A copy that the library reads in place: a ByteString"

	^ ByteString withAll: self
]
