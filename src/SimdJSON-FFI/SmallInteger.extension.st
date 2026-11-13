Extension { #name : 'SmallInteger' }

{ #category : '*SimdJSON-FFI' }
SmallInteger >> isSimdJSONSmallInteger [

	^ true
]

{ #category : '*SimdJSON-FFI' }
SmallInteger >> simdJSONTapeOn: anEncoder level: level [
	"Write my tape on anEncoder, as primitiveWrite writes me, without the check of the depth"

	^ anEncoder smallInteger: self
]
